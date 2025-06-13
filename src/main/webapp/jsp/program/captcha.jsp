<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%@ include file="../backendCommon/captcha.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());

Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

String charset = ConfigManager.getConfig("Charset");

try {
    int width   = Integer.parseInt(request.getParameter("width"));
    int height  = Integer.parseInt(request.getParameter("height"));
    String capt = createCaptcha(request.getParameter("key"), width, height);

    String reqType = request.getParameter("type");
    if(reqType != null && "img".equals(reqType)) {
        response.setContentType("text/html");
        response.setCharacterEncoding(charset);
        response.getWriter().write("<img src='" + capt + "'/>");

        return;
    }

    results.put("data", capt);
    results.put("success", new Boolean(true));
} catch(Exception ex) {
    LOGGER.error("Error on captcha - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
ObjectMapper mapper = new ObjectMapper();
mapper.writeValue(response.getOutputStream(), results);
%>