<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%><%@ include file="./backendCommon/common.jsp" %><%
HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);

boolean allows = false;

if(sessionMap != null) {
    String grade = sessionMap.get("GRADE") == null ? "GUEST" : sessionMap.get("GRADE").toString().trim().toUpperCase();
    if(grade == null) allows = false;
    else if("MASTER".equalsIgnoreCase(grade)) allows = true;
}

request.setAttribute("MASTER_PRIV", new Boolean(allows));
%>
<!DOCTYPE html>
<html>
<head>
<%@include file="./common/head.jsp"%>
<style>
body {  padding-left: 10px; padding-right: 10px; padding-top: 0px; }
#ta_sql { width: 100%; min-height: 200px; }
.div_btn_area { text-align: right; }
.div_res {overflow: auto; width: 100%;}
.table_res {width: 100%; border-collapse: collapse;}
.table_res th, .table_res td { border: 1px solid gray; }
</style>
<script type='text/javascript'>
$(function() {
	var divRes      = $('#div_res');
	var progRunning = $('#prog_running');
	
    $('#btn_run').on('click', function() {
    	var btns = $(this);
    	var params = {};
    	params.mode = $('#sel_mode').val();
    	params.sql  = $('#ta_sql').val();
    	
    	btns.addClass('disabled').prop('disabled', true);
    	progRunning.removeAttr('value');
    	
    	$.ajax({
    		url : '<c:url value="/jsp/program/sql.jsp"/>',
    		data : params,
    		dataType : "json",
    		method : "POST",
    		success : function(data) {
    			var divRes = $('#div_res');
    			divRes.empty();
    			
    			if(data) {
    				if(data.success) {
    					if(params.mode == 'SELECT') {
                            var idx = 0;
                            var jdx = 0;
                            
                            var htmls = "<table class='table_res'>";
                            htmls += "<colgroup>";
                            
                            if(data.columns.length >= 1) {
                            	for(idx=0; idx<data.columns.length; idx++) {
                            		htmls += "<col/>";
                            	}
                            } else {
                                htmls += "<col/>";
                            }
                            htmls += "</colgroup>";
                            
                            htmls += "<thead>";
                            htmls += "<tr>";
                            
                            idx = 0;
                            if(data.columns.length >= 1) {
                            	for(idx=0; idx<data.columns.length; idx++) {
                            		htmls += "<th data-colidx='" + idx + "'></th>";
                                }
                            } else {
                                htmls += "<th data-colidx='" + 0 + "'></th>";
                            }
                            
                            htmls += "</tr>";
                            htmls += "</thead>";
                            htmls += "<tbody>";
                            
                            if(data.data) {
                            	for(jdx=0; jdx<data.data.length; jdx++) {
                                    htmls += "<tr data-rowidx='" + jdx + "'>";
                                    
                                    idx = 0;
                                    $.each(data.data[jdx], function(k, v) {
                                        htmls += "<td data-colidx='" + idx + "' data-rowidx='" + jdx + "'></td>";
                                        idx++;
                                    });
                                    
                                    htmls += "</tr>";
                                }
                            } else {
                            	htmls += "<tr data-rowidx='" + 0 + "'>";
                            	htmls += "<th>조회된 데이터가 없습니다.</th>";
                            	htmls += "</tr>";
                            }
                            
                            
                            htmls += "</tbody>";
                            htmls += "</table>";
                            
                            divRes.append(htmls);
                            
                            var tableOne = divRes.find("table");
                            var theadOne = tableOne.find("thead");
                            var tbodyOne = tableOne.find("tbody");
                            
                            idx = 0;
                            jdx = 0;
                            
                            if(data.columns.length >= 1) {
                            	for(idx=0; idx<data.columns.length; idx++) {
                            		var theadTh = theadOne.find("th[data-colidx='" + idx + "']");
                                    theadTh.text(data.columns[idx]);
                            	}
                            }
                            
                            for(jdx=0; jdx<data.data.length; jdx++) {
                                var trOne = tbodyOne.find("tr[data-rowidx='" + jdx + "']");
                                idx = 0;
                                $.each(data.data[jdx], function(k, v) {
                                    var td = trOne.find("td[data-colidx='" + idx + "']");
                                    td.text(v);
                                    idx++;
                                });
                            }
                        } else {
                            divRes.text("영향받은 행의 수 : " + data.updates);
                        }
    				} else {
    					divRes.text("오류 ! " + data.message);
    				}
    			} else {
    				divRes.text("조회된 데이터가 없습니다.");
    			}
    			
    			console.log(data);
    		}, complete : function() {
    			btns.removeClass('disabled').prop('disabled', false);
    			progRunning.attr('value', "0");
    		}
    		
    	});
    });
    $('#ta_sql').focus();
});
</script>
<title>Deploy Broker</title>
</head>
<body>
    <div class='div_dxdeploy_root deploy_root wrapper deploy_theme_dark'>
        <h2>SQL Manager</h2>
        <c:choose>
        <c:when test="${MASTER_PRIV}">
            <div>
                <h4>SQL</h4>
                <div>
                    <textarea id='ta_sql' placeholder='이 곳에 실행할 SQL문을 입력해 주세요.'></textarea>
                </div>
                <div class='div_btn_area'>
                    <progress max="0" value="0" id="prog_running"></progress>
                    <select id='sel_mode'>
                        <option value='SELECT'>SELECT</option>
                        <option value='UPDATE'>UPDATE</option>
                    </select>
                    <input type='button' value='실행' id='btn_run'/>
                </div>
            </div>
            <div>
                <h4>Results</h4>
                <div id='div_res' class='div_res'>실행된 SQL문이 아직 없습니다.</div>
            </div>
        </c:when>
        <c:otherwise>
        이 기능을 사용할 권한이 없습니다.
        </c:otherwise>
        </c:choose>
    </div>
</body>
</html>