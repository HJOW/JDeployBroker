<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%@ include file="../backendCommon/common.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);
Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

String charset = ConfigManager.getConfig("Charset");

try {
    results.put("success", new Boolean(true));
    results.put("message", "");
    results.put("progress", getProgress(sess, request.getParameter("jobType").trim(), request.getParameter("jobCode").trim()));
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