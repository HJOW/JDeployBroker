<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.apache.maven.shared.invoker.*, org.apache.maven.shared.utils.cli.CommandLineException" %><%@ include file="common.jsp" %><%!
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
%>