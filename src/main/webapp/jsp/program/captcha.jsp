<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%@ include file="../backendCommon/captcha.jsp" %><%
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

try {
    String randomKey = createRandomCaptchaKey(6);
    sess.setAttribute("deploybroker_capt", randomKey); // 세션에 등록
    
    int width   = Integer.parseInt(request.getParameter("width"));
    int height  = Integer.parseInt(request.getParameter("height"));
    
    width  -= 20;
    height -= 40;
    
    String capt = createCaptcha(randomKey, width, height);

    String reqType = request.getParameter("type");
    if(reqType != null && "img".equals(reqType)) {
        response.setContentType("text/html");
        response.setCharacterEncoding(charset);
        response.getWriter().write("<img src='" + capt + "' style='width: " + width + "px; height: " + height + "px'/>");

        return;
    }
    
    if(reqType != null && "html".equals(reqType)) {
        response.setContentType("text/html");
        response.setCharacterEncoding(charset);
        
        String ctx = sess.getServletContext().getContextPath();
        
        StringBuilder htmls = new StringBuilder("");
        htmls = htmls.append("<!DOCTYPE html>").append("\n");
        htmls = htmls.append("<html>").append("\n");
        htmls = htmls.append("<head>").append("\n");
        
        htmls = htmls.append("<meta charset=\"UTF-8\"/>").append("\n");
        htmls = htmls.append("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>").append("\n");
        htmls = htmls.append("<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/>").append("\n");
        htmls = htmls.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>").append("\n");
        
        htmls = htmls.append("<link rel='stylesheet' type='text/css' href='" + ctx + "/resources/dx.css'/>").append("\n");
        htmls = htmls.append("<link rel='stylesheet' type='text/css' href='" + ctx + "/resources/dx-dark.css'/>").append("\n");
        
        htmls = htmls.append("<style type='text/css'>").append("\n");
        htmls = htmls.append("body, div { margin: 0; padding: 0; vertical-align: middle; text-align: center; }").append("\n");
        htmls = htmls.append("</style>").append("\n");
        
        htmls = htmls.append("</head>").append("\n");
        htmls = htmls.append("<body>").append("\n");
        htmls = htmls.append("<div>").append("\n");
        htmls = htmls.append("<img src='" + capt + "' style='width: " + width + "px; height: " + height + "px'/>").append("\n");
        htmls = htmls.append("<input type='button' onclick='location.reload();' value='REFRESH'/>").append("\n");
        htmls = htmls.append("</div>").append("\n");
        htmls = htmls.append("</body>").append("\n");
        htmls = htmls.append("</html>");
        response.getWriter().write(htmls.toString());

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