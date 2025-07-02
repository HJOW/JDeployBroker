<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%><%
HttpSession sess = request.getSession(); // 세션 새로고침 됨
request.setAttribute("ctx", sess.getServletContext().getContextPath());
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="icon" type='icon/x-icon' href='<c:url value="/resources/favicon.ico"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.structure.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.theme.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dxframe.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dx.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dx-dark.css"/>'/>
<script type='text/javascript' src='<c:url value="/resources/jquery/jquery-1.12.4.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/jquery/jquery-migrate-1.4.1.min.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.js"/>'></script>
<style type="text/css">
body, div {
    margin : 0;
    padding: 0;
    text-align: center;
    vertical-align: middle;
    overflow: hidden;
    width: 100%;
}
div progress {
    text-align: center;
    vertical-align: middle;
    width: 90%;
}
</style>
<script type='text/javascript'>
$.ctx = '<c:out value="${ctx}"/>';
$(function(){
	var divs = $('div');
	var prgs = divs.find('progress');
	var values = 0;
	var maxes  = 200;
	
    var fResize = function() { 
    	var hg = window.innerHeight;
    	divs.height(hg);
    	prgs.css('margin-top', Math.floor(hg / 2.0) + 'px');
    }
    
    $(window).on('resize', fResize);
    fResize();
    
    prgs.attr('max', maxes);
    setInterval(function() {
    	if(values >= maxes) { values = 0; location.reload(); return; }
    	values++;
    	
    	prgs.attr('value', values);
    }, 200);
});
</script>
<title>Session Timeout Extender</title>
</head>
<body>
    <div><progress></progress></div>
</body>
</html>