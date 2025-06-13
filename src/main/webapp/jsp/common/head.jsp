<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%><%
    String ctx = session.getServletContext().getContextPath();
    request.setAttribute("ctx", ctx);

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
%>
<meta charset="UTF-8"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link rel="icon" type='icon/x-icon' href='<c:url value="/resources/favicon.ico"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/fonts/fonts.css"/>'/>

<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.structure.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.theme.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/bootstrap-3.4.1-dist/css/bootstrap.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/bootstrap-3.4.1-dist/css/bootstrap-theme.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/jquery.toast.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dxframe.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/login.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dx.css"/>'/>
<link rel="stylesheet" type="text/css" href='<c:url value="/resources/dx-dark.css"/>'/>
<script type='text/javascript' src='<c:url value="/resources/jquery/jquery-1.12.4.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/jquery/jquery-migrate-1.4.1.min.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/jqueryui/themes/dark/jquery-ui.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/bootstrap-3.4.1-dist/js/bootstrap.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/jquery.toast.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/moment.min.js"/>'></script>
<script type='text/javascript'>
$.ctx = '<c:out value="${ctx}"/>';
</script>
<script type='text/javascript' src='<c:url value="/resources/dx.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/react/babel.min.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/react/react.development.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/react/react-dom.development.js"/>'></script>
<!--
<script type='text/javascript' src='<c:url value="/resources/react/react.production.min.js"/>'></script>
<script type='text/javascript' src='<c:url value="/resources/react/react-dom.production.min.js"/>'></script>
-->
<script type='text/babel' src='<c:url value="/resources/deploy.js"/>'></script>