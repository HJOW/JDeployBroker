<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%><%@ include file="./backendCommon/common.jsp" %><%
HttpSession sess = request.getSession();
Map<String, String> sessionMap = getSessionMap(sess);

boolean allows = false;

if(sessionMap != null) {
    String grade = sessionMap.get("GRADE") == null ? "GUEST" : sessionMap.get("GRADE").toString().trim().toUpperCase();
    if(grade == null) allows = false;
    else if("MASTER".equalsIgnoreCase(grade)) allows = true;
}


request.setAttribute("USE_DB", new Boolean(checkUsingDB()));
request.setAttribute("MASTER_PRIV", new Boolean(allows));
%>
<!DOCTYPE html>
<html>
<head>
<%@include file="./common/head.jsp"%>
<style>
body {  padding: 5px 5px 5px 5px; overflow-x: hidden; overflow-y: auto; min-height: 600px; }
body.dark { background-color: rgba(70, 70, 70, 0.99); color: rgba(230, 230, 230, 0.99); }
.tabroot .tabelement { display: none; padding: 5px 5px 5px 5px; }
.tabroot .tabelement.active { display: block; }
.tabroot .tabbtn:hover { background-color: rgba(110, 110, 110, 0.85); color: rgba(240, 240, 240, 0.99); }
.tabroot .tabbtn.active { background-color: rgba(140, 140, 140, 0.9); color: rgba(250, 250, 250, 0.99); }
.tabroot .tabbtn.active:hover { background-color: rgba(150, 150, 150, 0.9); color: rgba(250, 250, 250, 0.99); }
#ta_sql { width: 100%; min-height: 200px; }
.div_btn_area { text-align: right; }
.div_res {overflow: auto; width: 100%; min-height: 180px;}
.table_res {width: 100%; border-collapse: collapse;}
.table_res th, .table_res td { border: 1px solid gray; }
#ta_configviewer_status {width: 100%; min-height: 400px;}
</style>
<script type='text/javascript'>
$(function() {
	// 창 크기 변경 이벤트 설정
    setTimeout(function() {
        var heightRes = $('#div_res').height();
        var heightCfg = $('#ta_configviewer_status').height();
        var firstHeight = window.outerHeight;
        
        var fResize = function() {
            // var nowSize = $('#div_res').height();
            var winSize = window.outerHeight;
            
            $('#div_res').height( heightRes + (winSize - firstHeight) );
            $('#ta_configviewer_status').height( heightCfg + (winSize - firstHeight) );
        };
        $(window).on('resize', fResize);
        fResize();
    }, 250);
    
    // 탭 설정
    var fTabs = {};
    var tabArea = $('.tabroot');
    tabArea.find('.tablist').find('.tabbtn').each(function() {
        var btnOne = $(this);
        var tabNo  = btnOne.attr('data-tab');
        btnOne.on('click', function() {
            tabArea.find('.tablist').find('.tabbtn').removeClass('active');
            $(this).addClass('active');
            
            tabArea.find('.tabelement').removeClass('active');
            tabArea.find('.tabelement').each(function() {
                var dNo = $(this).attr('data-tab');
                if(tabNo == dNo) $(this).addClass('active');
            });
            
            var func = fTabs[tabNo];
            if(typeof(func) == 'function') func();
        }).addClass('binded_click');
    });
    
	// SQL Manager 세팅
    var divRes      = $('#div_res');
    var progRunning = $('#prog_running');
    
    $('body').addClass('dark');
    $('.deploy_root').addClass('dark');
    
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
                                var rows = data.data[jdx];
                                idx = 0;
                                
                                for(idx=0; idx<data.columns.length; idx++) {
                                    var td = trOne.find("td[data-colidx='" + idx + "']");
                                    td.text(rows[ data.columns[idx] ]);
                                }
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
            }, complete : function() {
                btns.removeClass('disabled').prop('disabled', false);
                progRunning.attr('value', "0");
            }
            
        });
    });
    
    // Config Viewer 세팅
    fTabs['2'] = function() {
    	var ta = $('#ta_configviewer_status');
    	$.dx.ajax({
    		url : $.ctx + '/jsp/program/seeconfig.jsp',
    		dataType : 'json',
    		method : 'POST',
    		success : function(data) {
    			if(! data.success) {
    				ta.val(data.message);
    			} else {
    				try {
    					var jsons = JSON.parse(data.data);
    					ta.val(JSON.stringify(jsons, null, 2));
    				} catch(e) {
    					ta.val('오류 : ' + e);
    				}
    			}
    		}, error : function(jqXHR, textStatus, errorThrown) {
    			ta.val('오류 : ' + errorThrown);
    		}
    	});
    };
    fTabs['2']();
    
    // 포커스
    $('#ta_sql').focus();
});
</script>
<title>Deploy Broker</title>
</head>
<body>
    <div class='div_dxdeploy_root deploy_root wrapper deploy_theme_dark tabroot'>
        <h2>Admin Manager</h2>
        <c:choose>
        <c:when test="${MASTER_PRIV}">
            <div class='tabroot'>
                <div class='tablist'>
                    <input type='button' value='Config Viewer' data-tab='1' class='tabbtn active'/>
                    
                    <c:if test="${USE_DB}">
                        <input type='button' value='SQL Manager' data-tab='2' class='tabbtn'/>
                    </c:if>
                </div>
                <div class='tabelement tab_1 active' data-tab='1'>
                    <h3>Config Viewer</h3>
                    <div>
                        <textarea id='ta_configviewer_status' readonly>
                        
                        </textarea>
                    </div>
                </div>
                
                <div class='tabelement tab_2' data-tab='2'>
                    <h3>SQL Manager</h3>
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
                            <input type='button' value='실행 (ALT + G)' id='btn_run' accesskey="G"/>
                        </div>
                    </div>
                    <div>
                        <h4>Results</h4>
                        <div id='div_res' class='div_res'>실행된 SQL문이 아직 없습니다.</div>
                    </div>
                </div>
            </div>
        </c:when>
        <c:otherwise>
        <div>이 기능을 사용할 권한이 없습니다.</div>
        <div><a href='javascript:self.close();'>확인</a></div>
        </c:otherwise>
        </c:choose>
    </div>
</body>
</html>