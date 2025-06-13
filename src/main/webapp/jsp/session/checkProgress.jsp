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