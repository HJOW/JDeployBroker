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

ObjectMapper mapper = new ObjectMapper();
String charset = ConfigManager.getConfig("Charset");

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

    // IP 접속 허용여부 체크
    if(! isMatched(request.getRemoteAddr(), ConfigManager.getConfig("IPFilterMode"), ConfigManager.getConfig("IPFilter"))) throw new RuntimeException("접속할 수 있는 IP 가 아닙니다.");

    // 작업 시작
    List<Map<String, Object>> targets = new ArrayList<Map<String, Object>>();
    
    //     DB 사용 시...
    if(checkUsingDB()) {
        // h2 로부터 먼저 작업 읽기
        String sql = "SELECT JTYPE, JNAME, JREALPATH, JURL, JDISABLED, JREPOURL, JREPOID, JREPOPW, JBUILDER, JMVNGOAL, JMVNPROFILE, JWARDIR FROM JDP_JOBS ORDER BY JNAME";
        List<String> params = new ArrayList<String>();
        try {
            List<Map<String, Object>> listDB = select(LOGGER, sql, params);
            
            for(Map<String, Object> rowDB : listDB) {
                // DB 컬럼과 파일 필드명이 다르므로 맞춰줌
                
                Map<String, Object> job = new HashMap<String, Object>();
                
                // 필수값들
                if(rowDB.get("JTYPE"    ) == null) continue; job.put("TYPE"     , rowDB.get("JTYPE"));
                if(rowDB.get("JNAME"    ) == null) continue; job.put("NAME"     , rowDB.get("JNAME"));
                if(rowDB.get("JREALPATH") == null) continue; job.put("REAL_PATH", rowDB.get("JREALPATH"));
                if(rowDB.get("JDISABLED") == null) continue; job.put("DISABLED" , rowDB.get("JDISABLED"));
                
                // 선택사항들
                if(rowDB.get("JURL"       ) != null) job.put("URL"    , rowDB.get("JURL"));
                if(rowDB.get("JREPOURL"   ) != null) job.put("REPO"   , rowDB.get("JREPOURL"));
                if(rowDB.get("JREPOID"    ) != null) job.put("REPO_ID", rowDB.get("JREPOID"));
                if(rowDB.get("JREPOPW"    ) != null) job.put("REPO_PW", rowDB.get("JREPOPW"));
                if(rowDB.get("JBUILDER"   ) != null) job.put("BUILDER", rowDB.get("JBUILDER"));
                if(rowDB.get("JMVNGOAL"   ) != null) job.put("GOAL"   , rowDB.get("JMVNGOAL"));
                if(rowDB.get("JMVNPROFILE") != null) job.put("PROFILE", rowDB.get("JMVNPROFILE"));
                if(rowDB.get("JWARDIR"    ) != null) job.put("WARDIR" , rowDB.get("JWARDIR"));
                
                targets.add(job);
            }
        } catch(Exception exDB) {
            exDB.printStackTrace();
            throw exDB;
        }
    }
    
    
    //     config.xml 로부터 작업 읽기
    String strTargets = ConfigManager.getConfig("Deploy");
    List<Map<String, Object>> targetReaded = mapper.readValue(strTargets.trim(), ArrayList.class);
    
    // DB 사용 시 - 우선순위 판단하고, 병합
    if(checkUsingDB()) {
        String sql = "";
        List<String> params = new ArrayList<String>();
        
        String strFileMorePriv = ConfigManager.getConfig("FORCE_UPDATE_DB");
        boolean fileMorePriv = false; // true 시 config.xml 파일 내용이 DB보다 더 우선함. false 인 경우 DB 내용이 더 우선함.
        if(strFileMorePriv != null) fileMorePriv = parseBool(strFileMorePriv);
        
        // 작업 목록 병합
        for(Map<String, Object> tasksFile : targetReaded) {
            String nameFile = tasksFile.get("NAME").toString();
            boolean dbExists = false;
            
            if(tasksFile.get("NAME"     ) == null) { LOGGER.error("There is no NAME      for " + nameFile + " on config.xml"); continue; };
            if(tasksFile.get("TYPE"     ) == null) { LOGGER.error("There is no TYPE      for " + nameFile + " on config.xml"); continue; };
            if(tasksFile.get("REAL_PATH") == null) { LOGGER.error("There is no REAL_PATH for " + nameFile + " on config.xml"); continue; };
            if(tasksFile.get("DISABLED" ) == null) { LOGGER.error("There is no DISABLED  for " + nameFile + " on config.xml"); continue; };
            
            for(Map<String, Object> tasksDB : targets) {
                String nameDB = tasksDB.get("NAME").toString();
                
                if(nameDB.equals(nameFile)) {
                    // DB, 파일 양쪽에 이미 존재하는 경우
                    dbExists = true;
                    
                    if(fileMorePriv) {
                        // 파일 내용이 더 우선하는 경우, DB 데이터를 업데이트
                        params.clear();
                        
                        try {
                            sql = "UPDATE JDP_JOBS ";
                            sql += "\n" + "SET JTYPE     = ? "; params.add(tasksFile.get("TYPE"     ).toString());
                            sql += "\n" + "  , JREALPATH = ? "; params.add(tasksFile.get("REAL_PATH").toString());
                            sql += "\n" + "  , JDISABLED = ? "; params.add(tasksFile.get("DISABLED" ).toString());
                            
                            if(tasksFile.get("URL"    ) != null) { sql += "\n" + "  , JURL        = ? "; params.add(tasksFile.get("URL").toString());       }
                            if(tasksFile.get("REPO"   ) != null) { sql += "\n" + "  , JREPOURL    = ? "; params.add(tasksFile.get("REPO").toString());      }
                            if(tasksFile.get("REPO_ID") != null) { sql += "\n" + "  , JREPOID     = ? "; params.add(tasksFile.get("REPO_ID").toString());   }
                            if(tasksFile.get("REPO_PW") != null) { sql += "\n" + "  , JREPOPW     = ? "; params.add(tasksFile.get("REPO_PW").toString());   }
                            if(tasksFile.get("BUILDER") != null) { sql += "\n" + "  , JBUILDER    = ? "; params.add(tasksFile.get("BUILDER").toString());   }
                            if(tasksFile.get("GOAL"   ) != null) { sql += "\n" + "  , JMVNGOAL    = ? "; params.add(tasksFile.get("GOAL").toString());      }
                            if(tasksFile.get("PROFILE") != null) { sql += "\n" + "  , JMVNPROFILE = ? "; params.add(tasksFile.get("PROFILE").toString());   }
                            if(tasksFile.get("WARDIR" ) != null) { sql += "\n" + "  , JWARDIR     = ? "; params.add(tasksFile.get("WARDIR").toString());    }
                            
                            sql += "\n" + "WHERE JNAME = ? ";   params.add(tasksFile.get("NAME").toString());
                            execute(LOGGER, sql, params);
                        } catch(Exception exDb) { LOGGER.error("Error on updating JDP_JOBS", exDb); }
                    } else {
                        continue; // DB 내용이 더 우선하므로, 건너뜀
                    }
                }
            }
            
            if(! dbExists) { // 파일에 있으나 DB에 없었던 경우 - INSERT 해야 함
                try {
                    params.clear();
                    sql = "INSERT INTO JDP_JOBS (";
                    sql += "JNAME, JTYPE, JREALPATH, JDISABLED";
                    
                    if(tasksFile.get("URL"    ) != null) sql += ", JURL       ";
                    if(tasksFile.get("REPO"   ) != null) sql += ", JREPOURL   ";
                    if(tasksFile.get("REPO_ID") != null) sql += ", JREPOID    ";
                    if(tasksFile.get("REPO_PW") != null) sql += ", JREPOPW    ";
                    if(tasksFile.get("BUILDER") != null) sql += ", JBUILDER   ";
                    if(tasksFile.get("GOAL"   ) != null) sql += ", JMVNGOAL   ";
                    if(tasksFile.get("PROFILE") != null) sql += ", JMVNPROFILE";
                    if(tasksFile.get("WARDIR" ) != null) sql += ", JWARDIR    ";
                    
                    sql += ") VALUES (?, ?, ?, ?";
                    params.add(tasksFile.get("NAME").toString());
                    params.add(tasksFile.get("TYPE").toString());
                    params.add(tasksFile.get("REAL_PATH").toString());
                    params.add(tasksFile.get("DISABLED").toString());
                    
                    if(tasksFile.get("URL"    ) != null) { sql += ", ?"; params.add(tasksFile.get("URL").toString());     }
                    if(tasksFile.get("REPO"   ) != null) { sql += ", ?"; params.add(tasksFile.get("REPO").toString());    }
                    if(tasksFile.get("REPO_ID") != null) { sql += ", ?"; params.add(tasksFile.get("REPO_ID").toString()); }
                    if(tasksFile.get("REPO_PW") != null) { sql += ", ?"; params.add(tasksFile.get("REPO_PW").toString()); }
                    if(tasksFile.get("BUILDER") != null) { sql += ", ?"; params.add(tasksFile.get("BUILDER").toString()); }
                    if(tasksFile.get("GOAL"   ) != null) { sql += ", ?"; params.add(tasksFile.get("GOAL").toString());    }
                    if(tasksFile.get("PROFILE") != null) { sql += ", ?"; params.add(tasksFile.get("PROFILE").toString()); }
                    if(tasksFile.get("WARDIR" ) != null) { sql += ", ?"; params.add(tasksFile.get("WARDIR").toString());  }
                    
                    sql += ")";
                
                    execute(LOGGER, sql, params);
                } catch(Exception exDb) { LOGGER.error("Error on inserting JDP_JOBS", exDb);  }
            }
        }
    } else {
        targets = targetReaded; // DB 미사용 시, targets 에 파일에서 읽은 데이터 때러녛기
    }
    targetReaded = null;
    
    // 배포 항목에서 이름 중복 체크 - 먼저 고유 번호 발급, 실제 경로 데이터 제거, 이름 유효성 체크
    int uniqueIndex = 0;
    for(Map<String, Object> rowOne : targets) {
        rowOne.put("NO", new Integer(uniqueIndex));
        rowOne.remove("REAL_PATH");

        String name = rowOne.get("NAME").toString().trim();
        if(name.equals("")) { throw new NullPointerException("배포 대상 이름은 공란으로 사용할 수 없습니다."); }
        if(name.contains(",")) { throw new RuntimeException("배포 대상 이름에는 쉼표를 사용할 수 없습니다."); }
        if(name.contains("'")) { throw new RuntimeException("배포 대상 이름에는 따옴표를 사용할 수 없습니다."); }
        if(name.contains("\"")) { throw new RuntimeException("배포 대상 이름에는 따옴표를 사용할 수 없습니다."); }
        if(name.contains(";")) { throw new RuntimeException("배포 대상 이름에는 세미콜론을 사용할 수 없습니다."); }
        if(name.contains("<")) { throw new RuntimeException("배포 대상 이름에는 꺽쇠(부등호)를 사용할 수 없습니다."); }
        if(name.contains(">")) { throw new RuntimeException("배포 대상 이름에는 꺽쇠(부등호)를 사용할 수 없습니다."); }
        if(name.contains("\n")) { throw new RuntimeException("배포 대상 이름에는 줄바꿈 기호를 사용할 수 없습니다."); }
    }

    // 다시 루프를 돌아, Disabled 항목 제거
    List<Map<String, Object>> temps = targets;
    targets = new ArrayList<Map<String, Object>>();
    for(Map<String, Object> mapOne : temps) {
        Object objDisabled = mapOne.get("DISABLED");
        if(parseBool(objDisabled)) continue;

        targets.add(mapOne);
    }
    temps = null;

    // 이름 중복 체크
    for(Map<String, Object> mapOne : targets) {
        for(Map<String, Object> mapTwo : targets) {
            if(String.valueOf(mapOne.get("uniqueIndex")).equals( String.valueOf(mapTwo.get("uniqueIndex")) )) continue;
            if(String.valueOf(mapOne.get("NAME")).equals( String.valueOf(mapTwo.get("NAME")) )) throw new RuntimeException("배포 대상에 중복된 이름 " + mapOne.get("NAME") + "이/가 존재합니다.");
        }
    }

    // 접근권한 있는 것만 찾아 필터링
    List<Map<String, Object>> allowedList = new ArrayList<Map<String, Object>>();
    if(sessionMap.get("GRADE").trim().equalsIgnoreCase("MASTER")) { // MASTER 는 전체 마스터 권한이므로 전부 허용
        allowedList = targets;
    } else {
        // ALLOWS 속성만 가져다 필터링
        String strAllows = sessionMap.get("ALLOWS");
        if(strAllows != null) strAllows = strAllows.trim();
        if(! strAllows.equals("")) {
            StringTokenizer commaTokenizer = new StringTokenizer(strAllows, ",");
            while(commaTokenizer.hasMoreTokens()) {
                String allowOne = commaTokenizer.nextToken().trim();

                for(Map<String, Object> targetOne : targets) {
                    if(allowOne.equals(String.valueOf(targetOne.get("NAME")))) allowedList.add(targetOne);
                }
            }
        }
    }

    // 일부 민감필드 제거
    for(Map<String, Object> rowOne : allowedList) {
        rowOne.remove("REAL_PATH");
        rowOne.remove("REPO_ID");
        rowOne.remove("REPO_PW");
    }

    // 응답
    results.put("success", new Boolean(true));
    results.put("message", "");
    results.put("targets", allowedList);
} catch(Exception ex) {
    LOGGER.error("Error on targets - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>