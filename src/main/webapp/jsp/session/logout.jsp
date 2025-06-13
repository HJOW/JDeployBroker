<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper"%><%@ include file="../backendCommon/common.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());
HttpSession sess = request.getSession();
Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, null, results);

try {
    sess.removeAttribute("deploybroker_sess");
    sess.removeAttribute("deploybroker_prog");
    sess.removeAttribute("deploybroker_capt");
    results.put("success", new Boolean(true));
} catch(Exception ex) {
    LOGGER.error("Error on logout - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, null, results);

response.setCharacterEncoding("UTF-8");
ObjectMapper mapper = new ObjectMapper();
mapper.writeValue(response.getOutputStream(), results);
%>