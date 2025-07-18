<%@ page language="java" pageEncoding="UTF-8" import="java.util.*, java.io.*, org.eclipse.jgit.api.*, org.eclipse.jgit.lib.*, org.eclipse.jgit.revwalk.*, org.eclipse.jgit.transport.*" %>
<%@ page import="org.eclipse.jgit.api.CloneCommand" %>
<%@ include file="maven.jsp" %><%!
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

public Git cloneGit(File dir, String remoteUrl, String branch) {
    if(dir.exists()) delete(dir);
    if(! dir.exists()) dir.mkdirs();
    
    try {
        CloneCommand cmd = Git.cloneRepository().setURI(remoteUrl);
        if(branch != null) {
            List<String> lists = new ArrayList<String>();
            lists.add(branch);
            cmd.setBranchesToClone(lists);
        }
        return cmd.setDirectory(dir).call();
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    }
}

public Git cloneGit(File dir, String remoteUrl) {
    return cloneGit(dir, remoteUrl, null);
}

public List<Map<String, Object>> getHistory(String remoteUrl) {
    Git git = null;
    try {
        Repository repo = null;
        
        // CredentialsProvider cre = new UsernamePasswordCredentialsProvider(id, password);
        
        List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
        
        git = new Git(repo);
        Iterable<RevCommit> commits = git.log().all().call();
        for(RevCommit commitOne : commits) {
            Map<String, Object> entryMap = new HashMap<String, Object>();
            
            entryMap.put("revision", String.valueOf(commitOne.getId()));
            entryMap.put("author", commitOne.getAuthorIdent().getName());
            entryMap.put("date", commitOne.getCommitTime());
            entryMap.put("message", commitOne.getFullMessage());
            
            list.add(entryMap);
        }
        
        return list;
    } catch(Exception ex) {
        throw new RuntimeException(ex.getMessage(), ex);
    } finally {
        if(git != null) {
            git.close();
        }
    }
}
%>