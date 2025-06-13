<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.eclipse.jgit.api.Git" %><%@ include file="maven.jsp" %><%!
public Git cloneGit(File dir, String remoteUrl) {
    if(dir.exists()) delete(dir);
    if(! dir.exists()) dir.mkdirs();
    
    try {
        return Git.cloneRepository().setURI(remoteUrl).setDirectory(dir).call();
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    }
}
%>