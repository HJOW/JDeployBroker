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

Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

String charset = ConfigManager.getConfig("Charset");
ObjectMapper mapper = new ObjectMapper();

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
    
    // MASTER 여부 체크 (SQL문 직접 실행은 MASTER 만 가능)
    String grade = sessionMap.get("GRADE") == null ? "GUEST" : sessionMap.get("GRADE").toString().trim().toUpperCase();
    if(! grade.equals("MASTER")) {
        beforeProcessResponse(request, response, LOGGER, null, results);

        response.setCharacterEncoding(charset);
        results.put("message", "Insufficient privileges.");
        mapper.writeValue(response.getOutputStream(), results);
        return;
    }

    // IP 접속 허용여부 체크
    if(! isMatched(request.getRemoteAddr(), ConfigManager.getConfig("IPFilterMode"), ConfigManager.getConfig("IPFilter"))) throw new RuntimeException("접속할 수 있는 IP 가 아닙니다.");

    // 요청 캐릭터셋 지정
    request.setCharacterEncoding(charset);
    
    
    
    String mode = request.getParameter("mode");
    if(mode == null) mode = "SELECT";
    mode = mode.trim().toUpperCase();
    
    String sql = request.getParameter("sql");
    if(sql == null) sql = "";
    sql = sql.trim();
    if(sql.equals("")) throw new NullPointerException("There is no SQL statement !");
    
    if(mode.equals("SELECT")) {
        List<Map<String, Object>> res = select(LOGGER, sql, null);
        results.put("data", res);
    } else {
        int uc = execute(LOGGER, sql, null);
        results.put("updates", new Integer(uc));
    }

    results.put("mode", mode);
    results.put("success", new Boolean(true));
} catch(Exception ex) {
    LOGGER.error("Error on sql - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>