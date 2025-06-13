<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.tmatesoft.svn.core.*, org.tmatesoft.svn.core.wc.*" %><%@ include file="maven.jsp" %><%!
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