<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%@ include file="../backendCommon/common.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);
Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

String charset = ConfigManager.getConfig("Charset");

try {
    if(sessionMap == null) { // 세션이 없음 - 로그인을 해야 함
        results.put("message", "Not logined");
    } else { // 세션 정보가 잘못됨
        if(sessionMap.get("ID") == null) {
            sess.removeAttribute("deploybroker");
            results.put("message", "Wrong session data");
        } else { // 세션 정보가 존재함

            // IP 접속 허용여부 체크
            if(! isMatched(request.getRemoteAddr(), ConfigManager.getConfig("IPFilterMode"), ConfigManager.getConfig("IPFilter"))) throw new RuntimeException("접속할 수 있는 IP 가 아닙니다.");

            // 응답
            results.put("success", new Boolean(true));
            results.put("message", "");
            results.put("session", sessionMap);
        }
    }
} catch(Exception ex) {
    LOGGER.error("Error on checkSession - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
ObjectMapper mapper = new ObjectMapper();
mapper.writeValue(response.getOutputStream(), results);
%>