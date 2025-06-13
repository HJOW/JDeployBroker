<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
<%@include file="./jsp/common/head.jsp"%>
<style>
body {  padding-left: 10px; padding-right: 10px; }
</style>
<script type='text/babel'>
$(function() {
	var rroot = ReactDOM.createRoot( $('.div_dxdeploy_root')[0] );
    rroot.render(React.createElement(  DXDeployMain  ));
});
</script>
<title>Deploy Broker</title>
</head>
<body>
    <div class='div_dxdeploy_root deploy_root wrapper deploy_theme_dark'></div>
</body>
</html>