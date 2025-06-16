<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.apache.maven.shared.invoker.*, org.apache.maven.shared.utils.cli.CommandLineException, org.apache.logging.log4j.Logger" %>
<%@ include file="common.jsp" %><%!
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

/** 메이븐 구동 (Maven Invoker 라이브러리 사용) */
public InvocationResult runMaven(File javaHome, File mavenHome, File pomXml, String goal, String profile) {
    InvocationRequest mReq = new DefaultInvocationRequest();
    if(javaHome != null) mReq.setJavaHome(javaHome);
    if(mavenHome != null) mReq.setMavenHome(mavenHome);
    mReq.setPomFile(pomXml);
    
    List<String> goals = new ArrayList<String>();
    List<String> profiles = new ArrayList<String>();
    if(goal.contains(",")) {
        StringTokenizer commaTokenizer = new StringTokenizer(goal, ",");
        while(commaTokenizer.hasMoreTokens()) {
            goals.add(commaTokenizer.nextToken().trim());
        }
    } else {
        goals.add(goal);
    }
    
    mReq.setGoals(goals);
    if(profile != null) {
        profiles.add(profile);
        mReq.setProfiles(profiles);
    }
    
    Invoker invoker = new DefaultInvoker();
    try {
        InvocationResult res = invoker.execute(mReq);
        
        CommandLineException exc = res.getExecutionException();
        if(exc != null) throw exc;
        
        if(res.getExitCode() != 0) throw new RuntimeException("Maven invocation returns exit code " + res.getExitCode());
        
        return res;
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    }
}

/** 메이븐 구동 (명령어 사용) */
public void runMavenByConsole(File javaHome, File mavenHome, File pomXml, String goal, String profile, String charset, Logger logger) {
    boolean windows = isWindowsOS();
    ProcessBuilder pb = null;
    Process p;

    BufferedReader stdReader = null;
    BufferedReader errReader = null;
    Thread threadStd = null;
    Thread threadErr = null;
    try {
        String pomXmlAbsPath = pomXml.getAbsolutePath();
        int pomXmlAbsLen = pomXmlAbsPath.length();
        File dir = new File(pomXml.getAbsolutePath().substring(0, pomXmlAbsLen - 7).trim());

        // pb = new ProcessBuilder("mvn", goal, "-P", profile);
        if(windows) pb = new ProcessBuilder(mavenHome.getAbsolutePath() + File.separator + "bin" + File.separator + "mvn.cmd", goal, "-P", profile);
        else pb = new ProcessBuilder(mavenHome.getAbsolutePath() + File.separator + "bin" + File.separator + "mvn", goal, "-P", profile);
        pb.directory(dir);

        Map<String, String> env = pb.environment();
        List<String> pathEnv = new ArrayList<String>();
        if(javaHome  != null) {
            env.put("JAVA_HOME", javaHome.getAbsolutePath());
            pathEnv.add(new File(javaHome.getAbsolutePath() + File.separator + "bin").getAbsolutePath());
        }
        if(mavenHome != null) {
            env.put("M2_HOME", mavenHome.getAbsolutePath());
            env.put("MAVEN_HOME", mavenHome.getAbsolutePath());
            pathEnv.add(new File(mavenHome.getAbsolutePath() + File.separator + "bin").getAbsolutePath());
        }
        if(! pathEnv.isEmpty()) {
            boolean firsts = true;
            StringBuilder pathEnvValues = new StringBuilder("");
            String sep = ":";
            if(windows) { // Windows 에서는 환경변수 구분자가 세미콜론
                sep = ";";
            }

            for(String pathEnvOne : pathEnv) {
                if(! firsts) pathEnvValues = pathEnvValues.append(sep);
                pathEnvValues = pathEnvValues.append(pathEnvOne);
                firsts = false;
            }
            pathEnv.clear();
            env.put("PATH", pathEnvValues.toString().trim());
            pathEnvValues = null;
        }

        final StringBuilder stdBuilder = new StringBuilder("");
        final StringBuilder errBuilder = new StringBuilder("");

        p = pb.start();

        stdReader = new BufferedReader(new InputStreamReader(p.getInputStream(), charset));
        errReader = new BufferedReader(new InputStreamReader(p.getErrorStream(), charset));

        final BufferedReader fStdReader = stdReader;
        final BufferedReader fErrReader = errReader;

        threadStd = new Thread(new Runnable() {
            @Override
            public void run() {
                String line;
                while(true) {
                    try {
                        line = fStdReader.readLine();
                        if(line == null) break;
                        stdBuilder.append("\n").append(line);
                    } catch(Exception exInThread) {
                        if(logger != null) logger.error(" on runMavenByConsole, (" + exInThread.getClass().getSimpleName() + ") " + exInThread.getMessage(), exInThread);
                        else exInThread.printStackTrace();
                        break;
                    }
                }
            }
        });

        threadErr = new Thread(new Runnable() {
            @Override
            public void run() {
                String line;
                while(true) {
                    try {
                        line = fErrReader.readLine();
                        if(line == null) break;
                        errBuilder.append("\n").append(line);
                    } catch(Exception exInThread) {
                        if(logger != null) logger.error(" on runMavenByConsole, (" + exInThread.getClass().getSimpleName() + ") " + exInThread.getMessage(), exInThread);
                        else exInThread.printStackTrace();
                        break;
                    }
                }
            }
        });

        threadStd.start();
        threadErr.start();

        int exitCode = p.waitFor();

        stdReader.close(); stdReader = null;
        errReader.close(); errReader = null;

        if(exitCode != 0) throw new RuntimeException(" on runMavenByConsole, exit code is " + exitCode + "\n" + errBuilder.toString());
    } catch(Exception ex) {
        if(logger != null) logger.error(" on runMavenByConsole, (" + ex.getClass().getSimpleName() + ") " + ex.getMessage(), ex);
        else ex.printStackTrace();
        throw new RuntimeException(ex.getMessage(), ex);
    } finally {
        if(stdReader != null) { try {   stdReader.close(); stdReader = null;  } catch(Exception excx) {} }
        if(errReader != null) { try {   errReader.close(); errReader = null;  } catch(Exception excx) {} }
    }

}
%>