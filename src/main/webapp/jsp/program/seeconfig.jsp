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
results.put("message", "");

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);
String charset = ConfigManager.getConfig("Charset");

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

ObjectMapper mapper = new ObjectMapper();

try {
    boolean allows = false;
    if(sessionMap != null) {
        String grade = sessionMap.get("GRADE") == null ? "GUEST" : sessionMap.get("GRADE").toString().trim().toUpperCase();
        if(grade == null) allows = false;
        else if("MASTER".equalsIgnoreCase(grade)) allows = true;
    }
    
    if(allows) {
        Map<String, String> map = ConfigManager.getConfigs();
        Set<String> keys = map.keySet();
        
        Map<String, Object> newMap = new HashMap<String, Object>();
        
        for(String k : keys) {
            String v = map.get(k);
            Object newValue = v;
            
            try {
                if("MAVEN_HOME".equalsIgnoreCase(k)) newValue = "[HIDDEN]";
                if("JAVA_HOME".equalsIgnoreCase(k)) newValue = "[HIDDEN]";
                if("TEMP_DIR".equalsIgnoreCase(k)) newValue = "[HIDDEN]";
                if("IPFilter".equalsIgnoreCase(k)) newValue = "[HIDDEN]";
                
                if("Manager".equalsIgnoreCase(k)) {
                    ArrayList<Map<String, Object>> oldManList = (ArrayList<Map<String, Object>>) mapper.readValue(v.trim(), ArrayList.class);
                    ArrayList<Map<String, Object>> newManList = new ArrayList<Map<String, Object>>();
                    
                    for(Map<String, Object> oldMan : oldManList) {
                        Map<String, Object> newMan = new HashMap<String, Object>();
                        newMan.putAll(oldMan);
                        newMan.put("PASSWORD", "[HIDDEN]");
                        newManList.add(newMan);
                    }
                    
                    newValue = newManList;
                }
                
                if("Deploy".equalsIgnoreCase(k)) {
                    ArrayList<Map<String, Object>> oldDeployList = (ArrayList<Map<String, Object>>) mapper.readValue(v.trim(), ArrayList.class);
                    ArrayList<Map<String, Object>> newDeployList = new ArrayList<Map<String, Object>>();
                    
                    for(Map<String, Object> oldTarget : oldDeployList) {
                        Map<String, Object> newTarget = new HashMap<String, Object>();
                        newTarget.putAll(oldTarget);
                        if(newTarget.containsKey("REAL_PATH")) newTarget.put("REAL_PATH", "[HIDDEN]");
                        if(newTarget.containsKey("REPO")) newTarget.put("REPO", "[HIDDEN]");
                        if(newTarget.containsKey("REPO_PW")) newTarget.put("REPO_PW", "[HIDDEN]");
                        
                        newDeployList.add(newTarget);
                    }
                    
                    newValue = newDeployList;
                }
                
            } catch(Exception exIn) {
                newValue = "[ERROR] " + exIn.getMessage();
            }
            newMap.put(k, newValue);
        }
        
        results.put("data", mapper.writeValueAsString(newMap));
        results.put("success", new Boolean(true));
    } else {
        results.put("message", "이 기능을 사용할 권한이 없습니다.");
        results.put("success", new Boolean(false));
    }
} catch(Exception ex) {
    LOGGER.error("Error on seeconfig - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>