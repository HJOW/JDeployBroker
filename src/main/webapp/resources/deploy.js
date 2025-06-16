/** Deploy Broker 프로젝트의 화면 구성 및 그를 위한 함수 선언 파일 */

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

/** 작업 진행 상황을 가져와 반환, Promise 타입 */
function fGetProgress(jobType, jobCode) {
    return new Promise(function(resolve, reject) {
        $.dx.ajax({
            url : $.ctx + '/jsp/session/checkProgress.jsp',
            data : { jobType : jobType, jobCode : jobCode },
            method : 'POST',
            dataType : 'json',
            success : function(res) {
                if(res.success) resolve(res.progress);
                else reject(res.message);
            }, error(jqXHR, textStatus, errorThrown) {
                reject(textStatus);
            }
        });
    });
}

/** Deploy Broker 메인 화면 컴포넌트 */
class DXDeployMain extends React.Component {
    state = {
        session : { logined : false }
    };
    
    checkSessionStatus() {
        const selfs = this;
        return new Promise((resolve, reject) => {
            $.dx.ajax({
                url : $.ctx + '/jsp/session/checkSession.jsp',
                data : {},
                method : 'POST',
                dataType : 'json',
                success : function(res) {
                    if(res.success) {
                        selfs.setState({
                            session : {
                                logined : true,
                                ID : res.session.ID,
                                NAME : res.session.NAME
                            }
                        }, () => { resolve(res); });
                    } else {
                        selfs.setState({
                            session : {logined : false}
                        }, () => {
                            if(res.message == 'Not logined') reject(null);
                            else reject(res.message);
                        });
                    }
                }, error : function() {
                    reject(null);
                }
            });
        });
    }
    
    componentDidMount() {
        const selfs = this;
        this.checkSessionStatus().catch((exc) => {
            if(exc != null) $.toast('Error : ' + exc);
            selfs.setState({session : { logined : false }});
        });
    }
    
    render() {
        return (
            <div className="deploybroker_root">
                 <DXNorthBar          session={this.state.session} root={this}/>
                 <DXDeployContentArea session={this.state.session} root={this}/>
                 <DXHiddenArea        session={this.state.session}/>
            </div>
        );
    }
}

function DXHiddenArea(props) {
    return (
        <div className="dxdeploy_hidden invisible">
            <textarea className="dxdeploy_hidden_session" defaultValue={ JSON.stringify(props.session) } readOnly={true}></textarea>
            <textarea className="dxdeploy_hidden_ctx"     defaultValue={ $.ctx } readOnly={true}></textarea>
        </div>
    );
}

class DXNorthBar extends React.Component {
    tryLogout() {
        const selfs = this;
        this.processLogout().then((sess) => {
            selfs.props.root.checkSessionStatus().then((res) => {  }).catch((err) => { $.toast(err); });
        }).catch((err) => { $.toast(err); });
    }

    processLogout() {
        const selfs = this;
        return new Promise((resolve, reject) => {
            $.dx.ajax({
                url : $.ctx + '/jsp/session/logout.jsp',
                data : {},
                method : 'POST',
                dataType : 'json',
                success : function(res) {
                    if(res.success) {
                        resolve(true);
                    } else {
                        reject(res.message);
                    }
                }, error : function() {
                    reject(null);
                }
            });
        });
    }

    render() {
        if(this.props.session.logined) {
            return (
                <nav className="navbar navbar-inverse navbar-fixed-top deployx_bodyheader">
                    <div className="container-fluid">
                        <div className="row">
                            <div className="col-12">
                                <div className="navbar-header">
                                    <a className="navbar-brand">
                                        <img src={ $.ctx + '/resources/logo.png' } alt="Deploy Broker" style={{ height : '100%' }}/>
                                    </a>
                                </div>
                                <div className="dxdeploy_sessionbar navbar-collapse collapse navbar-sessionarea" id="navbar" style={{"paddingRight" : "10px"}}>
                                    <ul className="nav navbar-nav navbar-right">
                                        <li>
                                            <a href="#" className="a_navtop_session a_navtop_profile">{this.props.session.NAME} ({this.props.session.ID}) 님 환영합니다.</a>
                                        </li>
                                        <li>
                                            <a href="#" className="a_navtop_session a_navtop_session_ctrl a_navtop_logout" onClick={() => { this.tryLogout(); }}>로그아웃</a>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </nav>
            );
        } else {
            return (
                <div className="dxdeploy_sessionbar">
            
                </div>
            );
        }
    }
}

class DXDeployContentArea extends React.Component {
    state = {
        targets : []
    };

    componentDidMount() {
        this.tryGetTargets();
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if(prevProps.session.logined != this.props.session.logined) {
            this.tryGetTargets();
        }
    }

    checkSessionStatus() {
        return this.props.root.checkSessionStatus();
    }

    tryGetTargets() {
        const selfs = this;
        this.getTargets().then((tg) => {
            selfs.setState({targets : tg});
        }).catch((err) => {
            if(err == 'not logined') return;
            $.toast(err);
        });
    }

    getTargets() {
        const selfs = this;
        return new Promise((resolve, reject) => {
            if(! this.props.session.logined) {
                reject('not logined');
                return;
            }

            $.dx.ajax({
                url : $.ctx + '/jsp/program/targets.jsp',
                data : {},
                method : 'POST',
                dataType : 'json',
                success : function(res) {
                    if(res.success) {
                        resolve(res.targets);
                    } else {
                        reject(res.message);
                    }
                }, error : function() {
                    reject(null);
                }
            });
        });
    }

    render() {
        if(this.props.session.logined) {
            return (
                <div className="dxdeploy_content">
                    <div className="div_dxdeploy_content">
                        {
                            this.state.targets.map((tg, idx) => {
                                if(tg.TYPE == 'SVN') {
                                    return (<DXSVNTarget root={this} key={idx} targetdata={tg}/>);
                                } else if(tg.TYPE == 'GIT') {
                                    return (<DXGITTarget root={this} key={idx} targetdata={tg}/>);
                                } else {
                                    return (<DXTarget root={this} key={idx} targetdata={tg}/>);
                                }
                            })
                        }
                    </div>
                </div>
            );
        } else {
            return (
                <DXLoginScreen root={this.props.root}/>
            );
        }
    }
}

class DXLoginScreen extends React.Component {
    state = {
        id : '',
        pw : ''
    };

    componentDidMount() {
        this.bindLoginButtonEvents();
    }

    componentDidUpdate() {
        this.bindLoginButtonEvents();
    }

    /** 로그인 버튼 및 엔터키 이벤트 부여 (React 의 onClick 으로 이벤트를 주면 jQuery의 trigger 가 동작하지 않음.) */
    bindLoginButtonEvents() {
        const selfs = this;

        // 엔터키 이벤트
        $.dx.applyEnterSearch();

        // 로그인 버튼
        const btnSubmit = $('#btnSubmit');
        if(! btnSubmit.is('.binded_click')) {
            btnSubmit.on('click', () => { selfs.tryLogin(); });
        }

        // 포커스
        $('.dxdeploy_login_focus').focus();
    }

    tryLogin() {

        const selfs = this;
        this.processLogin().then((sess) => {
            selfs.props.root.checkSessionStatus().then((res) => {  }).catch((err) => { $.toast(err); });
        }).catch((err) => { $.toast(err); });
    }

    processLogin() {
        const selfs = this;
        return new Promise((resolve, reject) => {
            $.dx.ajax({
                url : $.ctx + '/jsp/session/login.jsp',
                data : $.dx.buildJsonFrom('#form_login'),
                method : 'POST',
                dataType : 'json',
                success : function(res) {
                    if(res.success) {
                        resolve(res.session);
                    } else {
                        if(res.message == 'Not logined') reject(null);
                        else reject(res.message);
                    }
                }, error : function() {
                    reject(null);
                }
            });
        });
    }

    render() {
        return (
            <div className="dxdeploy_content deployx_login">
                <div className="div_deployx_login">
                    <form onSubmit={() => {return false}} className='form_login form-signin' id='form_login'>
                        <div className='login_body'>
                            <h2 className="form-signin-heading" style={{"fontSize" : "2rem"}}>Deploy Broker</h2>
                            <label htmlFor="dxlogin_id" className="sr-only">Email address</label>
                            <input type="text" id="dxlogin_id" className="form-control" placeholder="ID" name="id" required={true} autoFocus={true}/>
                            <label htmlFor="dxlogin_pw" className="sr-only">Password</label>
                            <input type="password" id="dxlogin_pw" name="pw" className="form-control" placeholder="Password" required={true}/>
                            <div style={{"textAlign" : "right"}}><button className="dxbtn dxbtn2" type="button" id="btnSubmit">LOG IN</button></div>
                        </div>
                    </form>
                </div>
            </div>
        );
    }
}

class DXTarget extends React.Component {
    componentDidMount() {
        $.dx.progressbar.apply();
    }

    componentDidUpdate() {
        $.dx.progressbar.apply();
    }

    submitTarget() {
        const selfs = this;
        let formTag = null;
        $('.form_target_element').each(function() {
            if( $(this).attr('data-name') == selfs.props.targetdata.NAME )  {
                formTag = $(this);
            }
        });

        if(formTag == null) { alert('배포 대상 정보를 매핑하는 데 실패하였습니다. 화면을 새로고침하여 주십시오.'); return; }

        // 파일 첨부 여부 체크
        const inpFile = formTag.find("[name='war']")[0];
        if(inpFile.files.length <= 0) { alert('파일을 첨부하신 후 진행해 주세요.'); return; }
        if(inpFile.files.length >= 2) { alert('파일은 하나만 첨부하실 수 있습니다.'); return; }

        // 첨부된 파일의 확장자 체크
        const fileName = inpFile.files[0].name;
        const fileExt = fileName.slice(fileName.lastIndexOf('.') + 1).toLowerCase();

        if(fileExt != 'war') { alert('war 파일만 첨부하실 수 있습니다.'); return; }

        const targetName = formTag.find("[name='NAME']").val();
        const divProg    = formTag.find(".deploy_progress");
        const btnSubmit  = formTag.find("input.btnSubmitTarget");

        // 버튼 비활성화하고, 프로그레스바 가동
        btnSubmit.prop('disabled', true);
        divProg.attr('data-value', '');
        divProg.attr('data-max', '100');
        divProg.attr('data-message', '작업 준비 중...');

        // 타이머 준비
        const varJobType = formTag.find("[name='JobType']").val();
        const varJobCode = formTag.find("[name='JobCode']").val();
        let completed  = false;
        let timer = setInterval(() => {
            fGetProgress(varJobType, varJobCode).then((res) => {
                if(timer == null) return;
                if(completed) return;
                divProg.attr('data-max', res.max);
                divProg.attr('data-value', res.value);
                if(res.message) {
                    divProg.attr('data-message', res.message);
                }
            });
        }, 2000);

        // 전송
        const formData = new FormData( formTag[0] );
        let endMsg = '';
        $.dx.ajax({
            url : $.ctx + '/jsp/program/deploy.jsp',
            data : formData,
            method : 'POST',
            processData : false,
            contentType : false,
            success : function(res) {
                if(! res.success) {
                    endMsg = '배포 실패, ' + res.message;
                } else {
                    endMsg = targetName + ' 배포 완료';
                }
            }, error : function(jqXHR, textStatus, errorThrown) {
                $.toast('배포에 실패하였습니다.');
                $.toast(errorThrown);
                endMsg = '배포 실패, ' + errorThrown;
            }, complete : function() {
                completed = true;

                // form 태그 초기화 (일부 항목은 초기화 후 복원)
                formTag[0].reset();
                formTag.find("[name='NAME']").val(targetName);

                try {
                    // 타이머 끄기
                    if(timer != null) {
                        clearInterval(timer);
                        timer = null;
                    }
                } catch(e) {
                    $.dx.log(e);
                }

                // 버튼 복구하고 프로그레스바 정지
                divProg.attr('data-value', '0');
                divProg.attr('data-message', endMsg);
                btnSubmit.prop('disabled', false);

                $.toast(endMsg);
            }
        });
    }

    render() {
        return (
            <div className="dxdeploy_target_one" data-name={this.props.targetdata.NAME}>
                <form onSubmit={() => {return false}} className="form_target_element" data-name={this.props.targetdata.NAME} data-type={this.props.targetdata.TYPE} encType="multipart/form-data" method="post">
                    <input type="hidden" name="NAME" value={this.props.targetdata.NAME}/>
                    <input type="hidden" name="TYPE" value={this.props.targetdata.TYPE}/>
                    <input type="hidden" name="JobType" value={"deploy"}/>
                    <input type="hidden" name="JobCode" value={"deploy_" + $.dx.randomInt(8) }/>
                    <div className="container-fluid">
                        <div className="row">
                            <div className="col-sm-12">
                                <h6 style={{'cursor' : 'pointer'}} onClick={() => { window.open(this.props.targetdata.URL); }}>{this.props.targetdata.NAME}</h6>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-sm-10">
                                <input type="file" name="war" accept=".war" className="full"/>
                            </div>
                            <div className="col-sm-2" style={{"verticalAlign" : "middle", "textAlign" : "right"}}>
                                <input type="button" className="btnSubmitTarget dxbtn" value="배포" onClick={() => { this.submitTarget(); }}/>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-sm-12">
                                <div className="deploy_progress" data-value={0}></div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        );
    }
}

class DXSVNTarget extends DXTarget {
    componentDidMount() {
        $.dx.progressbar.apply();
    }

    componentDidUpdate() {
        $.dx.progressbar.apply();
    }

    submitTarget() {
        const selfs = this;
        let formTag = null;
        $('.form_target_element').each(function() {
            if( $(this).attr('data-name') == selfs.props.targetdata.NAME )  {
                formTag = $(this);
            }
        });

        if(formTag == null) { alert('배포 대상 정보를 매핑하는 데 실패하였습니다. 화면을 새로고침하여 주십시오.'); return; }
        let formJson = $.dx.buildJsonFrom(formTag);

        const targetName = formJson.NAME;
        const divProg    = formTag.find(".deploy_progress");
        const btnSubmit  = formTag.find("input.btnSubmitTarget");

        // 버튼 비활성화하고, 프로그레스바 가동
        btnSubmit.prop('disabled', true);
        divProg.attr('data-value', '');
        divProg.attr('data-max', '100');
        divProg.attr('data-message', '작업 준비 중...');

        // 타이머 준비
        const varJobType = formTag.find("[name='JobType']").val();
        const varJobCode = formTag.find("[name='JobCode']").val();
        let completed  = false;
        let timer = setInterval(() => {
            fGetProgress(varJobType, varJobCode).then((res) => {
                if(timer == null) return;
                if(completed) return;

                divProg.attr('data-max', res.max);
                divProg.attr('data-value', res.value);
                if(res.message) {
                    divProg.attr('data-message', res.message);
                }
            });
        }, 2000);

        // 전송
        const formData = new FormData( formTag[0] );
        $.dx.ajax({
            url : $.ctx + '/jsp/program/deploysvn.jsp',
            data : formJson,
            dataType : 'JSON',
            method : 'POST',
            success : function(res) {
                if(! res.success) {
                    $.toast(res.message);
                } else {
                    $.toast(targetName + ' 배포 완료');
                }
            }, error : function(jqXHR, textStatus, errorThrown) {
                $.toast('배포에 실패하였습니다.');
                $.toast(errorThrown);
            }, complete : function() {
                completed = true;

                // form 태그 초기화 (일부 항목은 초기화 후 복원)
                formTag[0].reset();
                formTag.find("[name='NAME']").val(targetName);

                try {
                    // 타이머 끄기
                    if(timer != null) {
                        clearInterval(timer);
                        timer = null;
                    }
                } catch(e) {
                    $.dx.log(e);
                }

                // 버튼 복구하고 프로그레스바 정지
                divProg.attr('data-value', '0');
                divProg.attr('data-message', '작업 완료');
                btnSubmit.prop('disabled', false);
                $.dx.progressbar.refreshAll();
            }
        });
    }

    render() {
        return (
            <div className="dxdeploy_target_one" data-name={this.props.targetdata.NAME}>
                <form onSubmit={() => {return false}} className="form_target_element" data-name={this.props.targetdata.NAME} data-type={this.props.targetdata.TYPE}>
                    <input type="hidden" name="NAME" value={this.props.targetdata.NAME}/>
                    <input type="hidden" name="TYPE" value={this.props.targetdata.TYPE}/>
                    <input type="hidden" name="JobType" value={"deploy"}/>
                    <input type="hidden" name="JobCode" value={"deploy_" + $.dx.randomInt(8) }/>
                    <div className="container-fluid">
                        <div className="row">
                            <div className="col-sm-12">
                                <h6 style={{'cursor' : 'pointer'}} onClick={() => { window.open(this.props.targetdata.URL); }}>{this.props.targetdata.NAME}</h6>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-sm-5">
                                { this.props.targetdata.TYPE } : { this.props.targetdata.REPO }
                            </div>
                            <div className="col-sm-5">
                                { this.props.targetdata.BUILDER } - { this.props.targetdata.GOAL }
                            </div>
                            <div className="col-sm-2" style={{"verticalAlign" : "middle", "textAlign" : "right"}}>
                                <input type="button" className="btnSubmitTarget dxbtn" value="배포" onClick={() => { this.submitTarget(); }}/>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-sm-12">
                                <div className="deploy_progress" data-value={0}></div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        );
    }
}

class DXGITTarget extends DXSVNTarget {
    submitTarget() {
        const selfs = this;
        let formTag = null;
        $('.form_target_element').each(function() {
            if( $(this).attr('data-name') == selfs.props.targetdata.NAME )  {
                formTag = $(this);
            }
        });

        if(formTag == null) { alert('배포 대상 정보를 매핑하는 데 실패하였습니다. 화면을 새로고침하여 주십시오.'); return; }
        let formJson = $.dx.buildJsonFrom(formTag);

        const targetName = formJson.NAME;
        const divProg    = formTag.find(".deploy_progress");
        const btnSubmit  = formTag.find("input.btnSubmitTarget");

        // 버튼 비활성화하고, 프로그레스바 가동
        btnSubmit.prop('disabled', true);
        divProg.attr('data-value', '');
        divProg.attr('data-max', '100');
        divProg.attr('data-message', '작업 준비 중...');

        // 타이머 준비
        const varJobType = formTag.find("[name='JobType']").val();
        const varJobCode = formTag.find("[name='JobCode']").val();
        let completed  = false;
        let timer = setInterval(() => {
            fGetProgress(varJobType, varJobCode).then((res) => {
                if(timer == null) return;
                if(completed) return;

                divProg.attr('data-max', res.max);
                divProg.attr('data-value', res.value);
                if(res.message) {
                    divProg.attr('data-message', res.message);
                }
            });
        }, 2000);

        // 전송
        const formData = new FormData( formTag[0] );
        $.dx.ajax({
            url : $.ctx + '/jsp/program/deploygit.jsp',
            data : formJson,
            dataType : 'JSON',
            method : 'POST',
            success : function(res) {
                if(! res.success) {
                    $.toast(res.message);
                } else {
                    $.toast(targetName + ' 배포 완료');
                }
            }, error : function(jqXHR, textStatus, errorThrown) {
                $.toast('배포에 실패하였습니다.');
                $.toast(errorThrown);
            }, complete : function() {
                completed = true;

                // form 태그 초기화 (일부 항목은 초기화 후 복원)
                formTag[0].reset();
                formTag.find("[name='NAME']").val(targetName);

                try {
                    // 타이머 끄기
                    if(timer != null) {
                        clearInterval(timer);
                        timer = null;
                    }
                } catch(e) {
                    $.dx.log(e);
                }

                // 버튼 복구하고 프로그레스바 정지
                divProg.attr('data-value', '0');
                divProg.attr('data-message', '작업 완료');
                btnSubmit.prop('disabled', false);
                $.dx.progressbar.refreshAll();
            }
        });
    }
}

$(function() {
    // 테마는 다크 고정
    $.dx.theme = 'dark';
    
    // jQuery-UI Button 적용 (이미 적용된 버튼 제외)
    $(".deploy_root   input.dxbtn:not(.binded_button)" ).button().addClass('binded_button');
    $(".deploy_root   button.dxbtn:not(.binded_button)").button().addClass('binded_button');
    $(".deploy_dialog input.dxbtn:not(.binded_button)" ).button().addClass('binded_button');
    $(".deploy_dialog button.dxbtn:not(.binded_button)").button().addClass('binded_button');
    
    // jQuery-UI Menu 는 미사용
    // $('#deployx_nav').menu();
    
    // 자동 크기 조절 영역 이벤트 부여
    $.dx.applyAutofit();
    
    // 자동 스크롤 테이블
    $.dx.scrollTable();
    
    // 스토리지값 불러오기
    var localData = $.dx.storage.local.get();
    if(localData == null || typeof(localData) == 'undefined') {
        localData = $.dx.storage.cookie.get();
    }
    if(localData == null || typeof(localData) == 'undefined') {
        localData = { header : {} };
        if($.dx.theme) localData.theme = $.dx.theme;
        $.dx.storage.local.set(localData);
        // $.dx.storage.cookie.set(localData);
    }
    
    // ajax 시 헤더값
    $.each(localData.header, function(k, v) { $.dx.ajaxheader[k] = v; });
});