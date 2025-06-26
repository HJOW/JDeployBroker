<%@page import="java.io.FileNotFoundException"%>
<%@page import="java.sql.DriverManager"%>
<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet, java.sql.ResultSetMetaData, java.io.File, org.duckdns.hjow.util.simpleconfig.ConfigManager"%><%!
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

/** H2 Embedded DB 접속 */
public Connection connect() {
    try {
        Class.forName("org.h2.Driver");
        
        File dbDir = dbRootDir();
        if(! dbDir.exists()) throw new FileNotFoundException("Cannot prepare DB root directory. Please check DBDirectory or TEMP_DIR option on config.xml");
        
        String strDbDir = dbDir.getAbsolutePath();
        strDbDir = strDbDir.replace("\\", "/");
        
        return DriverManager.getConnection("jdbc:h2:" + strDbDir);
    } catch(Exception ex) {
        System.out.println("Cannot prepare embedded database. " + ex.getMessage());
        ex.printStackTrace();
    }
    return null;
}

private Connection connection = null;

/** SELECT 동작 기본 메소드 */
public synchronized List<Map<String, Object>> select(org.apache.logging.log4j.Logger LOGGER, String sql, List<String> params) {
    List<Map<String, Object>> res = null;
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
        res = new ArrayList<Map<String, Object>>();
        
        colIndex = meta.getColumnCount();
        for(int idx=0; idx<colIndex; idx++) {
            columns.add(meta.getColumnName(idx + 1)); // 얘도 1부터 시작함 !
        }
        
        while(rs.next()) {
            rowOne = new HashMap<String, Object>();
            
            for(String c : columns) {
                rowOne.put(c, rs.getObject(c));
            }
            
            res.add(rowOne);
        }
        
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
        
        connection.commit();
        pstmt.close();
        
        return updateCnt;
    } catch(Exception ex) {
        LOGGER.error("Exception when executing SQL - " + ex.getMessage(), ex);
    } finally {
        if(connection != null) { try { connection.rollback(); } catch(Exception exc) {} }
        if(pstmt != null) { try { pstmt.close(); pstmt = null; } catch(Exception exc) {} }
    }
    return -1;
}
%>