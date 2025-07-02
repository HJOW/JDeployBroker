<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*" %><%@ include file="maven.jsp" %><%!
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

public long checkoutSVN(File dir, String svnUrl, long revision, String id, String password) {
    if(dir.exists()) delete(dir);
    if(! dir.exists()) dir.mkdirs();
    
    boolean useJavaHL = false;
    
    // JavaHL 라이브러리 존재여부 체크
    try {
        Class.forName("org.tmatesoft.svn.core.wc.SVNClientManager");
        useJavaHL = false;
    } catch(ClassNotFoundException ex) {
        useJavaHL = true;
    }
    
    if(useJavaHL) {
        // JavaHL 을 통한 체크아웃 (javahl-1.14.1.jar, 그외 libsvnjavahl-1.dll 등의 라이브러리 필요)
        try {
            org.apache.subversion.javahl.SVNClient client = new org.apache.subversion.javahl.SVNClient();
            
            org.apache.subversion.javahl.types.Revision revObj = org.apache.subversion.javahl.types.Revision.HEAD;
            if(revision >= 0L) revObj = org.apache.subversion.javahl.types.Revision.getInstance(revision);

            return client.checkout(svnUrl, dir.getAbsolutePath(), revObj, org.apache.subversion.javahl.types.Revision.HEAD, org.apache.subversion.javahl.types.Depth.infinity, false, true);
        } catch(org.apache.subversion.javahl.ClientException ex) {
            throw new RuntimeException("AUTH FAILED - " + ex.getMessage(), ex);
        } catch(Exception ex) {
            throw new RuntimeException(ex.getMessage(), ex);
        }
    } 
    if(! useJavaHL) {
        // SVNKit 을 통한 체크아웃
        //    SVNKit 구동 시에는 다음 jar 파일들이 필요하다.
        //        svnkit-1.8.14.jar
        //        sequence-library-1.0.3.jar
        //        sqljet-1.1.10.jar
        //        antlr-runtime-3.4.jar
        //        jna-4.1.0.jar
        //        jna-platform-4.1.0.jar
        //        trilead-ssh2-1.0.0-build221.jar
        //        platform-3.4.0.jar
        //        jsch.agentproxy.connector-factory-0.0.7.jar
        //        jsch.agentproxy.core-0.0.7.jar
        //        jsch.agentproxy.pageant-0.0.7.jar
        //        jsch.agentproxy.sshagent-0.0.7.jar
        //        jsch.agentproxy.svnkit-trilead-ssh2-0.0.7.jar
        //        jsch.agentproxy.usocket-jna-0.0.7.jar
        //        jsch.agentproxy.usocket-nc-0.0.7.jar
        try {
            org.tmatesoft.svn.core.wc.SVNClientManager clientManager = org.tmatesoft.svn.core.wc.SVNClientManager.newInstance(org.tmatesoft.svn.core.wc.SVNWCUtil.createDefaultOptions(true), id, password);
            
            org.tmatesoft.svn.core.wc.SVNRevision revObj = org.tmatesoft.svn.core.wc.SVNRevision.HEAD;
            if(revision >= 0L) revObj = org.tmatesoft.svn.core.wc.SVNRevision.create(revision);

            org.tmatesoft.svn.core.SVNURL svnUrlInst = org.tmatesoft.svn.core.SVNURL.parseURIDecoded(svnUrl);
            return clientManager.getUpdateClient().doCheckout(svnUrlInst, dir, org.tmatesoft.svn.core.wc.SVNRevision.HEAD, revObj, org.tmatesoft.svn.core.SVNDepth.INFINITY, true);
        } catch(org.tmatesoft.svn.core.SVNAuthenticationException ex) {
            throw new RuntimeException("AUTH FAILED - " + ex.getMessage(), ex);
        } catch(Exception ex) {
            throw new RuntimeException(ex.getMessage(), ex);
        }
    }
    
    throw new RuntimeException("Cannot found SVN client kit.");
}

public long checkoutSVN(File dir, String svnUrl, String id, String password) {
    return checkoutSVN(dir, svnUrl, -1, id, password);
}
%>