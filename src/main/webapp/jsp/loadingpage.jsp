<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
<%@include file="./common/head.jsp"%>
</head>
<body>
    <div class='div_dxdeploy_root deploy_root wrapper deploy_theme_dark'></div>
    <script type='text/javascript'>
    $(function() {
    	window.parent.fn_calledFromIframe();
    });
    </script>
</body>
</html>