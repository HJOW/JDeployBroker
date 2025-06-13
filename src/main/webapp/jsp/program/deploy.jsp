<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" import="java.text.SimpleDateFormat, java.util.*, java.io.*, com.fasterxml.jackson.databind.ObjectMapper, org.duckdns.hjow.util.simpleconfig.ConfigManager, org.apache.commons.fileupload.servlet.ServletFileUpload, org.apache.commons.fileupload.disk.DiskFileItemFactory, org.apache.commons.fileupload.FileItem "%><%@ include file="../backendCommon/common.jsp" %><%
org.apache.logging.log4j.Logger LOGGER = org.apache.logging.log4j.LogManager.getLogger(this.getClass());

HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);
Map<String, Object> results = new HashMap<String, Object>();
results.put("success", new Boolean(false));

beforeProcessRequest(request, response, LOGGER, sessionMap, results);

ObjectMapper mapper = new ObjectMapper();
String charset = ConfigManager.getConfig("Charset");

SimpleDateFormat formatter8  = new SimpleDateFormat("yyyyMMdd");
SimpleDateFormat formatter19 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

int randomNumbers = (int) (Math.floor(Math.random() * 8999999) + 1000000);
Date date = new Date(System.currentTimeMillis());
String date8  = formatter8.format(date);
String date19 = formatter19.format(date);

String jobType = null;
String jobCode = null;

File tempDirDates = null;
File warFile = null;

FileInputStream finp = null;
FileOutputStream fout = null;
byte[] buffers = new byte[2048];

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

    // 요청 캐릭터셋 지정
    request.setCharacterEncoding(charset);

    // 배포 대상 데이터를 config.xml 에서 읽기 (아직 매개변수를 꺼낼 수 없어 일단 리스트를 갖고 있음)
    String strTargets = ConfigManager.getConfig("Deploy");
    List<Map<String, Object>> targets = mapper.readValue(strTargets.trim(), ArrayList.class);
    
    // 임시폴더 경로 찾기, 없으면 만들기
    File dirTemp;
    String cfgTempDir = ConfigManager.getConfig("TEMP_DIR");
    if(isEmpty(cfgTempDir)) cfgTempDir = System.getProperty("java.io.tmpdir");
    dirTemp = new File(cfgTempDir);
    if(! dirTemp.exists()) dirTemp.mkdirs();

    tempDirDates = new File(dirTemp.getAbsolutePath() + File.separator + "temp_" + date8 + "_" + randomNumbers);
    if(! tempDirDates.exists()) tempDirDates.mkdirs();

    // Request 가 Multipart 인지 판별
    if(ServletFileUpload.isMultipartContent(request)) {
        DiskFileItemFactory factory = new DiskFileItemFactory();
        factory.setRepository(tempDirDates);

        ServletFileUpload uploadMan = new ServletFileUpload(factory);
        List<FileItem> items = uploadMan.parseRequest(request); // Multipart 요청 해석

        // 매개변수부터 꺼내기
        Map<String, String> params = new HashMap<String, String>();
        for(FileItem item : items) {
            if(item.isFormField()) {
                params.put(item.getFieldName(), item.getString(charset));
            } else {
                if(warFile != null) continue;
                String fileName = item.getName();
                File   file     = new File(tempDirDates.getAbsolutePath() + File.separator + fileName);
                item.write(file); // 일단 임시폴더에 저장
                warFile = file;
            }
        }

        // JobType, JobCode 받기
        jobType = params.get("JobType");
        jobCode = params.get("JobCode");
        setProgress(sess, jobType, jobCode, -1, 100, "준비 중...");

        // 이름으로 배포 대상 찾기
        String deployName = params.get("NAME");
        Map<String, Object> target = null;
        for(Map<String, Object> mapOne : targets) {
            if(! String.valueOf(mapOne.get("NAME")).trim().equals(deployName.trim())) continue;
            target = mapOne;
            break;
        }

        if(target == null) throw new NullPointerException("해당하는 배포 대상을 찾을 수 없습니다.");
        if(warFile == null) throw new FileNotFoundException("파일이 첨부되지 않았습니다.");

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

        // 실제 경로로 파일을 이동시키기 (읽어서 쓰기 - 덮어씌우기 위함)
        File newDir = new File(target.get("REAL_PATH").toString().trim());
        long len  = warFile.length();
        finp = new FileInputStream(warFile);
        fout = new FileOutputStream(newDir + File.separator + target.get("NAME") + ".war");

        LOGGER.info("Deploying !");
        LOGGER.info("    Target : " + target.get("NAME"));
        LOGGER.info("    Source : " + warFile.getName());
        LOGGER.info("    When : " + date19);
        LOGGER.info("    Who : " + sessionMap.get("ID"));
        LOGGER.info("    From : " + request.getRemoteAddr());

        long comp = len + 10L;
        len = (len * 2L) + 10L;

        int loopCnt = 0;
        int r;
        while(true) {
            r = finp.read(buffers, 0, buffers.length);
            if(r < 0) break;

            fout.write(buffers, 0, r);
            comp += r;
            loopCnt++;

            if(loopCnt %  10 == 0) setProgress(sess, jobType, jobCode, (int) (comp / 16384), (int) (len / 16384), "WAR 파일 복사 중...");
            if(loopCnt % 100 == 0) Thread.sleep(50L);
        }

        fout.close(); fout = null;
        finp.close(); finp = null;

        // 작업 완료
    } else {
        throw new RuntimeException("This is not a multipart request !");
    }

    // 응답
    results.put("success", new Boolean(true));
    results.put("message", "");
    results.put("targets", targets);
} catch(Exception ex) {
    LOGGER.error("Error on deploy - " + ex.getMessage(), ex);
    results.put("success", new Boolean(false));
    results.put("message", "오류 : " + ex.getMessage());
} finally {
    if(fout != null) { try { fout.close(); } catch(Exception exIn) {} }
    if(finp != null) { try { finp.close(); } catch(Exception exIn) {} }
    if(warFile != null) {
        if(warFile.exists()) warFile.delete();
    }
    if(tempDirDates != null) {
        if(tempDirDates.exists()) {
            delete(tempDirDates);
        }
    }
    setProgress(sess, jobType, jobCode, 0, 100, "작업 완료");
}

beforeProcessResponse(request, response, LOGGER, sessionMap, results);

response.setCharacterEncoding(charset);
mapper.writeValue(response.getOutputStream(), results);
%>