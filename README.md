JDeployBroker
------------------------------------------------------------------------------
주의 !
이 프로젝트는 제가 개인적으로 필요할 때마다 기능 추가하여 사용하는 프로젝트로
일반 사용 용도로는 아직 적합하지 않습니다.
수많은 버그와 보안 취약점이 존재할 수 있습니다.

------------------------------------------------------------------------------

JSP/서블릿 웹 프로젝트 (war) 배포를 위한 프로그램입니다.
구버전 JDK 사용 등의 이유로 Jenkins 사용이 불가능한 환경에서 사용하기 위해 개발했습니다.

이 JDeployBroker 또한 웹 기반 프로그램입니다.
Tomcat 등의 웹 컨테이너 혹은 WAS 에 배포하여 사용합니다.

프로그램 특성상 보안에 매우 큰 영향이 있습니다.
되도록이면 접속할 수 있는 IP 를 제한하여 사용하시기 바랍니다.

------------------------------------------------------------------------------
JDK 8, 톰캣 9가 필요합니다.  
Eclipse, IntelliJ IDEA로 작업 가능합니다.  

스프링을 사용하지 않았으며  
일부 백엔드 소스 또한 jsp 로 구현되어 있습니다.  

DB를 사용하지 않습니다.  
로그인 계정, 배포 경로 모두 config.xml 파일 하나로 관리됩니다.  

------------------------------------------------------------------------------

웹경로 / WEB-INF / classes / config.xml 파일 예제 및 설명

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>
Deploy Manager

설정 : 아래의 내용들을 수정하여 기능을 수정할 수 있다.

EnvMode : 로컬 / 개발 / 운영 등 실행 환경 설정 (local / dev / real, 현재는 의미가 없으며, 이 셋 중 아무 값이나 넣으면 된다.)
MainUrl : 이 Deploy Manager 의 메인 URL
Charset : 요청 / 응답 캐릭터셋 (UTF-8 을 사용할 것 !)
Manager : 매니저 (사용자) 계정
   예: { "ID" : "master", "PASSWORD" : "Deploy1!", "NAME" : "관리자", "GRADE" : "MASTER", "ALLOWS" : "" }
   항목 설명
       ID   : 사용자 ID
       NAME : 성명 (로그인 시 화면에 출력됨)
       PASSWORD : 로그인에 쓰일 암호 
       GRADE : 사용자 등급 (MASTER / USER) - MASTER 지정 시 모두 허용되므로 ALLOWS 항목이 의미가 없어짐.
       ALLOWS : 아래 배포 대상들 중 사용 권한을 부여할 배포 대상 이름을 이 곳에 기재하며, 콤마로 구분한다.

Deploy : 배포 대상
   예: { "TYPE" : "WAR", "NAME" : "DX", "REAL_PATH" : "C:/apache-tomcat-9.0.104/webapps/", "URL" : "http://192.168.0.11:8080/DOC/" }
   항목 설명
       TYPE : 배포 방식 유형 (WAR, SVN, GIT) - SVN 이나 GIT 사용 시, 프로젝트는 Maven 을 사용해야 하며, 프로젝트 루트 경로에 pom.xml 이 존재해야 함.
       NAME : 배포 대상 이름, 사용자 권한 부여할 때도 쓰이며, 배포 시 war 파일의 이름으로도 쓰인다.
       REAL_PATH : 배포 시 실제 war 파일이 저장될 디렉토리 경로를 지정한다. 역슬래시는 일반슬래시로 바꾸어 써야 한다. war 파일이 이미 존재하는 경우 덮어 씌워진다.
       URL : 해당 배포 대상 웹 프로젝트의 URL 로, 화면 내에서 제목 부분을 클릭하면 이 URL이 새 창으로 호출된다.
       DISABLED : 비활성 여부 (Y/N) 선택사항으로 기본값은 N, Y로 지정 시 로드되지 않음. (사용하지 않으나 기록으로 남기고 싶을 때 사용)
   배포 방식 유형이 GIT 또는 SVN인 경우 추가 항목이 필요함
       REPO : 저장소 URL (GIT 원격 저장소 또는 SVN 서버 URL)
       BUILDER : 소스 빌드 툴 유형 (MAVEN)
       GOAL : Maven Goal (여러 개 지정 시 콤마로 구분)
       PROFILE : Maven Profile (사용하지 않는 경우 공란으로 설정 필요) 
       WARDIR : Maven 작업 후 war 파일이 생성되는 위치 (상대경로로 지정)
   배포 방식 유형이 SVN인 경우 추가 항목이 필요함
       REPO_ID : SVN 계정 ID
       REPO_PW : SVN 계정 암호
       
IPFilterMode : 접속 IP 필터링 모드, ALL / BLACKLIST / WHITELIST 중 입력
    BLACKLIST 또는 WHITELIST 사용 시 IPFilter 를 같이 사용함
    항목 설명
       ALL : 전부 접속 허용
       BLACKLIST : IPFilter 에 지정된 IP 는 접속이 차단
       WHITELIST : IPFilter 에 지정된 IP 만 접속이 허용 (나머지는 차단 !)
IPFilter : 접속 허용 또는 차단 대상 IP 패턴을 입력, IPFilterMode 에서 ALL이 아닌 다른 항목 사용 시 필요함. 콤마로 구분.
JAVA_HOME : 지금은 사용하지 않습니다.
MAVEN_HOME : 지금은 사용하지 않습니다.
TEMP_DIR : 임시 파일 디렉토리를 지정할 수 있습니다. 선택사항으로, 비워둘 경우 java.io.tmpdir 환경변수 값을 사용합니다.
</comment>
<entry key="EnvMode">local</entry>
<entry key="MainUrl">http://localhost:9191/DeployBroker/</entry>
<entry key="Charset">UTF-8</entry>
<entry key="Manager">
[
    { "ID" : "master", "PASSWORD" : "Deploy1!", "NAME" : "관리자", "GRADE" : "MASTER", "ALLOWS" : "" }
]
</entry>
<entry key="Deploy">
[
    { "TYPE" : "WAR", "NAME" : "DOC" , "REAL_PATH" : "H:/Temp/DeployBroker/1", "URL" : "http://localhost:9191/DeployBroker/" },
    { "TYPE" : "SVN", "NAME" : "BBS" , "REAL_PATH" : "H:/Temp/DeployBroker/2", "URL" : "http://localhost:9191/DeployBroker/", "REPO" : "https://192.168.0.20/svn/bbs", "REPO_ID" : "", "REPO_PW" : "", "BUILDER" : "MAVEN", "GOAL" : "install", "PROFILE" : "dev", "WARDIR" : "/target/BBS.war", "DISABLED" : "Y" }
]
</entry>
<entry key="IPFilterMode">WHITELIST</entry>
<entry key="IPFilter">192.168.*.*,127.0.0.1,0:0:0:0:0:0:0:1</entry>
<entry key="JAVA_HOME">C:/Program Files/Java/jdk1.8.0_202</entry>
<entry key="MAVEN_HOME">C:/Apps/Maven</entry>
<entry key="TEMP_DIR">H:/Temp/DeployBroker/t</entry>
</properties>
```
------------------------------------------------------------------------------
LICENSE

Copyright 2025 HJOW (hujinone22@naver.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

------------------------------------------------------------------------------
Using third-parties

antlr
commons-codec
commons-collections
commons-fileupload
commons-io
commons-logging
commons-net
cos
log4j2
slf4j (API)
maven-invoker
eclipse jgit
platform
sequence-library
simpleconfigs
sqljet
svnkit
taglibs-standard
trilead-ssh2
jna
jsch
jackson
jQuery
jQuery-UI
babel-standalone
react
bootstrap3
Nanum Gothic