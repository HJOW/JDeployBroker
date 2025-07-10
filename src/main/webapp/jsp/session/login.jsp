<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.text.SimpleDateFormat, java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager, java.security.MessageDigest"%><%@ include file="../backendCommon/common.jsp" %><%
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
Map<String, Number> pwWrongTable = (Map<String, Number>) sess.getServletContext().getAttribute("deploybroker_pwwrong");
if(pwWrongTable == null) pwWrongTable = new HashMap<String, Number>();

Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, null, results);

SimpleDateFormat formatter19 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
Date date = new Date(System.currentTimeMillis());
String date19 = formatter19.format(date);

ObjectMapper mapper = new ObjectMapper();
String charset = ConfigManager.getConfig("Charset");

try {
    // 로그인 처리 (회원가입 구현할 것이 아니기 때문에, ConfigManager 에서 가져오기)
    
    String id = request.getParameter("id").trim();
    String pw = request.getParameter("pw").trim();
    
    String captchaInputs = request.getParameter("captcha").trim();
    
    // 로그인 시도는 무조건 로그 출력
    LOGGER.info("Login Trying !");
    LOGGER.info("    ID : " + id);
    LOGGER.info("    When : " + date19);
    LOGGER.info("    From : " + request.getRemoteAddr());

    // IP 접속 허용여부 체크
    if(! isMatched(request.getRemoteAddr(), ConfigManager.getConfig("IPFilterMode"), ConfigManager.getConfig("IPFilter"))) throw new RuntimeException("접속할 수 있는 IP 가 아닙니다.");
    
    // Captcha 체크
    Object oCapt = sess.getAttribute("deploybroker_capt");
    if(! isEmpty(oCapt)) {
        if(! captchaInputs.equalsIgnoreCase(oCapt.toString())) {
            results.put("success", new Boolean(false));
            results.put("message", "화면에 보이는 이미지 코드를 올바르게 입력해 주세요.");

            beforeProcessResponse(request, response, LOGGER, null, results);
            
            response.setCharacterEncoding(charset);
            mapper.writeValue(response.getOutputStream(), results);
            return;
        }
    }
    
    // Manager 계정 조회 (config.xml 참고)
    String strManagerAccounts = ConfigManager.getConfig("Manager");
    List<Map<String, Object>> managerAccounts = mapper.readValue(strManagerAccounts.trim(), ArrayList.class);
    
    // ID로 계정 찾기
    Map<String, Object> accountFound = null;
    for(Map<String, Object> accountOne : managerAccounts) {
        if(accountOne.get("ID").toString().trim().equals( id.trim() )) {
            accountFound = accountOne;
            break;
        }
    }
    
    if(accountFound == null) {
        results.put("success", new Boolean(false));
        results.put("message", "해당하는 계정을 찾을 수 없습니다.");

        beforeProcessResponse(request, response, LOGGER, null, results);
        
        response.setCharacterEncoding(charset);
        mapper.writeValue(response.getOutputStream(), results);
        return;
    }
    
    // 비밀번호 틀린 횟수 체크
    int countsWrong = pwWrongTable.get(id) == null ? 0 : pwWrongTable.get(id).intValue();
    if(countsWrong >= 10) {
        results.put("success", new Boolean(false));
        results.put("message", "너무 많은 로그인 실패로 계정이 잠겼습니다.");

        beforeProcessResponse(request, response, LOGGER, null, results);
        
        response.setCharacterEncoding(charset);
        mapper.writeValue(response.getOutputStream(), results);
        return;
    }
    
    // 비밀번호 체크
    boolean pwAccepts = false;
    String pwNow = accountFound.get("PASSWORD").toString().trim();
    // 먼저 평문으로 검사
    if(pw.equals(pwNow)) {
        pwAccepts = true;
    } else {
        // 해시값으로 한번 더 검사
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        pwNow = new String(Base64.getEncoder().encode( digest.digest(new String(pwNow + "deploy").getBytes("UTF-8")) ), "UTF-8");
        
        if(pw.equals(pwNow)) pwAccepts = true;
    }
    
    if(! pwAccepts) { // 비밀번호 틀림
        // 틀린 횟수 기록
        countsWrong++;
        pwWrongTable.put(id, new Integer(countsWrong));
        sess.getServletContext().setAttribute("deploybroker_pwwrong", pwWrongTable);
        
        results.put("success", new Boolean(false));
        results.put("message", "해당하는 계정을 찾을 수 없습니다.");

        beforeProcessResponse(request, response, LOGGER, null, results);
        
        response.setCharacterEncoding(charset);
        mapper.writeValue(response.getOutputStream(), results);
        return;
    }
    
    // 로그인 성공 처리
    //     세션에 담을 데이터 만들기
    Map<String, String> sessionMap = new HashMap<String, String>();
    sessionMap.put("ID", accountFound.get("ID").toString().trim());
    sessionMap.put("NAME", accountFound.get("NAME").toString().trim());
    sessionMap.put("GRADE", accountFound.get("GRADE").toString().trim());
    sessionMap.put("ALLOWS", accountFound.get("ALLOWS").toString().trim());
    
    //     로그 출력
    LOGGER.info("Login Success !");
    LOGGER.info("    ID : " + sessionMap.get("ID"));
    LOGGER.info("    Name : " + sessionMap.get("NAME"));
    LOGGER.info("    When : " + date19);
    LOGGER.info("    From : " + request.getRemoteAddr());

    //     세션에 담기
    sess.setAttribute("deploybroker_sess", sessionMap);
    
    // 완료 응답
    results.put("success", new Boolean(true));
    results.put("session", sessionMap);
} catch(Exception ex) {
    LOGGER.error("Error on login - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, (Map<String, String>) sess.getAttribute("deploybroker_sess"), results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>