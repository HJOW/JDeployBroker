<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.tmatesoft.svn.core.*, org.tmatesoft.svn.core.wc.*" %><%@ include file="maven.jsp" %><%!
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

public long checkoutSVN(File dir, String svnUrl, String id, String password) {
    if(dir.exists()) delete(dir);
    if(! dir.exists()) dir.mkdirs();
    
    SVNClientManager clientManager = SVNClientManager.newInstance(SVNWCUtil.createDefaultOptions(true), id, password);
    long rev;
    
    try {
        SVNURL svnUrlInst = SVNURL.parseURIDecoded(svnUrl);
        return clientManager.getUpdateClient().doCheckout(svnUrlInst, dir, SVNRevision.HEAD, SVNRevision.HEAD, SVNDepth.INFINITY, true);
    } catch(SVNAuthenticationException ex) {
        throw new RuntimeException("AUTH FAILED - " + ex.getMessage(), ex);
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    }
}
%>