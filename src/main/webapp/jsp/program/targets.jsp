<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%@ include file="../backendCommon/common.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());

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

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);
Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

ObjectMapper mapper = new ObjectMapper();
String charset = ConfigManager.getConfig("Charset");

try {
    // 먼저 세션 체크
    boolean sessionAccepted = true;

    if(sessionMap == null) {
        sessionAccepted = false;
        results.put("message", "Not logined");
    } else {
        if(sessionMap.get("ID") == null) {
            sessionAccepted = false;
            sess.removeAttribute("deploybroker");
            results.put("message", "Wrong session data");
        }
    }

    if(!sessionAccepted) {
        beforeProcessResponse(request, response, LOGGER, null, results);

        response.setCharacterEncoding(charset);
        mapper.writeValue(response.getOutputStream(), results);
        return;
    }

    // IP 접속 허용여부 체크
    if(! isMatched(request.getRemoteAddr(), ConfigManager.getConfig("IPFilterMode"), ConfigManager.getConfig("IPFilter"))) throw new RuntimeException("접속할 수 있는 IP 가 아닙니다.");

    // 작업 시작
    String strTargets = ConfigManager.getConfig("Deploy");
    List<Map<String, Object>> targets = mapper.readValue(strTargets.trim(), ArrayList.class);

    // 배포 항목에서 이름 중복 체크 - 먼저 고유 번호 발급, 실제 경로 데이터 제거, 이름 유효성 체크
    int uniqueIndex = 0;
    for(Map<String, Object> rowOne : targets) {
        rowOne.put("NO", new Integer(uniqueIndex));
        rowOne.remove("REAL_PATH");

        String name = rowOne.get("NAME").toString().trim();
        if(name.equals("")) { throw new NullPointerException("배포 대상 이름은 공란으로 사용할 수 없습니다."); }
        if(name.contains(",")) { throw new RuntimeException("배포 대상 이름에는 쉼표를 사용할 수 없습니다."); }
        if(name.contains("'")) { throw new RuntimeException("배포 대상 이름에는 따옴표를 사용할 수 없습니다."); }
        if(name.contains("\"")) { throw new RuntimeException("배포 대상 이름에는 따옴표를 사용할 수 없습니다."); }
        if(name.contains(";")) { throw new RuntimeException("배포 대상 이름에는 세미콜론을 사용할 수 없습니다."); }
        if(name.contains("<")) { throw new RuntimeException("배포 대상 이름에는 꺽쇠(부등호)를 사용할 수 없습니다."); }
        if(name.contains(">")) { throw new RuntimeException("배포 대상 이름에는 꺽쇠(부등호)를 사용할 수 없습니다."); }
        if(name.contains("\n")) { throw new RuntimeException("배포 대상 이름에는 줄바꿈 기호를 사용할 수 없습니다."); }
    }

    // 다시 루프를 돌아, Disabled 항목 제거
    List<Map<String, Object>> temps = targets;
    targets = new ArrayList<Map<String, Object>>();
    for(Map<String, Object> mapOne : temps) {
        Object objDisabled = mapOne.get("DISABLED");
        if(parseBool(objDisabled)) continue;

        targets.add(mapOne);
    }
    temps = null;

    // 이름 중복 체크
    for(Map<String, Object> mapOne : targets) {
        for(Map<String, Object> mapTwo : targets) {
            if(String.valueOf(mapOne.get("uniqueIndex")).equals( String.valueOf(mapTwo.get("uniqueIndex")) )) continue;
            if(String.valueOf(mapOne.get("NAME")).equals( String.valueOf(mapTwo.get("NAME")) )) throw new RuntimeException("배포 대상에 중복된 이름 " + mapOne.get("NAME") + "이/가 존재합니다.");
        }
    }

    // 접근권한 있는 것만 찾아 필터링
    List<Map<String, Object>> allowedList = new ArrayList<Map<String, Object>>();
    if(sessionMap.get("GRADE").trim().equalsIgnoreCase("MASTER")) { // MASTER 는 전체 마스터 권한이므로 전부 허용
        allowedList = targets;
    } else {
        // ALLOWS 속성만 가져다 필터링
        String strAllows = sessionMap.get("ALLOWS");
        if(strAllows != null) strAllows = strAllows.trim();
        if(! strAllows.equals("")) {
            StringTokenizer commaTokenizer = new StringTokenizer(strAllows, ",");
            while(commaTokenizer.hasMoreTokens()) {
                String allowOne = commaTokenizer.nextToken().trim();

                for(Map<String, Object> targetOne : targets) {
                    if(allowOne.equals(String.valueOf(targetOne.get("NAME")))) allowedList.add(targetOne);
                }
            }
        }
    }

    // 일부 민감필드 제거
    for(Map<String, Object> rowOne : allowedList) {
        rowOne.remove("REAL_PATH");
        rowOne.remove("REPO_ID");
        rowOne.remove("REPO_PW");
    }

    // 응답
    results.put("success", new Boolean(true));
    results.put("message", "");
    results.put("targets", allowedList);
} catch(Exception ex) {
    LOGGER.error("Error on targets - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>