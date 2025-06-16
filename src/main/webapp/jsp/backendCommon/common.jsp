<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.net.*" %><%!
    public static int VERSION = 4;

//   Copyright 2025 HJOW
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

    /** 각 요청 처리부 앞단에서 호출 */
    public void beforeProcessRequest(Object httpServletRequest, Object httpServletResponse, org.apache.logging.log4j.Logger LOGGER, Map<String, String> sessionMap, Map<String, Object> resultMap) {

    }

    /** 각 요청 처리부 뒷단에서 호출 */
    public void beforeProcessResponse(Object httpServletRequest, Object httpServletResponse, org.apache.logging.log4j.Logger LOGGER, Map<String, String> sessionMap, Map<String, Object> resultMap) {

    }

    /** 이 객체가 비어 있는지 확인. 문자열의 경우 양끝 공백 제거하여 빈 문자열인지도 확인. null 또한 비어있는 것으로 간주함. */
    public boolean isEmpty(Object obj) {
        if(obj == null) return true;
        if(obj instanceof Collection<?>) {
            return ((Collection<?>) obj).isEmpty();
        }
        if(obj instanceof Map<?, ?>) {
            return ((Map<?, ?>) obj).isEmpty();
        }
        if(obj instanceof Number   ) return false;
        if(obj instanceof Boolean  ) return false;
        if(obj instanceof Character) return (((Character) obj).charValue() == ' ');
        String str = obj.toString();
        return str.trim().equals("");
    }

    /** 객체를 boolean 으로 변환, null 은 false, Boolean 타입은 그대로 반환, 숫자인 경우 정수로 변환하여 0이면 true 그외에는 false, 모두 해당되지 않는다면 문자열로 강제 변환 및 소문자로 변환 후 y, yes, true, t 는 true, 그외에는 false */
    public boolean parseBool(Object obj) {
        if(obj == null) return false;
        if(obj instanceof Boolean) return ((Boolean) obj).booleanValue();
        if(obj instanceof Number ) {
            if(((Number) obj).intValue() == 0) return false;
            return true;
        }
        String str = obj.toString().trim().toLowerCase();
        if(str.equals("y") || str.equals("yes") || str.equals("t") || str.equals("true")) return true;
        return false;
    }

    /** IP 패턴 체크 */
    public boolean isMatched(String ip, String ipFilterMode, String ipFilterListStr) {
        if(ip == null) return false;
        if(ipFilterMode == null) return false;
        if(ipFilterListStr == null) return false;

        if(ipFilterMode.equalsIgnoreCase("ALL")) return true; // 전체 접속 허용

        // ipFilterListStr 꺼내기
        StringTokenizer commaTokenizer = new StringTokenizer(ipFilterListStr, ",");
        List<String> patterns = new ArrayList<String>();
        while(commaTokenizer.hasMoreTokens()) { patterns.add(commaTokenizer.nextToken().trim()); }

        // 패턴 매칭
        boolean matches = false;
        for(String patternOne : patterns) {
            if(ip.indexOf(".") >= 0) {
                // IPv4
                matches = isMatched4(ip, patternOne);
            } else if(ip.indexOf(":") >= 0) {
                // IPv6
                matches = isMatched6(ip, patternOne);
            } else if(ip.equals("localhost")) {
                // 127.0.0.1 로 바꿔서 IPv4 처리
                matches = isMatched4("127.0.0.1", patternOne);
            } else {
                continue;
            }
            
            if(ipFilterMode.equalsIgnoreCase("BLACKLIST")) {
                if(matches) return false;
            } else if(ipFilterMode.equalsIgnoreCase("WHITELIST")) {
                if(matches) return true;
            }
        }

        if(ipFilterMode.equalsIgnoreCase("BLACKLIST")) {
            return true;
        } else if(ipFilterMode.equalsIgnoreCase("WHITELIST")) {
            return false;
        }

        return false;
    }

    /**
     *  IPv4 규격의 IP 주소를 받아, 해당 패턴에 매칭되면 true 를 리턴, 그외의 경우 false 를 리턴
     *     패턴은 간단한데, 기존 IP 형식과 동일하나 일부 블럭에 숫자 대신 와일드카드(*)가 들어가는 형태
     *     와일드카드 블럭 자리에는 어떤 값이 오더라도 허용
     */
    public boolean isMatched4(String ip, String pattern) {
        if (ip == null || pattern == null || ip.isEmpty() || pattern.isEmpty()) {
            return false;
        }

        String[] ipParts = ip.split("\\.");
        String[] patternParts = pattern.split("\\.");

        if (ipParts.length != 4 || patternParts.length != 4) {
            return false; // 잘못된 IP 또는 패턴 형식
        }

        for (int i = 0; i < 4; i++) {
            String ipBlock = ipParts[i];
            String patternBlock = patternParts[i];

            int ipVal;
            try {
                ipVal = Integer.parseInt(ipBlock);
            } catch (NumberFormatException e) {
                return false; // IP 블록이 숫자가 아님
            }

            if (ipVal < 0 || ipVal > 255) {
                return false; // IP 블록이 범위를 벗어남
            }

            if (patternBlock.equals("*")) {
                // 와일드카드는 모든 유효한 IP 블록과 매칭됨 (ipBlock은 이미 유효성 검사됨)
                continue;
            } else {
                // 패턴 블록이 특정 숫자인 경우
                int patternVal;
                try {
                    patternVal = Integer.parseInt(patternBlock);
                } catch (NumberFormatException e) {
                    // 패턴 블록이 "*"도 아니고 숫자도 아니면 잘못된 패턴
                    return false;
                }

                if (patternVal < 0 || patternVal > 255) {
                    return false; // 패턴 블록이 범위를 벗어남 (예: "1.2.3.999")
                }

                if (ipVal != patternVal) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     *  IPv6 규격의 IP 주소를 받아, 해당 패턴에 매칭되면 true 를 리턴, 그외의 경우 false 를 리턴
     *     패턴은 간단한데, 기존 IP 형식과 동일하나 일부 블럭에 숫자 대신 와일드카드(*)가 들어가는 형태
     *     와일드카드 블럭 자리에는 어떤 값이 오더라도 허용
     */
    public boolean isMatched6(String ip, String pattern) {
        if (ip == null || pattern == null || ip.isEmpty() || pattern.isEmpty()) {
            return false;
        }

        InetAddress inetAddress;
        try {
            inetAddress = InetAddress.getByName(ip);
        } catch (UnknownHostException e) {
            return false; // 유효하지 않은 IP 주소 형식
        }

        if (!(inetAddress instanceof Inet6Address)) {
            return false; // IPv6 주소가 아님
        }

        Inet6Address inet6Addr = (Inet6Address) inetAddress;
        // getHostAddress()는 일반적으로 정규화된 형태(축약형 해제, 소문자)를 반환합니다.
        // 최신 JDK에서는 Scope ID를 제외하고 반환하지만, 안전을 위해 명시적으로 제거할 수 있습니다.
        String canonicalIp = inet6Addr.getHostAddress();
        int scopeIndex = canonicalIp.indexOf('%');
        if (scopeIndex != -1) {
            canonicalIp = canonicalIp.substring(0, scopeIndex);
        }

        String[] ipHexBlocks = canonicalIp.split(":");
        // 정규화된 IPv6 주소는 항상 8개의 블록을 가져야 합니다.
        if (ipHexBlocks.length != 8) {
            // 예기치 않은 상황: Inet6Address.getHostAddress()가 8블록을 반환하지 않음
            return false;
        }

        String[] patternHexBlocks = expandIPv6Pattern(pattern);
        if (patternHexBlocks == null || patternHexBlocks.length != 8) {
            return false; // 잘못된 패턴 또는 패턴 확장 실패
        }

        for (int i = 0; i < 8; i++) {
            String ipBlock = ipHexBlocks[i]; // 예: "0", "db8", "ffff" (소문자, 선행 0 없음)
            String patternBlock = patternHexBlocks[i]; // 예: "*", "0", "DB8", "0000"

            if (patternBlock.equals("*")) {
                // 와일드카드는 모든 유효한 IP 블록과 매칭됨
                continue;
            }

            // 패턴 블록이 특정 16진수 문자열인 경우 ("::" 확장으로 "0"이 될 수 있음)
            // IP 블록과 패턴 블록을 숫자 값으로 비교하여 "abc" vs "ABC", "0" vs "0000" 등을 처리
            long ipVal;
            try {
                // ipBlock은 canonical 형태이므로 항상 유효한 16진수
                ipVal = Long.parseLong(ipBlock, 16);
            } catch (NumberFormatException e) {
                // canonicalIp.split() 결과이므로 발생하지 않아야 함
                return false;
            }

            long patternVal;
            try {
                // patternBlock은 expandIPv6Pattern에서 유효성 검사를 거침 ( "*"가 아니면 16진수)
                patternVal = Long.parseLong(patternBlock, 16);
            } catch (NumberFormatException e) {
                // expandIPv6Pattern 로직 오류가 아니라면 발생하지 않아야 함
                return false;
            }

            if (ipVal != patternVal) {
                return false;
            }
        }

        return true;
    }

    /**
     * IPv6 패턴 문자열을 8개의 블록으로 확장합니다.
     * "::"는 적절한 수의 "0" 블록으로 대체됩니다.
     * 각 블록은 "*"이거나 유효한 16진수 문자열이어야 합니다.
     * 유효하지 않은 패턴이면 null을 반환합니다.
     */
    private String[] expandIPv6Pattern(String pattern) {
        if (pattern == null || pattern.isEmpty()) {
            return null;
        }

        // "::"가 두 번 이상 사용되었는지 확인
        if (pattern.indexOf("::") != pattern.lastIndexOf("::")) {
            return null; // 잘못된 IPv6 패턴 형식
        }

        List<String> resultParts = new ArrayList<String>(8);
        int doubleColonIndex = pattern.indexOf("::");

        if (doubleColonIndex == -1) { // "::" 없음
            String[] parts = pattern.split(":", -1); // 마지막 세그먼트는 보존
            if (parts.length != 8) {
                return null; // "::"가 없으면 반드시 8개의 세그먼트여야 함
            }
            for (String part : parts) {
                if (!isValidIPv6PatternBlock(part)) {
                    return null;
                }
                resultParts.add(part);
            }
        } else { // "::" 있음
            String leftPartStr = pattern.substring(0, doubleColonIndex);
            String rightPartStr = pattern.substring(doubleColonIndex + 2);

            List<String> leftSegments = new ArrayList<>();
            if (!leftPartStr.isEmpty()) {
                Collections.addAll(leftSegments, leftPartStr.split(":"));
            }

            List<String> rightSegments = new ArrayList<>();
            if (!rightPartStr.isEmpty()) {
                Collections.addAll(rightSegments, rightPartStr.split(":"));
            }

            for (String segment : leftSegments) {
                if (!isValidIPv6PatternBlock(segment)) {
                    return null;
                }
                resultParts.add(segment);
            }

            int segmentsPresent = leftSegments.size() + rightSegments.size();
            if (segmentsPresent > 8) { // 명시적 세그먼트가 8개를 초과하면 안됨
                return null;
            }
            // "::"가 있다면 최소 하나 이상의 0블록을 대체해야 한다는 엄격한 규칙(RFC 5952)도 있지만,
            // InetAddress 파싱은 좀 더 유연하므로 여기서는 segmentsPresent가 8일 때 zerosToInsert가 0이 되는 것을 허용.
            // (예: "1:2:3:4::5:6:7:8"은 "1:2:3:4:0:5:6:7:8"로 해석될 수 있음)
            // 그러나 "1:2:3:4:5:6:7:8::" 같은 경우는 segmentsPresent가 8이고 ::가 추가된 형태이므로,
            // 아래 resultParts.size() != 8 체크에서 걸러지거나, segmentsPresent > 8 에서 걸러짐.

            int zerosToInsert = 8 - segmentsPresent;
            if (zerosToInsert < 0) { // segmentsPresent > 8 인 경우
                return null;
            }


            for (int i = 0; i < zerosToInsert; i++) {
                // "::"는 IP에서 0 값 블록과 매칭되어야 하므로, 패턴 확장 시 "0"으로 채움
                resultParts.add("0");
            }

            for (String segment : rightSegments) {
                if (!isValidIPv6PatternBlock(segment)) {
                    return null;
                }
                resultParts.add(segment);
            }

            if (resultParts.size() != 8) {
                // 로직상 이 지점에 도달하기 전에 대부분의 오류가 걸러져야 함
                return null;
            }
        }

        return resultParts.toArray(new String[0]);
    }

    /**
     * IPv6 패턴의 단일 블록이 유효한지 검사합니다.
     * 블록은 "*"이거나 1~4자리의 16진수 문자열이어야 합니다.
     */
    private boolean isValidIPv6PatternBlock(String block) {
        if (block == null) return false; // null 블록은 허용 안 함
        if (block.equals("*")) {
            return true;
        }
        if (block.isEmpty() || block.length() > 4) { // 빈 블록 또는 길이 초과
            return false;
        }
        for (char c : block.toCharArray()) {
            boolean isDigit = (c >= '0' && c <= '9');
            boolean isLowercaseHex = (c >= 'a' && c <= 'f');
            boolean isUppercaseHex = (c >= 'A' && c <= 'F');
            if (!(isDigit || isLowercaseHex || isUppercaseHex)) {
                return false; // 16진수 문자가 아님
            }
        }
        return true;
    }
    
    /** 파일 또는 폴더를 삭제 (주의 ! 폴더 삭제 시, 재귀 호출 있음. 심볼릭 링크 쓰는 디렉토리는 특별히 주의 !) */
    public void delete(java.io.File dir) {
        if(dir == null) return;
        if(! dir.exists()) return;
        
        if(dir.isDirectory()) {
            java.io.File[] children = dir.listFiles();
            for(java.io.File f : children) {
                delete(f);
            }
        }
        dir.delete();
    }

    /** 로그인 세션 정보 반환 (null 이 나오면 로그인이 안된 것) */
    public Map<String, String> getSessionMap(HttpSession httpSession) {
        Object obj = httpSession.getAttribute("deploybroker_sess");
        try {
            if(obj == null) return null;
            
            Map<String, String> sessionMap = (Map<String, String>) obj;
            if(sessionMap.get("ID") == null) return null;
            return sessionMap;
        } catch(ClassCastException ex) {
            return null;
        }
    }

    /** 작업 진행 상태 등록/갱신, 메시지 추가 */
    public void setProgress(HttpSession httpSession, String jobType, String jobCode, int progress, int maximum, String message) {
        cleanOldProgress(httpSession);

        if(httpSession == null) return;
        if(jobType == null) return;
        if(jobCode == null) return;

        Map<String, Object> progMap = null;
        boolean createNew = false;
        Object obj = httpSession.getAttribute("deploybroker_prog");
        try {
            progMap = (Map<String, Object>) obj;
            if(progMap == null) createNew = true;
            else createNew = false;
        } catch(ClassCastException ex) {
            createNew = true;
        }

        if(createNew) {
            progMap = new HashMap<String, Object>();
            httpSession.setAttribute("deploybroker_prog", progMap);
        }

        Map<String, Object> jobMap = (Map<String, Object>) progMap.get(jobType);
        if(jobMap == null) {
            jobMap = new HashMap<String, Object>();
            progMap.put(jobType, jobMap);
            httpSession.setAttribute("deploybroker_prog", progMap);
        }

        Map<String, Object> jobCodeMap = (Map<String, Object>) jobMap.get(jobCode);
        if(jobCodeMap == null) {
            jobCodeMap = new HashMap<String, Object>();
            jobMap.put(jobCode, jobCodeMap);
            httpSession.setAttribute("deploybroker_prog", progMap);
        }

        jobCodeMap.put("type", jobType);
        jobCodeMap.put("code", jobCode);
        jobCodeMap.put("value", new Integer(progress));
        jobCodeMap.put("max", new Integer(maximum));
        jobCodeMap.put("date", new Long(System.currentTimeMillis()));
        if(message != null) {
            if(message.length() >= 100) message = message.substring(0, 97) + "...";
            jobCodeMap.put("message", message);
        }
        jobMap.put(jobCode, jobCodeMap);
        progMap.put(jobType, jobMap);
        httpSession.setAttribute("deploybroker_prog", progMap);
    }

    /** 작업 진행 상태 등록/갱신 */
    public void setProgress(HttpSession httpSession, String jobType, String jobCode, int progress, int maximum) {
        setProgress(httpSession, jobType, jobCode, progress, maximum, null);
    }

    /** 작업 진행 상태 반환 */
    public Map<String, Object> getProgress(HttpSession httpSession, String jobType, String jobCode) {
        if(httpSession == null) return new HashMap<String, Object>();
        if(jobType == null) return new HashMap<String, Object>();
        if(jobCode == null) return new HashMap<String, Object>();

        Map<String, Object> progMap = null;
        Object obj = httpSession.getAttribute("deploybroker_prog");
        try {
            progMap = (Map<String, Object>) obj;
            if(progMap == null) return new HashMap<String, Object>();
        } catch(ClassCastException ex) {
            return new HashMap<String, Object>();
        }

        Map<String, Object> jobMap = (Map<String, Object>) progMap.get(jobType);
        if(jobMap == null) return new HashMap<String, Object>();

        Map<String, Object> jobCodeMap = (Map<String, Object>) jobMap.get(jobCode);
        if(jobCodeMap == null) return new HashMap<String, Object>();

        // 유효성 검사 체크
        Long date = (Long) jobCodeMap.get("date");
        if(date == null) { jobMap.remove(jobCode); progMap.put(jobType, jobMap); httpSession.setAttribute("deploybroker_prog", progMap); return new HashMap<String, Object>(); }
        if(System.currentTimeMillis() - date.longValue() >= 1000L * 60L * 10L) { jobMap.remove(jobCode); progMap.put(jobType, jobMap); httpSession.setAttribute("deploybroker_prog", progMap); return new HashMap<String, Object>(); }

        // 유효기간 연장하기
        jobCodeMap.put("date", new Long(System.currentTimeMillis()));
        jobMap.put(jobCode, jobCodeMap);
        progMap.put(jobType, jobMap);
        httpSession.setAttribute("deploybroker_prog", progMap);

        // Map 복제하기
        Map<String, Object> newMap = new HashMap<String, Object>();
        newMap.putAll(jobCodeMap);
        newMap.remove("date");
        return newMap;
    }

    /** 오래된 진행 상태 데이터 삭제 */
    public void cleanOldProgress(HttpSession httpSession) {
        if(httpSession == null) return;

        Map<String, Object> progMap = null;
        Object obj = httpSession.getAttribute("deploybroker_prog");
        try {
            progMap = (Map<String, Object>) obj;
            if(progMap == null) return;
        } catch(ClassCastException ex) {
            return;
        }

        Set<String> jobTypes = progMap.keySet();
        for(String jobType : jobTypes) {
            Map<String, Object> jobMap = (Map<String, Object>) progMap.get(jobType);
            Set<String> jobCodes = jobMap.keySet();
            for(String jobCode : jobCodes) {
                Map<String, Object> jobCodeMap = (Map<String, Object>) jobMap.get(jobCode);
                Long date = (Long) jobCodeMap.get("date");

                // 오래된 데이터이면 삭제
                if(date == null) {
                    jobMap.remove(jobCode);
                    progMap.put(jobType, jobMap);
                    httpSession.setAttribute("deploybroker_prog", progMap);
                }
            }
        }
    }

    /** 현재의 OS가 Windows 기반인지 체크 */
    public boolean isWindowsOS() {
        String osType=  System.getProperty("os.name");
        if(osType == null) return false;

        osType = osType.trim().toLowerCase();
        if(osType.startsWith("windows")) return true;
        return false;
    }
%>