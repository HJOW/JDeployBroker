<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.text.SimpleDateFormat, java.util.*, java.io.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager, org.apache.commons.fileupload.servlet.ServletFileUpload "%><%@ include file="../backendCommon/git.jsp" %><%
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

try {
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
    
    // SVN 에서 가져오기
    String gitURL = target.get("REPO")    == null ? "" : target.get("REPO").toString().trim();
    
    // 히스토리 조회
    results.put("data", getHistory(gitURL));
    results.put("success", new Boolean(true));
} catch(Exception ex) {
    LOGGER.error("Error on checkSession - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>