<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.text.SimpleDateFormat, java.util.*, java.io.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager, org.apache.commons.fileupload.servlet.ServletFileUpload "%><%@ include file="../backendCommon/svn.jsp" %><%
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

SimpleDateFormat formatter8  = new SimpleDateFormat("yyyyMMdd");
SimpleDateFormat formatter19 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

int randomNumbers = (int) (Math.floor(Math.random() * 8999999) + 1000000);
Date date = new Date(System.currentTimeMillis());
String date8  = formatter8.format(date);
String date19 = formatter19.format(date);

String jobType = null;
String jobCode = null;

File tempDirDates = null;
File warFile = null;

FileInputStream finp = null;
FileOutputStream fout = null;
byte[] buffers = new byte[2048];

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

    // 요청 캐릭터셋 지정
    request.setCharacterEncoding(charset);

    // JobType, JobCode 받기
    jobType = request.getParameter("JobType");
    jobCode = request.getParameter("JobCode");
    setProgress(sess, jobType, jobCode, -1, 100, "준비 중...");

    // 배포 대상 데이터를 config.xml 에서 읽기
    String strTargets = ConfigManager.getConfig("Deploy");
    List<Map<String, Object>> targets = mapper.readValue(strTargets.trim(), ArrayList.class);
    
    // 이름으로 배포 대상 찾기
    String deployName = request.getParameter("NAME");
    if(deployName == null) throw new NullPointerException("해당하는 배포 대상의 이름을 알 수 없습니다.");
    Map<String, Object> target = null;
    for(Map<String, Object> mapOne : targets) {
        if(! String.valueOf(mapOne.get("NAME")).trim().equals(deployName.trim())) continue;
        target = mapOne;
        break;
    }
    
    if(target == null) throw new NullPointerException("해당하는 배포 대상을 찾을 수 없습니다.");
    
    // 접근 권한 체크
    if(! sessionMap.get("GRADE").trim().equalsIgnoreCase("MASTER")) { // MASTER 인 경우 최상위 권한으로 체크할 필요 없음
        // MASTER 가 아닌 경우

        // ALLOWS 속성 안에 이번 배포하려는 대상 이름이 있는지 확인
        boolean accepts = false;
        String strAllows = sessionMap.get("ALLOWS");
        if(strAllows != null) strAllows = strAllows.trim();
        if(! strAllows.equals("")) {
            StringTokenizer commaTokenizer = new StringTokenizer(strAllows, ",");
            while(commaTokenizer.hasMoreTokens()) {
                String allowOne = commaTokenizer.nextToken().trim();

                if(allowOne.equals(target.get("NAME").toString())) { accepts = true; break; }
            }
        }

        if(! accepts) {
            throw new RuntimeException("해당 배포 대상 " + target.get("NAME") + " 에 배포할 권한이 없습니다.");
        }
    }

    // 임시폴더 경로 찾기, 없으면 만들기
    File dirTemp;
    String cfgTempDir = ConfigManager.getConfig("TEMP_DIR");
    if(isEmpty(cfgTempDir)) cfgTempDir = System.getProperty("java.io.tmpdir");
    dirTemp = new File(cfgTempDir);
    if(! dirTemp.exists()) dirTemp.mkdirs();

    tempDirDates = new File(dirTemp.getAbsolutePath() + File.separator + "temp_" + deployName + "_" + date8 + "_" + randomNumbers);
    if(! tempDirDates.exists()) tempDirDates.mkdirs();

    // Revision 옵션 존재여부 검사
    String revUseDefault = request.getParameter("REV_USE_DEFAULTS");
    long rev = -1;
    if(! parseBool(revUseDefault)) {
        rev = Long.parseLong(request.getParameter("REVISION").replace(",", "").trim());
    }

    // SVN 에서 가져오기
    String svnUrl = target.get("REPO")    == null ? "" : target.get("REPO").toString().trim();
    String svnId  = target.get("REPO_ID") == null ? "" : target.get("REPO_ID").toString().trim();
    String svnPw  = target.get("REPO_PW") == null ? "" : target.get("REPO_PW").toString().trim();
    
    LOGGER.info("Checkout from SVN !");
    LOGGER.info("    Target : " + target.get("NAME"));
    LOGGER.info("    Source : " + svnUrl);
    LOGGER.info("       by  : " + svnId);
    LOGGER.info("    Rev    : " + rev);
    LOGGER.info("    Who    : " + sessionMap.get("ID"));
    LOGGER.info("    When   : " + date19);
    LOGGER.info("    From   : " + request.getRemoteAddr());

    setProgress(sess, jobType, jobCode, -1, 100, "SVN 체크아웃 중...");
    checkoutSVN(tempDirDates, svnUrl, rev, svnId, svnPw);

    LOGGER.info("Checkout finished.");
    
    LOGGER.info("Run maven !");
    LOGGER.info("    Target  : " + target.get("NAME"));
    LOGGER.info("    Goal    : " + target.get("GOAL").toString().trim());
    LOGGER.info("    Profile : " + (target.get("PROFILE") == null ? null : target.get("PROFILE").toString().trim()));
    
    // Maven 돌리기
    setProgress(sess, jobType, jobCode, -1, 100, "Maven 기동 중...");
    runMavenByConsole(new File(ConfigManager.getConfig("JAVA_HOME")), new File(ConfigManager.getConfig("MAVEN_HOME")), new File(tempDirDates.getAbsolutePath() + File.separator + "pom.xml"), target.get("GOAL").toString().trim(), target.get("PROFILE") == null ? null : target.get("PROFILE").toString().trim(), ConfigManager.getConfig("Charset"), LOGGER);

    LOGGER.info("Maven Job ended !");

    // war 파일 찾기
    warFile = new File(tempDirDates.getAbsolutePath() + File.separator + target.get("WARDIR"));
    
    // 목적지 war 파일명 지정
    String destWarName = ConfigManager.getConfig("WARNAME");
    if(isEmpty(destWarName)) destWarName = target.get("NAME") + ".war";
    
    // 실제 경로로 파일을 이동시키기 (읽어서 쓰기 - 덮어씌우기 위함)
    File newDir = new File(target.get("REAL_PATH").toString().trim());
    long len  = warFile.length();
    finp = new FileInputStream(warFile);
    fout = new FileOutputStream(newDir + File.separator + destWarName);

    LOGGER.info("Deploying !");
    LOGGER.info("    Target : " + target.get("NAME"));
    LOGGER.info("    Source : " + warFile.getName());
    LOGGER.info("    When : " + date19);
    LOGGER.info("    Who : " + sessionMap.get("ID"));
    LOGGER.info("    From : " + request.getRemoteAddr());

    long comp = len + 10L;
    len = (len * 2L) + 10L;

    int loopCnt = 0;
    int r;
    while(true) {
        r = finp.read(buffers, 0, buffers.length);
        if(r < 0) break;

        fout.write(buffers, 0, r);
        comp += r;
        loopCnt++;

        if(loopCnt %  10 == 0) setProgress(sess, jobType, jobCode, (int) (comp / 16384), (int) (len / 16384), "WAR 파일 복사 중...");
        if(loopCnt % 100 == 0) Thread.sleep(50L);
    }

    fout.close(); fout = null;
    finp.close(); finp = null;

    // 작업 완료
    LOGGER.info("END !");
} catch(Exception ex) {
    String msg = ex.getMessage();
    results.put("success", new Boolean(false));
    if(msg.startsWith("AUTH FAILED -")) {
        LOGGER.error("SVN Auth failed - " + msg, ex);
        results.put("message", "SVN 로그인 실패 : " + msg);
    } else {
        LOGGER.error("Error on deploysvn - " + msg, ex);
        results.put("message", "오류 : " + msg);
    }
} finally {
    if(fout != null) { try { fout.close(); } catch(Exception exIn) {} }
    if(finp != null) { try { finp.close(); } catch(Exception exIn) {} }
    if(warFile != null) {
        if(warFile.exists()) delete(warFile);
    }
    if(tempDirDates != null) {
        if(tempDirDates.exists()) {
            delete(tempDirDates);
        }
    }
    setProgress(sess, jobType, jobCode, 0, 100, "작업 완료");
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>