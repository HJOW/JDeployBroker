<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
<%@include file="./jsp/common/head.jsp"%>
<style>
body { margin: 0; padding-top: 0; padding-left: 10px; padding-right: 10px; }
</style>



<script type="text/javascript">
var __moved = false;
function fn_calledFromIframe() {
	if(__moved) return;
    location.href = '<c:url value="/program.jsp"/>';
    __moved = true;
};
$(function() {
	$('#div_loaging_screen').css('padding-top', Math.floor(window.innerHeight / 2) + 'px');
	$('#iframe_loading').attr('src', $.ctx + '/jsp/loadingpage.jsp');
	setTimeout(fn_calledFromIframe, 8000);
});
</script>
<title>Deploy Broker</title>
</head>
<body>
    <div class='div_dxdeploy_root deploy_root wrapper deploy_theme_dark'>
        <div style='text-align: center; padding-top: 500px;' id='div_loaging_screen'>
            <div><progress></progress></div>
            <div>잠시만 기다려 주십시오...</div>
        </div>
        <div class='invisible'>
            <iframe id='iframe_loading' class='full'></iframe>
        </div>
    </div>
</body>
</html>