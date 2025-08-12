<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.sql.DriverManager, java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet, java.sql.ResultSetMetaData, java.sql.SQLException, java.io.File, java.io.FileNotFoundException, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%!
/** H2 Embedded DB 동작 디렉토리 결정 */
public File dbRootDir() {
    // DB 루트 경로 옵션 검사
    String strRootDir = ConfigManager.getConfig("DBDirectory");
    
    if(strRootDir == null) strRootDir = "";
    strRootDir = strRootDir.trim();
    if(strRootDir.equals("")) strRootDir = null;
    
    boolean usingTempDir = false;
    if(strRootDir == null) usingTempDir = true;
    
    // // DB 루트 경로 옵션이 없으면 임시 폴더 사용
    if(usingTempDir) strRootDir = ConfigManager.getConfig("TEMP_DIR");
    
    if(strRootDir == null) strRootDir = "";
    strRootDir = strRootDir.trim();
    if(strRootDir.equals("")) strRootDir = null;
    if(strRootDir == null) strRootDir = System.getProperty("java.io.tmpdir");
    
    File dir = new File(strRootDir.trim());
    if(! dir.exists()) dir.mkdirs();
    
    if(usingTempDir) {
        dir = new File(dir.getAbsolutePath() + File.separator + "jdeploybroker");
        if(! dir.exists()) dir.mkdirs();
    }
    
    return dir;
}

private Boolean usingDB = null;
public synchronized boolean checkUsingDB() {
    if(usingDB == null) {
        String sUsingDB = ConfigManager.getConfig("USE_DB");
        if(sUsingDB == null) { usingDB = new Boolean(true); usingDB.booleanValue(); }
        sUsingDB = sUsingDB.trim().toUpperCase();
        if(sUsingDB.equals("")) { usingDB = new Boolean(true); usingDB.booleanValue(); } 
        usingDB = new Boolean((sUsingDB.equals("Y") || sUsingDB.equals("YES") || sUsingDB.equals("TRUE") || sUsingDB.equals("T")));
    }
    
    return usingDB.booleanValue();
}

/** H2 Embedded DB 접속 */
public synchronized Connection connect() {
    Connection conn = null;
    try {
        if(! checkUsingDB()) return null;
        
        Class.forName("org.h2.Driver");
        
        File dbDir = dbRootDir();
        if(! dbDir.exists()) throw new FileNotFoundException("Cannot prepare DB root directory. Please check DBDirectory or TEMP_DIR option on config.xml");
        
        String strDbDir = dbDir.getAbsolutePath();
        strDbDir = strDbDir.replace("\\", "/");
        
        conn = DriverManager.getConnection("jdbc:h2:" + strDbDir + ";AUTO_SERVER=TRUE");
        prepare(conn);
        
        return conn;
    } catch(Exception ex) {
        System.out.println("Cannot prepare embedded database. " + ex.getMessage());
        ex.printStackTrace();
        
        if(conn != null) {
            try {
                conn.close();
            } catch(Exception exc) {
                System.out.println("Cannot close failed database. " + exc.getMessage());
            }
            conn = null;
        }
    }
    return null;
}

/** DB 사용 직후 사용준비 (테이블 생성) */
public void prepare(Connection conn) throws Exception {
    if(! checkUsingDB()) return;
    
    int counts = 0;
    boolean prepared = false;
    
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // JDP_NUMBERS 테이블 존재여부 확인
    try {
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS CNT FROM JDP_NUMBERS");
        rs = pstmt.executeQuery();
        
        while(rs.next()) {
            counts = rs.getInt(1);
        }
        
        rs.close(); rs = null;
        pstmt.close(); pstmt = null;
        
        if(counts >= 1) prepared = true;
        if(prepared) {
            pstmt = conn.prepareStatement("SELECT COUNT(*) AS CNT FROM JDP_JOBS");
            rs = pstmt.executeQuery();
            
            while(rs.next()) {
                counts = rs.getInt(1);
            }
            
            rs.close(); rs = null;
            pstmt.close(); pstmt = null;
            
            prepared = true;
        }
        
        if(! prepared) {
            try {
                pstmt = conn.prepareStatement("DROP TABLE JDP_NUMBERS");
                pstmt.execute();
                conn.commit();
                pstmt.close(); pstmt = null;
            } catch(SQLException exIn) {} finally {
                if(pstmt != null) { pstmt.close(); pstmt = null; }
            }
            
            try {
                pstmt = conn.prepareStatement("DROP TABLE JDP_JOBS");
                pstmt.execute();
                conn.commit();
                pstmt.close(); pstmt = null;
            } catch(SQLException exIn) {} finally {
                if(pstmt != null) { pstmt.close(); pstmt = null; }
            }
            prepared = false;
        }
    } catch(SQLException ex) {
        prepared = false;
    } catch(Exception ex) {
        System.out.println("Cannot prepare embedded database insides - " + ex.getMessage());
        throw new RuntimeException(ex.getMessage(), ex);
    }
    
    if(prepared) return; // 준비가 이미 되어 있으면 이 메소드는 중단
    
    // 준비가 안되었으면...
    
    try {
        // JDP_NUMBERS 처리
        pstmt = conn.prepareStatement("CREATE TABLE JDP_NUMBERS (NUM INTEGER, CONSTRAINT PK_JDP_NUMBERS PRIMARY KEY(NUM))");
        pstmt.execute();
        conn.commit();
        pstmt.close(); pstmt = null;
        
        for(int idx=1; idx<=10; idx++) {
            pstmt = conn.prepareStatement("INSERT INTO JDP_NUMBERS (NUM) VALUES (?)");
            pstmt.setInt(1, idx);
            pstmt.execute();
            conn.commit();
            pstmt.close(); pstmt = null;
        }
        
        // JDP_JOBS 처리
        String sql = "CREATE TABLE JDP_JOBS (";
        sql += "\n" + "  JTYPE       VARCHAR(5)";
        sql += "\n" + ", JNAME       VARCHAR(255)";
        sql += "\n" + ", JREALPATH   VARCHAR(255)";
        sql += "\n" + ", JURL        VARCHAR(255)";
        sql += "\n" + ", JDISABLED   VARCHAR(5)";
        sql += "\n" + ", JREPOURL    VARCHAR(255)";
        sql += "\n" + ", JREPOID     VARCHAR(255)";
        sql += "\n" + ", JREPOPW     VARCHAR(255)";
        sql += "\n" + ", JBUILDER    VARCHAR(255)";
        sql += "\n" + ", JMVNGOAL    VARCHAR(100)";
        sql += "\n" + ", JMVNPROFILE VARCHAR(100)";
        sql += "\n" + ", JWARDIR     VARCHAR(255)";
        sql += "\n" + ", CONSTRAINT PK_JDP_JOBS PRIMARY KEY (JNAME)";
        sql += "\n" + ")  ";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.execute();
        conn.commit();
        pstmt.close(); pstmt = null;
        
        
        prepared = true;
    } catch(SQLException ex) {
        prepared = false;
    } catch(Exception ex) {
        System.out.println("Cannot prepare embedded database insides - " + ex.getMessage());
        throw new RuntimeException(ex.getMessage(), ex);
    }
}

private Connection connection = null;

/** SELECT 동작 기본 메소드 */
public synchronized List<Map<String, Object>> select(org.apache.logging.log4j.Logger LOGGER, String sql, List<String> params) {
    if(! checkUsingDB()) return new ArrayList<Map<String, Object>>();
    
    Map<String, Object> details = selectMeta(LOGGER, sql, params);
    if(details == null) return null;
    
    List<Map<String, Object>> res = (List<Map<String, Object>>) details.get("list");
    return res;
}

/** SELECT 동작 상세 메소드 (메타 데이터 포함) */
public synchronized Map<String, Object> selectMeta(org.apache.logging.log4j.Logger LOGGER, String sql, List<String> params) {
    if(! checkUsingDB()) return new HashMap<String, Object>();
    
    Map<String, Object> res = null;
    List<Map<String, Object>> resList = null;
    List<String> columns = null;
    Map<String, Object> rowOne = null;
    
    if(connection == null) connection = connect();
    
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    int paramIndex = 0;
    int colIndex = 0;
    try {
        pstmt = connection.prepareStatement(sql);
        
        if(params != null) {
            for(String p : params) {
                paramIndex++; // 덧셈을 먼저 해야 함. 그래야 1부터 시작함.
                pstmt.setString(paramIndex, p);
            }
        }
        
        rs = pstmt.executeQuery();
        ResultSetMetaData meta = rs.getMetaData();
        
        columns = new ArrayList<String>();
        res = new HashMap<String, Object>();
        resList = new ArrayList<Map<String, Object>>();
        
        colIndex = meta.getColumnCount();
        for(int idx=0; idx<colIndex; idx++) {
            columns.add(meta.getColumnName(idx + 1)); // 얘도 1부터 시작함 !
        }
        
        while(rs.next()) {
            rowOne = new HashMap<String, Object>();
            
            for(String c : columns) {
                rowOne.put(c, rs.getObject(c));
            }
            
            resList.add(rowOne);
        }
        
        res.put("list", resList);
        res.put("columns", columns);
        
        rs.close();
        pstmt.close();
        
        return res;
    } catch(Exception ex) {
        LOGGER.error("Exception when executing SQL - " + ex.getMessage(), ex);
    } finally {
        if(rs    != null) { try { rs.close();    rs    = null; } catch(Exception exc) {} }
        if(pstmt != null) { try { pstmt.close(); pstmt = null; } catch(Exception exc) {} }
    }
    return null;
}

/** CREATE, UPDATE, DELETE, DDL 동작 기본 메소드 */
public synchronized int execute(org.apache.logging.log4j.Logger LOGGER, String sql, List<String> params) {
    if(! checkUsingDB()) return 0;
    if(connection == null) connection = connect();
    
    PreparedStatement pstmt = null;
    int paramIndex = 0;
    try {
        pstmt = connection.prepareStatement(sql);
        
        if(params != null) {
            for(String p : params) {
                paramIndex++; // 덧셈을 먼저 해야 함. 그래야 1부터 시작함.
                pstmt.setString(paramIndex, p);
            }
        }
        
        pstmt.execute();
        int updateCnt = pstmt.getUpdateCount();
        
        commit(LOGGER);
        pstmt.close();
        
        return updateCnt;
    } catch(Exception ex) {
        LOGGER.error("Exception when executing SQL - " + ex.getMessage(), ex);
    } finally {
        rollback(LOGGER);
        if(pstmt != null) { try { pstmt.close(); pstmt = null; } catch(Exception exc) {} }
    }
    return -1;
}

public void commit(org.apache.logging.log4j.Logger LOGGER) {
    if(! checkUsingDB()) return;
    if(connection == null) return;
    try { connection.commit(); } catch(Exception exc) { LOGGER.error("Exception when executing JDBC commit - " + exc.getMessage(), exc); }
}

public void rollback(org.apache.logging.log4j.Logger LOGGER) {
    if(! checkUsingDB()) return;
    if(connection == null) return;
    try { connection.rollback(); } catch(Exception exc) { LOGGER.error("Exception when executing JDBC rollback - " + exc.getMessage(), exc); }
}
%>