/** 
 * DX 프로젝트 공통 스크립트  
 *
 */

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

$.dx = {};
$.dx.ver   = '20250530';
$.dx.build = 1;
$.dx.theme = 'light';
$.dx.themeoption = {};
$.dx.themeoption.menuClickUnit = 'a';

$.dx.log = function(t) { try { console.log(t); } catch(e) {} };
$.log = $.dx.log;
$.dx.tries = function(callback) { try { if(typeof(callback) == 'function') callback(); } catch(e) { $.dx.log(e); $.toast(e); } };
$.dx.t = $.dx.tries;
$.dx.ajaxheader = { };
$.dx.ajaxevents = { success : [], error : [], complete : [] };
$.dx.editor = {};
$.dx.editor.instances = [];
$.dx.editor.config = { usageStatistics : false, plugins : [] };
$.dx.editor.configedit = { initialEditType : 'wysiwyg', initialValue : '', previewStyle : 'vertical', hideModeSwitch : true };
$.dx.trees = {};

/**  $.ajax 대용 */
$.dx.ajax = function(obj) {
    var originalValues = {};
    $.each(obj, function(k, v) { originalValues[k] = v; });
    
    obj._logYn = true;
    if(obj.mute) { obj._logYn = false; }
    
    var ajaxNo = randomInt();
    
    obj.beforeSend = function(jqXHR, settings) {
        var headerObj = $.dx.ajaxheader;
        
        if(typeof(headerObj) == 'string') headerObj = JSON.parse(headerObj);
        if(typeof(headerObj) != 'object') headerObj = {};
        
        headerObj.ver   = $.dx.ver;
        headerObj.build = $.dx.build;
        headerObj.theme = $.dx.theme;
        
        jqXHR.setRequestHeader('Djheader', JSON.stringify( headerObj ));
        
        try {
            var jwtToken = $.dx.cookie.get('dxjwt');
            if(! $.dx.isnullempty(jwtToken) ) jqXHR.setRequestHeader('Authorization', jwtToken);
        } catch(e) { $.log(e); }
        
        if(typeof(originalValues.beforeSend) == 'function') originalValues.beforeSend(jqXHR, settings);
    };
    
    obj.success = function(content, textStatus, jqXHR) {
        if(typeof(originalValues.success) == 'function') originalValues.success(content, textStatus, jqXHR);
        
        if($.dx.ajaxevents.success && $.dx.ajaxevents.success.length >= 1) {
            for(var idx=0; idx<$.dx.ajaxevents.success.length; idx++) { try { $.dx.ajaxevents.success[idx](content, textStatus, jqXHR); } catch(exIn) { $.log(exIn); } }
        }
    };
    
    obj.error = function(jqXHR, status, errorThrown) {
        $.dx.handleAjaxError(jqXHR, status, errorThrown);
        if(obj._logYn) $.log(ajaxNo + ' AJAX ' + obj.url + ' ERROR ' + errorThrown);
        if(typeof(originalValues.error) == 'function') originalValues.error(jqXHR, status, errorThrown);
        
        if($.dx.ajaxevents.error && $.dx.ajaxevents.error.length >= 1) {
            for(var idx=0; idx<$.dx.ajaxevents.error.length; idx++) { try { $.dx.ajaxevents.error[idx](jqXHR, status, errorThrown); } catch(exIn) { $.log(exIn); } }
        }
    };
    
    obj.complete = function(jqXHR, textStatus) {
        if(obj._logYn) $.log(ajaxNo + ' AJAX ' + obj.url + ' END ' + textStatus);
        if(typeof(originalValues.complete) == 'function') originalValues.complete(jqXHR, textStatus);
        
        if($.dx.ajaxevents.complete && $.dx.ajaxevents.complete.length >= 1) {
            for(var idx=0; idx<$.dx.ajaxevents.complete.length; idx++) { try { $.dx.ajaxevents.complete[idx](jqXHR, textStatus); } catch(exIn) { $.log(exIn); } }
        }
    };
    
    if(obj._logYn) $.log(ajaxNo + ' AJAX ' + obj.url + ' START');
    return $.ajax(obj);
};

/** 대상이 null / undefined / 빈 문자열인지 검사 */
function isnullempty(obj) {
    if (obj == undefined || obj == null || obj == "" || obj == "null")
        return true;
    return false;
};
$.dx.isnullempty = isnullempty;

/** 랜덤한 자연수로 만들어진 문자열 반환. 자리수를 지정할 수 있으며 1 ~ 14 자리수까지 가능 (기본값 8) */
function randomInt(digit) {
    if(typeof(digit) == 'undefined') digit = 8;
    if(typeof(digit) !=    'number') digit = parseInt(digit); 
    if(digit <   1) digit =  1;
    if(digit >= 14) digit = 14;
    
    var no;
    var str = '';
    
    while(str.length != digit) { // while 을 돌리는 이유는, 앞자리가 0이 나오면 다시 랜덤을 돌려야 하기 때문
        no  = Math.random() * 999999999999999;
        str = String(no).substring(0, digit);
    }
    
    return str;
}
$.dx.randomInt = randomInt;

/** JSON 객체를 Query String 형식으로 변환 (a=1&b=2&c=3 ...) */
function convertToQueryString(jsonObj) {
    if(jsonObj == null) return '';
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    
    var queryString = '';
    
    $.each(jsonObj, function(k, v) {
        if(queryString != '') queryString += '&';
        queryString += encodeURIComponent(k) + '=' + encodeURIComponent(v);
    });
    
    return queryString;
}
$.dx.convertToQueryString = convertToQueryString;

/***
 * 유효성 검사 도구
 *     사용 예:
 *         if(! $.checker.checkYYYYMM('2014-01')) { alert('년월을 잘못 입력하셨습니다.'); return; }  
 * 
 */
function ValidChecker() {
    /** 년월 입력 잘 했는 지 검증 (true / false 리턴) */
    this.checkYYYYMM = function(str, allowEmpty) {
        if(str == null || typeof(str) == 'undefined') { if(allowEmpty) return true; else return false; }
        str = String(str);
        if(str == '' || str == 'null') { if(allowEmpty) return true; else return false; }
        str = str.replace(/-/g, '');
        if(str.length < 6) return false;

        if(moment(str, 'YYYYMM', true).isValid()) return true;
        return false;
    };

    /** 년월일 입력 잘 했는 지 검증 (true / false 리턴) */
    this.checkYYYYMMDD = function(str, allowEmpty) {
        if(str == null || typeof(str) == 'undefined') { if(allowEmpty) return true; else return false; }
        str = String(str);
        if(str == '' || str == 'null') { if(allowEmpty) return true; else return false; }
        str = str.replace(/-/g, '');
        if(str.length < 8) return false;
        
        if(moment(str, 'YYYYMMDD', true).isValid()) return true;
        return false;
    };

    /** 정수값 입력을 잘 했는 지 검증 (true / false 리턴) */
    this.checkInteger = function(str, allowEmpty) {
        if(str == null || typeof(str) == 'undefined') { if(allowEmpty) return true; else return false; }
        str = String(str);
        if(str == '' || str == 'null') { if(allowEmpty) return true; else return false; }
        if(isNaN(str)) return false;
        if(String(parseInt(str)) != String(str)) return false;
        return true;
    }
    
    /** 소수 포함 숫자값 입력을 잘 했는 지 검증 (true / false 리턴) */
    this.checkFloat = function(str, allowEmpty) {
        if(str == null || typeof(str) == 'undefined') { if(allowEmpty) return true; else return false; }
        str = String(str);
        if(str == '' || str == 'null') { if(allowEmpty) return true; else return false; }
        if(isNaN(str)) return false;
        
        return /^-?\d+(\.\d{1,6})?$/.test(str);
    }

    /** 올바른 이메일 주소인지 확인 */
    this.checkEmail = function(str, allowEmpty) {
        if(str == null || typeof(str) == 'undefined') { if(allowEmpty) return true; else return false; }
        str = String(str);
        if(str == '' || str == 'null') { if(allowEmpty) return true; else return false; }
        if(str.indexOf('@') < 0) return false;
        if(str.indexOf('.') < 0) return false;
        return true;
    }
}

$.dx.checker = new ValidChecker();
$.checker = $.dx.checker;
$.c = $.checker;

/** 문자열 바꿔치기 */
function replaceString(str, target, replacement) {
    return str.split(target).join(replacement);
}
$.dx.replaceString = replaceString;

/** 문자열 제거 */
function removeCharacters(str, chars) {
    var res = String(str);
    
    if(typeof(chars) == 'string') {
        for(var idx=0; idx<chars.length; idx++) {
            res = $.dx.replaceString(res, chars.charAt(idx), '');
        }
    } else {
        for(var idx=0; idx<chars.length; idx++) {
            res = $.dx.replaceString(res, chars[idx], '');
        }
    }
    return res;
}
$.dx.removeCharacters = removeCharacters;

/** 문자열을 받아, 첫 줄만 반환 */
function onlySingleLine(str) {
    if($.dx.isnullempty(str)) return str;
    var splits = str.split('\n');
    return splits[0];
}
$.dx.onlySingleLine = onlySingleLine;

/** 문자열을 받아, UTF-8 바이너리 크기 반환 (bytes 단위) */
function getStrUTF8Length(str) {
    if(str == null || typeof(str) == 'undefined') return 0;
    var b, i, c, s;
    s = String(str);
    for(b=i=0;c=s.charCodeAt(i++);b+=c>>11?3:c>>7?2:1);
    return b;
}
$.dx.getStrUTF8Length = getStrUTF8Length;

/** 바이너리를 BASE64 변환 시 커지는 용량 예상 (byte 단위 정수로 입력해야 함) */
function predictBase64Size(originalBinarySize) {
    if(typeof(originalBinarySize) == 'string') originalBinarySize = Number(originalBinarySize);
    return Math.ceil(originalBinarySize / 3) * 4;
}
$.dx.predictBase64Size = predictBase64Size;

function trimdata(text) {
    if (text == null || text == undefined || text == "")
        return "";
    return text.replace(/^\s+|\s+$/g, '');
}

function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
}

/** 바이트 길이를 정수로 받아, 사람이 읽기 편한 용량 표기 텍스트 반환 */
function convertReadableFileSize(numbersOfBytes) {
    if($.dx.isnullempty(numbersOfBytes)) return numbersOfBytes;
    if(isNaN(numbersOfBytes)) return numbersOfBytes + '';
    
    if(typeof(numbersOfBytes) == 'string') numbersOfBytes = parseInt(numbersOfBytes);
    
    var unit = 'byte';
    var left = numbersOfBytes;
    
    if(left <= 1) return left + ' ' + unit;
    
    unit = 'bytes';
    if(left < 1024) return left + ' ' + unit;
    
    var rounded = 0;
    
    unit = 'KB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'MB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'GB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'TB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'FB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'EB';
    left = left / 1024.0;
    
    if(left < 1024) {
        rounded = Math.floor(left * 100.0) / 100.0;
        return rounded + ' ' + unit;
    }
    
    unit = 'ZB';
    left = left / 1024.0;
    
    rounded = Math.floor(left * 100.0) / 100.0;
    return rounded + ' ' + unit;
}
$.dx.convertReadableFileSize = convertReadableFileSize;

/** 파일 확장자를 받아, 미리보기 가능여부 판단 */
function isPreviewAvail(ext) {
    if($.dx.isnullempty(ext)) ext = '';
    ext = String(ext).toLowerCase().trim();
    
    if(ext ==  'pdf') return true;
    if(ext ==  'jpg') return true;
    if(ext ==  'png') return true;
    
    return false;
}
$.dx.isPreviewAvail = isPreviewAvail;

/** 이 메소드 직접 사용은 되도록 지양할 것. 대신 bigAlert 혹은 bigHTMLAlert 사용 */
function bigAlertRaw(msg, title, html, callbackClose, callbackBeforeOpen, cbuttons) {
    var dialogObj = $('#div_dialog_bigalert');
    if(dialogObj.length <= 0) {
        $('body').append('<div id="div_dialog_bigalert" style="display:none;"></div>');
        dialogObj = $('#div_dialog_bigalert');
    }
    dialogObj.attr('title', title);
    dialogObj.empty();
    dialogObj.append("<div class='div_dialog_bigalert_in'></div>");
    dialogObj.find(".div_dialog_bigalert_in").append("<div class='div_dialog_bigalert_msg'></div>");

    dialogObj.find(".div_dialog_bigalert_msg").css('overflow', 'auto');
    dialogObj.find(".div_dialog_bigalert_msg").css('white-space', 'pre-wrap');

    if(html) dialogObj.find(".div_dialog_bigalert_msg").html(msg);
    else     dialogObj.find(".div_dialog_bigalert_msg").text(msg);

    var abuttons = [
        {
            id : "div_dialog_bigalert_close",
            text : "닫기",
            click : function() {
                $(this).dialog("close");
            }
        }
    ];

    if(cbuttons) {
        if(typeof(cbuttons) == 'function') abuttons = cbuttons(abuttons);
        else abuttons = cbuttons;
    }
    
    return dialogObj.dialog({
        width: 600,
        height: 500,
        autoOpen: true,
        modal: true,
        buttons : abuttons,
        open : function() {
            if(typeof(callbackBeforeOpen) == 'function') callbackBeforeOpen(this);
        },
        close : function(event, ui) {
            try { dialogObj.dialog('destroy'); dialogObj.remove(); } catch(e) { $.log(e); }
            if(typeof(callbackClose) == 'function') callbackClose();
        }
    });
}
$.dx.bigAlertRaw = bigAlertRaw;

/**
 * 큰 alert 알림창을 띄운다. 내용을 텍스트로 처리한다.
 *     자바스크립트 흐름이 일시정지되지 않는다. 다시말해, 대화상자가 닫히지 않은 채로 다음 줄이 실행된다는 뜻이다.
 *     이를 위해 fAlert 에 함수를 넣어야 한다. 대화상자가 닫히면, fAfter 함수가 실행된다.
 * 
 *     fBefore 는 선택사항으로, 대화상자가 열리기 직전 호출되며, 대화상자 객체가 매개변수로 들어온다.
 *         이 함수 내에서 대화상자 크기를 변경할 수 있다.
 * 
  * 사용 예
 *     bigAlert('안내 메시지입니다.', function() {
 *         doSomething();
 *     });
 */
function bigAlert(msg, fAfter, fBefore) {
    return $.dx.bigAlertRaw(msg, '알림', false, fAfter, fBefore);
}

/**
 * 큰 alert 알림창을 띄운다. 내용을 HTML로 처리한다.
 *     자바스크립트 흐름이 일시정지되지 않는다. 다시말해, 대화상자가 닫히지 않은 채로 다음 줄이 실행된다는 뜻이다.
 *     이를 위해 fAlert 에 함수를 넣어야 한다. 대화상자가 닫히면, fAfter 함수가 실행된다.
 * 
 *     fBefore 는 선택사항으로, 대화상자가 열리기 직전 호출되며, 대화상자 객체가 매개변수로 들어온다.
 *         이 함수 내에서 대화상자 크기를 변경할 수 있다.
 */
function bigHTMLAlert(msg, fAfter, fBefore) {
    return $.dx.bigAlertRaw(msg, '알림', true, fAfter, fBefore);
}

/** 이 메소드 직접 사용은 되도록 지양할 것. 대신 bigConfigm 혹은 bigHTMLConfirm 사용. 콜백함수 내 매개변수로 응답이 true / false 로 넘어옴. */
function bigConfirmRaw(msg, title, html, callbackClose, callbackBeforeOpen, cbuttons) {
    var dialogObj = $('#div_dialog_bigconfirm');
    if(dialogObj.length <= 0) {
        $('body').append('<div id="div_dialog_bigconfirm" style="display:none;"></div>');
        dialogObj = $('#div_dialog_bigconfirm');
    }
    dialogObj.attr('title', title);
    dialogObj.empty();
    dialogObj.append("<div class='div_dialog_bigconfirm_in'></div>");
    dialogObj.find(".div_dialog_bigconfirm_in").append("<div class='div_dialog_bigconfirm_msg'></div>");

    dialogObj.find(".div_dialog_bigconfirm_msg").css('overflow', 'auto');
    dialogObj.find(".div_dialog_bigconfirm_msg").css('white-space', 'pre-wrap');

    if(html) dialogObj.find(".div_dialog_bigconfirm_msg").html(msg);
    else     dialogObj.find(".div_dialog_bigconfirm_msg").text(msg);

    var response = false;

    var abuttons = [
        {
            id : "div_dialog_bigconfirm_accept",
            text : "확인",
            click : function() {
                response = true;
                $(this).dialog("close");
            }
        },
        {
            id : "div_dialog_bigconfirm_close",
            text : "닫기",
            click : function() {
                response = false;
                $(this).dialog("close");
            }
        }
    ];
    
    if(cbuttons) {
        if(typeof(cbuttons) == 'function') abuttons = cbuttons(abuttons);
        else abuttons = cbuttons;
    }
    
    return dialogObj.dialog({
        width: 600,
        height: 500,
        autoOpen: true,
        modal: true,
        buttons : abuttons,
        open : function() {
            if(typeof(callbackBeforeOpen) == 'function') callbackBeforeOpen(this);
        },
        close : function(event, ui) {
            try { dialogObj.dialog('destroy'); dialogObj.remove(); } catch(e) { $.log(e); }
            if(typeof(callbackClose) == 'function') callbackClose(response);
        }
    });
}
$.dx.bigConfirmRaw = bigConfirmRaw;

/**
 * 큰 confirm 확인창을 띄운다. 내용을 텍스트로 처리한다.
 *     자바스크립트 흐름이 일시정지되지 않는다. 다시말해, 대화상자가 닫히지 않은 채로 다음 줄이 실행된다는 뜻이다.
 *     이를 위해 fAlert 에 함수를 넣어야 한다. 대화상자가 닫히면, fAfter 함수가 실행된다.
 *         사용자가 '확인' 버튼을 클릭했으면 첫 번째 매개변수가 true로, 그냥 대화상자를 닫았으면 첫 번째 매개변수가 false 로 들어간다.
 * 
 *     fBefore 는 선택사항으로, 대화상자가 열리기 직전 호출되며, 대화상자 객체가 매개변수로 들어온다.
 *         이 함수 내에서 대화상자 크기를 변경할 수 있다.
 * 
 * 사용 예
 *     bigConfirm('확인 또는 닫기를 눌러주세요', function(yn) {  
 *         if(! yn) return;
 *         doSomething();
 *     });
 */
function bigConfirm(msg, fAfter, fBefore) {
    return $.dx.bigConfirmRaw(msg, '알림', false, fAfter, fBefore);
}

/**
 * 큰 confirm 확인창을 띄운다. 내용을 HTML로 처리한다.
 *     자바스크립트 흐름이 일시정지되지 않는다. 다시말해, 대화상자가 닫히지 않은 채로 다음 줄이 실행된다는 뜻이다.
 *     이를 위해 fAlert 에 함수를 넣어야 한다. 대화상자가 닫히면, fAfter 함수가 실행된다.
 *         사용자가 '확인' 버튼을 클릭했으면 첫 번째 매개변수가 true로, 그냥 대화상자를 닫았으면 첫 번째 매개변수가 false 로 들어간다.
 * 
 *     fBefore 는 선택사항으로, 대화상자가 열리기 직전 호출되며, 대화상자 객체가 매개변수로 들어온다.
 *         이 함수 내에서 대화상자 크기를 변경할 수 있다.
 */
function bigHTMLConfirm(msg, fAfter, fBefore) {
    return $.dx.bigConfirmRaw(msg, '알림', true, fAfter, fBefore);
}

/**
  검색창 엔터키 검색 기능
     사용 방법
        1. 검색 입력창 태그 (input 태그여야 함) 에 entersearch 이름의 class을 부여한다.
           예) 
               BEFORE) <input class="basic_txt_box" type="text" name="CUST_NAME" id="CUST_NAME" value="" />
               AFTER)  <input class="basic_txt_box entersearch" type="text" name="CUST_NAME" id="CUST_NAME" value="" />
        2. 이 태그에, 엔터키 눌렀을 때 클릭 처리할 버튼 선택자를 data-entersearch 속성으로 넣는다.
           예)
               BEFORE) <input class="basic_txt_box entersearch" type="text" name="CUST_NAME" id="CUST_NAME" value="" />
               AFTER)  <input class="basic_txt_box entersearch" data-entersearch='#btn_search_contract' type="text" name="CUST_NAME" id="CUST_NAME" value="" />            
        이것으로 끝이다.
  이벤트 부여를 수동으로 하고 싶은 경우, 또는, 동적으로 입력 창이 추가된 곳에 이벤트 부여를 해야 하는 경우
  해당 위치에 다음과 같이 자바스크립트 코드를 넣는다.
       app.entersearch.apply();
  이벤트를 해제하고 싶은 경우, 해당 위치에 다음과 같이 자바스크립트 코드를 넣는다.
       app.entersearch.revoke();
*/
function applyEnterSearch() {
    $('input.entersearch').each(function() {
        if($(this).is('.binded_entersearch')) return; // 이미 이벤트 부여되었으면 스킵
        
        $(this).on('keypress', function(e) {
            if(e.keyCode != 13) return;
            
            var targetSelector = $(this).attr('data-entersearch'); // 엔터키 눌렀을 때 클릭 처리할 버튼 선택자 꺼내기
            if(typeof(targetSelector) == 'undefined' || targetSelector == null) return;
            
            $(targetSelector).trigger('click');
        });
        
        $(this).addClass('binded_entersearch'); // 이벤트 중복 부여되지 않도록 표시
    });
};
$.dx.applyEnterSearch = applyEnterSearch;

/** 검색창 엔터키 검색 기능 사용 중단 (관련 이벤트 전부 해제) - 주의 ! 해당 입력창의 keypress 이벤트가 전부 날아간다. */
function revokeEnterSearch() {
    $('input.binded_entersearch').each(function() {
        $(this).off('keypress');
        $(this).removeClass('binded_entersearch');
    });
};
$.dx.revokeEnterSearch = revokeEnterSearch;

/** 검색창 엔터키 검색 기능이 적용된 입력창에 포커스  */
function focusEnterSearch() {
    var target = $('input.entersearch');
    if($('input.entersearch.focusfirst').length >= 1 ) {
        target = $('input.entersearch.focusfirst');
    }
    
    target.first().focus();
    
};
$.dx.focusEnterSearch = focusEnterSearch;

/**   
 * JSON 데이터를 xlsx (OOXML 표준, MS Excel 등의 프로그램에서 사용)
 * 매개변수로 JSON 형식 객체를 넣어야 함.
 * 생성 완료되면, 사용자의 브라우저에서는 파일 다운로드 창이 나타남.
 *   
 * @param obj : JSON 객체 (속성 - fileName : 파일명, sheets : 시트 데이터 (이 또한 JSON객체로 안에 name, data 속성 필요, data 는 배열))
 *              예) $.dx.buildXlsx({fileName : '회사명', sheets : [ { name : '메인시트', data : [ { "회사명" : "대정아이씨티", "연락처" : "01011111111" } ] } ]});
 * 
 */
function buildXlsx(obj) {
    var fileName      = obj.fileName
    var sheets        = obj.sheets;
    
    var workbook = XLSX.utils.book_new();
    
    for(var sdx=0; sdx<sheets.length; sdx++) {
        var sheetOne = sheets[sdx];
        var sheets = XLSX.utils.json_to_sheet(sheetOne.data);
        XLSX.utils.book_append_sheet(workbook, sheets, sheetOne.name);
    }
    XLSX.writeFile(workbook, fileName + ".xlsx");
}
$.dx.buildXlsx = buildXlsx;

/**
 * 버튼 다중클릭 이벤트 부여
 * 
 * @param btnSelector  : 버튼 객체 혹은 셀렉터 (예: #btn_search)
 * @param eventHandler : 이벤트 처리기 함수 (버튼이 다중클릭 되었을 때 호출될 함수, 또는 함수가 들어있는 배열)
 * @param optTimeout   : 제한 시간. 이 시간 내에 지정 횟수 이상 클릭이 되어야 이벤트가 발생, 기본값은 2000 (밀리초)
 * @param optCounts    : 지정 횟수. 이 횟수 이상을 제한 시간 안에 클릭해야 이벤트가 발생, 기본값은 3 (회)
 */
function detectBtnMultiPress(btnSelector, eventHandler, optTimeout, optCounts) {
    var buttonObj  = $(btnSelector);
    
    var timeouts = 2000;
    var counts   = 3;
    
    if(optTimeout != null && typeof(optTimeout) != 'undefined' && (! isNaN(optTimeout))) timeouts = parseInt(optTimeout);
    if(optCounts  != null && typeof(optCounts ) != 'undefined' && (! isNaN(optCounts ))) counts   = parseInt(optCounts);
    
    // 버튼 클릭 시 그 클릭 시간이 이 배열에 쌓일 예정
    var pressTries = [];
    
    // 함수들을 미리 준비한다.
    
    // 오래된 시간 데이터를 삭제하는 함수
    var cleanFunc = function() {
        var idx = 0;
        var now = new Date().getTime();
        while(idx < pressTries.length) {
            var target = pressTries[idx];
            
            if(now - target >= timeouts) { // 오래된 시간들을 배열에서 삭제
                pressTries.splice(idx, 1);
                continue;
            }
            
            idx++;
        }
    };
    
    // 클릭 시간이 지정횟수를 초과했으면 이벤트를 집행시키는 함수
    var executorFunc = function() {
        if(pressTries.length >= counts) {
            pressTries = [];
            if(typeof(eventHandler) == 'function') eventHandler();
            if($.isArray(eventHandler)) $.each(eventHandler, function(fnc) { if(typeof(fnc) == 'function') fnc(); });
        }
    };
    
    // 클릭 이벤트 작성 시작
    buttonObj.on('click', function() {
        pressTries.push(new Date().getTime());
        cleanFunc();
        executorFunc();
    });
}

/** 날짜 데이터 문자열을 다른 포맷으로 변경 */
function convertDateFormat(dateFormatString, originalFormat, newFormat) {
    return moment(dateFormatString, originalFormat).format(newFormat);
}
$.dx.convertDateFormat = convertDateFormat;

/** 
 * JSON 객체를 통해 HTTP GET 요청 매개변수부를 만듦 
 *
 * 예) { "a" : 1, "b" : 2 } --> a=1&b=2
 */
function jsonToQueryStr(jsonObj) {
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    var res = '';
    $.each(jsonObj, function(k, v) {
        if(res != '') res += '&';
        res += String(k) + '=' + encodeURIComponent(String(v));
    });
    return res;
}
$.dx.jsonToQueryStr = jsonToQueryStr;

/** 
 * 팝업을 띄운다. 이 때, 매개변수를 POST 방식으로 전송한다. (paramJson 의 키값에 따옴표 안들어가도록 유의 !) 
 *    url : 팝업 주소
 *    popupArgs : window.open 함수에 쓰이는 마지막 매개변수, 팝업창의 속성을 지정한다.
 *    paramJson : 보낼 매개변수를 JSON 객체로 넣는다. (필수)
 */
function openPostPop(url, popupArgs, paramJson) {
    if(typeof(paramJson) == 'undefined') paramJson = popupArgs;
    if(typeof(paramJson) == 'string'   ) paramJson = JSON.parse(paramJson);

    // 고유 SEQ 만들기
    var seq = 0;
    $('.div_tempform').each(function() {
        var v = parseInt($(this).attr('data-seq'));
        if(v > seq) seq = v;
    });
    seq++;

    // 임시 form 을 만든다.
    $('body').append("<div class='div_tempform' data-seq='" + seq + "'><form method='POST'></form></div>");

    // 임시 form 뒤의 div태그 꺼내기
    var divParent = $('.div_tempform[data-seq=' + seq + ']');
    var formObj   = divParent.find('form');
    var popupName = 'postpopup_' + seq;

    formObj.attr('action', url);
    
    // 매개변수 form 으로 변환
    $.each(paramJson, function(k, v) {
        k = k.replace(/'/g, '');
        formObj.append("<input type='hidden' name='" + k + "'/>");
        formObj.find("input[name='" + k + "']").val(v);
    });
    
    // 팝업 띄우고 대상 세팅
    var win = window.open('', popupName, popupArgs);
    formObj.attr('target', popupName);
    
    // 매개변수 전송
    formObj.submit();
    
    // 2초 뒤 임시요소 지우기
    setTimeout(function() {
        divParent.remove();
    }, 2000);
    return win;
}
$.dx.openPostPop = openPostPop;

/**
 * iframe 에 URL을 띄우면서 POST 로 매개변수를 전송한다. (iframe 에 고유한 name, id 부여 필수)
 */
function sendPostToIframe(url, iframeSelector, paramJson, callback) {
    if(typeof(paramJson) == 'string') paramJson = JSON.parse(paramJson);
    var iframeObj = $(iframeSelector);
    
    // iframe 이름, id 백업
    var originalName = iframeObj.attr('name');
    var originalID   = iframeObj.attr('id');
    if(typeof(originalName) == 'undefined' || originalName == '') originalName = null;
    if(typeof(originalID  ) == 'undefined' || originalID   == '') originalID   = null;
    
    if(originalName == null && originalID == null) throw 'iframe 에 name 이나 id가 부여되지 않았습니다.';

    // 고유 SEQ 만들기
    var seq = 0;
    $('.div_tempform').each(function() {
        var v = parseInt($(this).attr('data-seq'));
        if(v > seq) seq = v;
    });
    seq++;

    // 임시 form 을 만든다.
    $('body').append("<div class='div_tempform' data-seq='" + seq + "'><form method='POST'></form></div>");

    // 임시 form 뒤의 div태그 꺼내기
    var divParent = $('.div_tempform[data-seq=' + seq + ']');
    var formObj   = divParent.find('form');
    var iframeName = originalName;
    // var iframeName = 'postiframe' + seq;

    // // iframe 이름, id 부여
    // iframeObj.attr('name', iframeName);
    // iframeObj.attr('id'  , iframeName);
    // iframeObj = $('#' + iframeName);

    // URL과 이름 부여
    formObj.attr('action', url);
    formObj.attr('target', iframeName);

    // 매개변수 form 으로 변환
    $.each(paramJson, function(k, v) {
        k = k.replace(/'/g, '');
        formObj.append("<input type='hidden' name='" + k + "'/>");
        formObj.find("input[name='" + k + "']").val(v);
    });
    
    // 매개변수 전송
    formObj[0].submit();
    
    // 2초 뒤 임시요소 지우고 이름 복원
    setTimeout(function() {
        divParent.remove();
        //if(originalName) iframeObj.attr('name', originalName);
        //if(originalID  ) iframeObj.attr('id'  , originalID);
        if(typeof(callback) == 'function') callback();
    }, 2000);
    return iframeObj;
}
$.dx.sendPostToIframe = sendPostToIframe

/**
 * 해당 구역 내의 form 요소 (input, textarea, select) 값 JSON에서 꺼내서 세팅
 * 
 */
function fillValuesFrom(areaSelector, jsonObj) {
    if(jsonObj == null || typeof(jsonObj) == 'undefined') jsonObj = {};
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    
    var rootArea = $(areaSelector);
    var funcProc = function(component) {
        var comp  = $(component);
        var value = null;
        var name  = null;
        
        if(comp.is('.output-field')) {
            name = comp.attr('data-column');
        } else {
            name  = comp.attr('name');
        }

        if(name == null) return;
        
        $.each(jsonObj, function(k, v) {
            if(name == String(k).toUpperCase()) {
                value = v;
            } 
        });
        
        if(typeof(value) == 'undefined') return;
        if(typeof(value) == 'function' ) value = value(comp, name);

        value = processValueForField(comp, value);
        
        if(comp.is('input')) {
            var type = comp.attr('type');
            if(type == 'text' || type == 'number' || type == 'date' || type == 'password' || type == 'hidden' || type == 'tel' || type == 'email' || type == 'search' || type == 'time' || type == 'url' || type == 'range' || type == 'month' || type == 'color') {
                if(value == null) value = '';
                comp.val(value);
            }
        }
        
        if(comp.is('textarea')) {
            if(value == null) value = '';
            comp.val(value);
        }
        
        if(comp.is('select')) {
            if(value == null) value = '';
            if(comp.find("option[value='" + value + "']").length >= 1) comp.val(value);
            else comp.val(comp.find("option:first").attr('value'));
        }
        
        if(comp.is('.output-field')) {
            if(value == null) value = '';
            comp.text(value);
        }
    }
    
    rootArea.find("input"        ).each(function() { funcProc(this); });
    rootArea.find("textarea"     ).each(function() { funcProc(this); });
    rootArea.find("select"       ).each(function() { funcProc(this); });
    rootArea.find(".output-field").each(function() { funcProc(this); });
}
$.dx.fillValuesFrom = fillValuesFrom;

/** fillValuesFrom 처리 중, 포맷팅이 지정된 컴포넌트인 경우 값을 포맷 처리하는 함수 (직접호출 X) */
function processValueForField(comp, value) {
    if(value == null) return value;
    var res = value;
    try {
        comp = $(comp);
        if(comp.is('.format-date')) {
            var dateFormatter = comp.attr('data-format-pattern');
            if(typeof(dateFormatter) == 'undefined') dateFormatter = 'YYYY-MM-DD';
    
            res = res.replace(/-/g, '');
            var dates = new Date(parseInt(res.substring(0, 4)), parseInt(res.substring(4, 6)) - 1, parseInt(res.substring(6, 8)));
            res = moment(dates).format(dateFormatter);

            if(String(res) == 'Invalid date') return value;
        }

        return res;
    } catch(e) {
        $.log(e);
    }

    return value;
}
$.dx.processValueForField = processValueForField;

/** 해당 영역 내 form 태그들 모두 값 비우기 */
function makeAllEmpty(areaSelector) {
    var rootArea = $(areaSelector);
    var funcProc = function(component) {
        var comp  = $(component);
        var value = null;
        var name  = null;
        
        if(comp.is('.output-field')) {
            name = comp.attr('data-column');
        } else {
            name  = comp.attr('name');
        }

        if(name == null) return;
        value = '';
        
        if(comp.is('input')) {
            var type = comp.attr('type');
            if(type == 'text' || type == 'number' || type == 'date' || type == 'password' || type == 'hidden') {
                if(value == null) value = '';
                comp.val(value);
            }
        }
        
        if(comp.is('textarea')) {
            if(value == null) value = '';
            comp.val(value);
        }
        
        if(comp.is('select')) {
            if(value == null) value = '';
            if(comp.find("option[value='" + value + "']").length >= 1) comp.val(value);
            else comp.val(comp.find("option:first").attr('value'));
        }
        
        if(comp.is('.output-field')) {
            if(value == null) value = '';
            comp.text(value);
        }
    }
    
    rootArea.find("input"        ).each(function() { funcProc(this); });
    rootArea.find("textarea"     ).each(function() { funcProc(this); });
    rootArea.find("select"       ).each(function() { funcProc(this); });
    rootArea.find(".output-field").each(function() { funcProc(this); });
}
$.dx.makeAllEmpty = makeAllEmpty;

/** 해당 구역 내의 data-column 요소에, 값을 JSON에서 꺼내서 세팅 */
function fillValuesOnlyFields(areaSelector, jsonObj) {
    if(jsonObj == null || typeof(jsonObj) == 'undefined') jsonObj = {};
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    
    var rootArea = $(areaSelector);
    var funcProc = function(component) {
        var comp  = $(component);
        if(! comp.is('.output-field')) return;
        
        var value = null;
        var name = comp.attr('data-column');
        
        $.each(jsonObj, function(k, v) {
            if(name == String(k).toUpperCase()) {
                value = v;
            } 
        });

        if(typeof(value) == 'undefined') return;
        if(typeof(value) == 'function' ) value = value(comp, name);

        value = processValueForField(comp, value);
        
        if(value == null) value = '';
        comp.text(value);
    }
    
    rootArea.find(".output-field").each(function() { funcProc(this); });
}
$.dx.fillValuesOnlyFields = fillValuesOnlyFields;

/** 
 * <pre>
 * 해당 구역 내의 input, textarea, select 태그들로부터 값을 추출해 JSON을 생성해 반환한다.
 * name 값이 그대로 키가 된다. disabled 된 요소들의 값도 포함된다. 
 * 클래스 ignore_build_json 을 가진 요소는 제외된다.
 *
 * 
 * </pre>
 * @param  areaSelector : 구역 선택자 (굳이 form 태그가 아니어도 된다.)
 * @param  freprocess   : (선택 사항) 값을 JSON 에 넣기 전 모종의 조작을 가할 콜백함수를 넣을 수 있다. 매개변수 name 과 value 가 들어오며, 값을 반환하는 함수여야 한다.
*/
function buildJsonFrom(areaSelector, freprocess) {
    var area   = $(areaSelector);
    var result = {};
    
    if(typeof(freprocess) != 'function') freprocess = function(name, value) { return value; }
    
    area.find("input").each(function() {
        var comp = $(this);
        var type = comp.attr('type');
        var name = comp.attr('name');
        
        if(comp.is('.ignore_build_json')) return;
        
        if(type == 'button' || type == 'submit' || type == 'reset') return;
        if(type == 'checkbox' || type == 'radio') {
            if(! comp.is(':checked')) return;
            
            var oldVal = result[name];
            if(typeof(oldVal) == 'undefined') {
                result[name] = comp.val();
            } else if($.isArray(oldVal)) {
                result[name].push(comp.val());
            } else {
                result[name] = [];
                result[name].push(oldVal);
                result[name].push(comp.val());
            }                              
        } else {
            result[name] = comp.val();
            
            if(type == 'date' && comp.is('.only_date_numbers')) {
                result[name] = String(result[name]).replace(/-/g, "");
            }
        }
    });
    
    area.find('textarea').each(function() {
        var comp = $(this);
        var name = comp.attr('name');
        if(comp.is('.ignore_build_json')) return;
        result[name] = comp.val();
    });
    
    area.find('select').each(function() {
        var comp = $(this);
        var name = comp.attr('name');
        if(comp.is('.ignore_build_json')) return;
        result[name] = comp.val(); // multiple 속성이 있는 경우, val() 결과가 배열로 나오므로, 어짜피 마찬가지
    });
    
    var temp = result;
    result = {};
    
    $.each(temp, function(k, v) {
        result[k] = freprocess(k, v);
    });
    
    return result;
}
$.dx.buildJsonFrom = buildJsonFrom;
/** 
 * JSON의 각 키들을 언더바 기준으로 나눠 앞 단어만 소문자로 만든다. 값은 변경하지 않는다.
 * 
 * 예) lowerFirstJsonKey({ "CONS_START_DATE" : "20241104" }) --> { "cons_START_DATE" : "20241104" } 
 * 
 */
function lowerFirstJsonKey(json) {
    var newJson = {};
    
    $.each(json, function(k, v) {
        var splits = k.split('_');
        var newKey = '';
        
        for(var idx=0; idx<splits.length; idx++) {
            if(idx == 0) {
                newKey += splits[idx].toLowerCase();
            } else {
                newKey += '_' + splits[idx];
            }
        }
        newJson[newKey] = v;
    });
    return newJson;
}
$.dx.lowerFirstJsonKey = lowerFirstJsonKey;
/**   
 * <pre>
 * 템플릿 HTML 텍스트 군데군데 위치한 구멍에, JSON 에서 데이터를 꺼내 채워 넣는다. (매핑) 구멍은 [] 로, 그 안에 필드명을 넣어 표시한다. ([] 안에 띄어쓰기가 있어서는 안 된다.)
 * 
 * 예) templateHtml : <td>[userName]</td>
 *     json : { userName : '홍길동' }
 *     결과 : <td>홍길동</td> 
 * 
 * </pre>
 */
function fillRowValue(templateHtml, json, removeHtmlChars) {
    var html = String(templateHtml);
    
    if(json == null) json = {};
    if(typeof(json) == 'undefined') json = {};
    if(typeof(json) == 'string'   ) json = JSON.parse(json);
    
    var useRemoveHtmlChars = false;
    if(removeHtmlChars) useRemoveHtmlChars = true;
    
    $.each(json, function(k, v) {
        if(v == null || typeof(v) == 'undefined') v = '';
        if(typeof(v) != 'string') v = String(v);
        
        if(useRemoveHtmlChars) {
            v = $.dx.replaceString(v, '<', '&lt;');
            v = $.dx.replaceString(v, '>', '&gt;');
        }
        
        html = replaceString(html, '[' + k + ']', v);
    });
    
    return html;
};
$.dx.fillRowValue = fillRowValue;

/**
 * <pre>
 * json 안에 담긴 데이터를 form 요소 내 input, textarea, select 에 채워 넣는다.
 * </pre>
 */
function fillFormValue(formSelector, json) {
    if(typeof(json) == 'string') json = JSON.parse(json);
    if(json == null) json = {};

    var upperCasedJson = {};
    $.each(json, function(k, v) {
        upperCasedJson[k.toUpperCase()] = v;
    });
    json = null;

    var formObj = $(formSelector);
    formObj.find('input, textarea, select').each(function() {
        var comp = $(this);
        var name = comp.attr('name');
        var type = comp.attr('type');
        var value = upperCasedJson[name];
        
        if(typeof(value) == 'undefined') return;
        if(value == null) value = '';
        
        if(comp.is('input')) {
            if(type == 'text' || type == 'number' || type == 'date' || type == 'password' || type == 'hidden') {
                comp.val(value);
            }
            if(type == 'checkbox' || type == 'radio') {
                if($.isArray(value)) {
                    if(value.indexOf(comp.val()) >= 0) comp.prop('checked', true);
                    else comp.prop('checked', false);
                } else if(comp.val() == value) {
                    comp.prop('checked', true);
                } else comp.prop('checked', false);
            }
        }
        
        if(comp.is('textarea')) {
            comp.val(value);
        }
        
        if(comp.is('select')) {
            comp.val(value);
        }
    });
};
$.dx.fillFormValue = fillFormValue;

/** 
 * tbody 내의 td 의 클래스로 데이터 타입을 판별해 스타일 및 반올림 적용
 * 
 *    클래스 td_type_int    - 정수로 취급, 오른쪽 정렬, 반올림
 *    클래스 td_type_float  - 소수로 취급, 오른쪽 정렬
 *    클래스 td_type_date   - 날짜로 취급, 중앙 정렬
 *    클래스 td_type_string - 텍스트로 취급, 왼쪽 정렬
 *    클래스 td_type_code   - 텍스트로 취급, 중앙 정렬
 * 
 */
function applyTdType(tbodySelector) {
    var tbody = $(tbodySelector);
    tbody.find(".td_type_int").each(function() {
        var tdOne = $(this);
        var value = String(tdOne.text()).trim();
        
        if(value == '') return;
        if(value == 'null') { tdOne.text(String('')); return; }
        
        if(value.indexOf('.') >= 0) {
            value = parseFloat(value);
            value = Math.round(value);
            value = parseInt(value);
            value = Number(value).toLocaleString();
        } else {
            value = parseInt(value);
            value = Number(value).toLocaleString();
        }
        tdOne.text(String(value));
    });
    tbody.find(".td_type_float").each(function() {
        var tdOne = $(this);
        var value = String(tdOne.text()).trim();
        var nVal;
        
        if(value == '') return;
        if(value == 'null') { tdOne.text(String('')); return; }
        
        if(value.indexOf('.') >= 0) {
            nVal  = parseFloat(value);
            value = Math.round(nVal * 100.0) / 100.0; // 소수 2자리까지 출력
            value = Number(value).toLocaleString();
        } else {
            nVal  = parseInt(value);
            value = Number(nVal).toLocaleString();
        }
        if(nVal != 0 && value.indexOf('.') < 0) value = value + '.00';
        tdOne.text(String(value));
    });
    tbody.find(".td_type_number").each(function() {
        var tdOne = $(this);
        var value = String(tdOne.text()).trim();
        
        if(value == '') return;
        if(value == 'null') { tdOne.text(String('')); return; }
        
        var nVal = Math.floor(parseFloat(value));
        
        var valData = parseFloat(value) - nVal;
        
        if(valData == 0) {
            value = Number(value).toLocaleString();
        } else {
            nVal  = parseFloat(value);
            value = Math.round(nVal * 100.0) / 100.0; // 소수 2자리까지 출력
            value = Number(value).toLocaleString();
        }
        tdOne.text(String(value));
    });
    tbody.find(".td_type_date").each(function() {
        var tdOne = $(this);
        var value = String(tdOne.text()).trim().replace(/-/g, "");
        if(value == 'null' || value == '-') value = '';
        
        if(value == '') return;
        if(value == 'null') { tdOne.text(String('')); return; }
        
        var nVal = null;
        var formats = '';
        if(value.length == 6) {
            nVal = moment(value, 'YYYYMM');
            formats = 'YYYY-MM';
        } else if (value.length == 7) {
            nVal = moment(value.substring(0, 7), 'YYYYMM');
            formats = 'YYYY-MM'; 
        } else if (value.length == 8) {
            nVal = moment(value, 'YYYYMMDD');
            formats = 'YYYY-MM-DD';
        } else if (value.length > 8 && value.length < 12) {
            nVal = moment(value.substring(0, 8), 'YYYYMMDD');
            formats = 'YYYY-MM-DD';
        } else if (value.length == 12) {
            nVal = moment(value, 'YYYYMMDDHHmm');
            formats = 'YYYY-MM-DD HH:mm';
        } else if (value.length > 12 && value.length < 14) {
            nVal = moment(value.substring(0, 12), 'YYYYMMDD');
            formats = 'YYYY-MM-DD HH:mm';
        } else if (value.length == 14) {
            nVal = moment(value, 'YYYYMMDDHHmmss');
            formats = 'YYYY-MM-DD HH:mm:ss';
        } else {
            nVal = moment(value.substring(0, 14), 'YYYYMMDDHHmmss');
            formats = 'YYYY-MM-DD HH:mm:ss';
        }
        
        tdOne.text(nVal.format(formats));
    });
}
/** tbody 에서 같은 데이터가 들어간 셀 병합 (jqGrid 비호환) */
function mergeTbody(tbodySelector) {
    var tbody = $(tbodySelector);
    
    var trs = [];
    tbody.find('tr').each(function() { trs.push($(this)); });
    
    // 수평 단위 먼저 계산
    for(var trx=0; trx<trs.length; trx++) {
        var tr = trs[trx];
        tr.children = [];
        
        tr.find('th, td').each(function() { tr.children.push($(this)); });
        
        var sameCount   = 1;
        var beforeValue = '';
        var beforeTd    = null;
        
        for(var tdx=0; tdx<tr.children.length; tdx++) {
            var tdOne = $(tr.children[tdx]);
            var value = tdOne.text();
            
            if(beforeTd != null) {
                // 데이터 영역은 셀병합을 해서는 안 됨
                var dataCellYn = tdOne.is('.td_type_int') || tdOne.is('.td_type_float') || tdOne.is('.td_type_string') || tdOne.is('.td_type_code') || tdOne.is('.td_type_date') || tdOne.is('.td_type_number');
                if(dataCellYn && tdOne.is('.td_canmerge')) dataCellYn = false; // 셀병합 허용 예외
                
                if((!dataCellYn) && (beforeValue == value)) { // 이전 셀과 값이 같으면 - 셀병합 갯수 늘리고 표시
                    tdOne.addClass('merge_remove_target');
                    sameCount++;
                    continue;
                } else {
                    if(sameCount >= 2) {
                        beforeTd.attr('data-colspan', String(sameCount));
                        beforeTd.addClass('merge_colspan_survive_target');
                    }
                    sameCount = 1;
                }
            }
            
            beforeTd    = tdOne;
            beforeValue = beforeTd.text();
        }
        
        // 아직 셀병합 계산 진행중인 건이 남아있는 경우 - 계산 마무리
        if(beforeTd != null && sameCount >= 2) {
            beforeTd.attr('data-colspan', String(sameCount));
            beforeTd.addClass('merge_colspan_survive_target');
        }
    }
    
    // 수직단위 계산
    if(trs.length >= 1) {
        
        var sameCount   = 1;
        var beforeValue = '';
        var beforeTd    = null;
        
        // 행 하나를 고른 뒤, 그 자식 갯수로 반복 (다시말해 열 갯수만큼 반복)
        for(var cdx=0; cdx<trs[0].children.length; cdx++) {
            for(var trx=0; trx<trs.length; trx++) {
                var trOne = trs[trx];
                var tdOne = trOne.children[cdx];
                var value = tdOne.text();
                
                if(beforeTd != null) {
                    // 데이터 영역은 셀병합을 해서는 안 됨
                    var dataCellYn = tdOne.is('.td_type_int') || tdOne.is('.td_type_float') || tdOne.is('.td_type_string') || tdOne.is('.td_type_code') || tdOne.is('.td_type_date') || tdOne.is('.td_type_number');
                    if(dataCellYn && tdOne.is('.td_canmerge')) dataCellYn = false; // 셀병합 허용 예외
                
                    if((!dataCellYn) && (beforeValue == value)) { // 이전 셀과 값이 같으면 - 셀병합 갯수 늘리고 표시
                        tdOne.addClass('merge_remove_target');
                        sameCount++;
                        continue;
                    } else {
                        if(sameCount >= 2) {
                            beforeTd.attr('data-rowspan', String(sameCount));
                            beforeTd.addClass('merge_rowspan_survive_target');
                        }
                        sameCount = 1;
                    }
                }
                
                beforeTd    = tdOne;
                beforeValue = beforeTd.text();
            }
        }
        
        // 아직 셀병합 계산 진행중인 건이 남아있는 경우 - 계산 마무리
        if(beforeTd != null && sameCount >= 2) {
            beforeTd.attr('data-rowspan', String(sameCount));
            beforeTd.addClass('merge_rowspan_survive_target');
        }
    }
    
    // 집행
    tbody.find(".merge_remove_target").remove();
    tbody.find(".merge_colspan_survive_target").each(function() {
        $(this).attr('colspan', $(this).attr('data-colspan'));
    });
    tbody.find(".merge_rowspan_survive_target").each(function() {
        $(this).attr('rowspan', $(this).attr('data-rowspan'));
    });
}

/** 
 * 테이블 (jqGrid 안쓴 테이블만 해당) 을 행 선택 가능하게 만듦
 * 
 *     사용방법
 *     var tableInst = new TableSelectable('#table_id');
 * 
 */
function TableSelectable(selector) {
    this.instances = $(selector);

    this.on  = function() {
        this.off();
        var tbody = this.instances.find('tbody');
        tbody.find('tr').each(function() {
            var tr = $(this);
            tr.on('click', function() {
                if(tr.is('.not_selectable')) return;
                tbody.find('tr').removeClass('selected');
                tr.addClass('selected');
            });
            tr.addClass('binded_rowselect');
        });
        
        this.instances.addClass('binded_rowselect');
    };

    this.off = function() {
        if(this.instances.is('.binded_rowselect')) {
            this.instances.find('tr.binded_rowselect').off('click');
        }
    };

    this.getSelectedRow = function() {
        var tr = this.getSelectedTr();
        if(tr == null) return;
        var rowOne = {};

        $(tr).find('td[data-col]').each(function() {
            var attrs = $(this).attr('data-col');
            var value = $(this).text();
            rowOne[attrs] = value;
        });

        return rowOne;
    };

    this.getSelectedTr = function() {
        var tbody = this.instances.find('tbody');
        var trSelected = tbody.find('tr.selected');
        if(trSelected.length == 0) return null;
        return trSelected;
    };

    this.on();
};

/** 테이블 (jqGrid 안쓴 테이블만 해당) 을 행 선택 가능하게 만듦 */
function makeTableRowSelectabble(selector) {
    var table = $(selector);
    var tbody = table.find('tbody');

    if(table.is('.binded_rowselect')) {
        table.find('tr.binded_rowselect').off('click');
    }

    tbody.find('tr').each(function() {
        var tr = $(this);
        tr.on('click', function() {
            tbody.find('tr').removeClass('selected');
            tr.addClass('selected');
        });
        tr.addClass('binded_rowselect');
    });
    
    table.addClass('binded_rowselect');
}

/** jQuery AJAX 오류 시 처리할 내용 공통 */
function handleAjaxError(jqXHR, status, errorThrown) {
    var msg = [];
    msg.push('서버와의 통신에 실패하였습니다.');
    if(status) {
        if(typeof(status) == 'object') { try {  status = JSON.stringify(status);  } catch(e) { status = String(status); } }
        if(! $.dx.isnullempty(status)) msg.push('Status : ' + status);
    }
    
    if(! $.dx.isnullempty(errorThrown)) msg.push('Error : ' + errorThrown);
    
    if(typeof($.toast) != 'undefined') {
        for(var idx=0; idx<msg.length; idx++) { $.toast(msg[idx]); }
    }
    for(var idx=0; idx<msg.length; idx++) { $.log(msg[idx]); }
    $.log(jqXHR);
}
$.dx.handleAjaxError = handleAjaxError;

/**
 * 문자열을 HEX 문자열로 인코딩 or 반대로 디코딩 (리포트 출력 시 인코딩해 전달해 한글깨짐 방지 목적)
 * 
 * 사용 예)  
 * var hexEncoder = new HexEncoder();
 * var encoded    = hexEncoder.encode('안녕하세요 여러분');
 * alert(encoded);
 * alert(hexEncoder.decode(encoded));
 */
function HexEncoder() {
    this.encode = function encode(originalStr) {
        var utf8Str = unescape(encodeURIComponent(originalStr));
        var hexStr = '';
        
        for (let i = 0; i < utf8Str.length; i++) {
            hexStr += utf8Str.charCodeAt(i).toString(16).padStart(2, '0');
        }
        
        return hexStr;
    };
    
    this.decode = function decode(hexString) {
        let utf8Str = '';
        
        for (let i = 0; i < hexString.length; i += 2) {
            utf8Str += String.fromCharCode(parseInt(hexString.substr(i, 2), 16));
        }
        
        return decodeURIComponent(escape(utf8Str));
    }
}

/** form 태그 리셋 */
function resetForm(formObj) {
    $(formObj).each(function() {
       var maybeForm = $(this);
       if(! maybeForm.is('form')) return;
       try { maybeForm[0].reset(); } catch(e) {} // DOM 자체 reset 함수 호출
       
       // 일부 요소는 리셋이 안되는 듯... 직접 리셋
       maybeForm.find("input[type='hidden']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='text']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='date']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='number']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='tel']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='email']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='time']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='search']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='url']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='month']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='color']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='range']").each(function() { $(this).val(''); });
       maybeForm.find("input[type='password']").each(function() { $(this).val(''); });
       maybeForm.find("textarea").each(function() { $(this).val(''); });
    });
}
$.dx.resetForm = resetForm;

/** form 태그에서 required 속성이 걸린 항목이 입력이 모두 완료되었는지 확인. 결과는 문자열들의 배열로 나오며, 비어 있으면 통과, 아닌 경우 배열 안에 오류 메시지들이 담김. required 속성을 넣지 못한다면 required 클래스를 넣어도 됨. */
function checkFormRequired(formObj) {
    var errorMsg = [];
    
    $(formObj).each(function() {
       var maybeForm = $(this);
       if(! maybeForm.is('form')) return;
       
       maybeForm.find("input").each(function() {
           var inpOne = $(this);
           var inpType = inpOne.attr('type');
           
           // 버튼 건너뛰기
           if(inpType == 'button' || inpType == 'submit' || inpType == 'reset') return;
           // 체크박스 건너뛰기
           if(inpType == 'checkbox' || inpType == 'radio') return;
           
           // required 여부 검사
           if((! inpOne.prop('required')) && (! inpOne.is('.required'))) return;
           
           // 값 입력여부 검사
           if(! $.dx.isnullempty(inpOne.val())) return;
           
           var errorOne = inpOne.attr('data-label') + '을 입력해 주세요.';
           if($.dx.isnullempty(inpOne.attr('data-label'))) errorOne = '필수 값이 입력되지 않았습니다.';
           
           errorMsg.push(errorOne);
       });
       
       maybeForm.find("textarea").each(function() {
           var inpOne = $(this);
           
           // required 여부 검사
           if((! inpOne.prop('required')) && (! inpOne.is('.required'))) return;
           
           // 값 입력여부 검사
           if(! $.dx.isnullempty(inpOne.val())) return;
           
           var errorOne = inpOne.attr('data-label') + '을 입력해 주세요.';
           if($.dx.isnullempty(inpOne.attr('data-label'))) errorOne = '필수 값이 입력되지 않았습니다.';
           
           errorMsg.push(errorOne);
       });
       
       maybeForm.find("select").each(function() {
           var inpOne = $(this);
           
           // required 여부 검사
           if((! inpOne.prop('required')) && (! inpOne.is('.required'))) return;
           
           // 값 입력여부 검사
           if(! $.dx.isnullempty(inpOne.val())) return;
           
           var errorOne = inpOne.attr('data-label') + '을 선택해 주세요.';
           if($.dx.isnullempty(inpOne.attr('data-label'))) errorOne = '필수 값이 선택되지 않았습니다.';
           
           errorMsg.push(errorOne);
       });
    });
    
    return errorMsg;
}
$.dx.checkFormRequired = checkFormRequired;

/** form 태그 required 유효성 검사 후, 걸렸으면 alert 후 false 리턴, 아니면 true 리턴 */
function alertRequireds(formObj) {
    var errors = $.dx.checkFormRequired(formObj);
    if(errors.length <= 0) return true;
    alert(errors[0]);
    return false;
}
$.dx.alertRequireds = alertRequireds;

/** form 태그에서 data-bytelength 속성이 있는 input, textarea 요소들을 검사. 결과는 문자열들의 배열로 나오며, 비어 있으면 통과, 아닌 경우 배열 안에 오류 메시지들이 담김. */
function checkFormLengths(formObj) {
    var errorMsg = [];
    
    $(formObj).each(function() {
        var maybeForm = $(this);
        if(! maybeForm.is('form')) return;

        maybeForm.find("input").each(function() {
            var inpOne = $(this);
            var types = inpOne.attr('type');

            // button, submit, reset, checkbox, radio 제외
            if(types == 'button' || types == 'submit' || types == 'reset' || types == 'checkbox' || types == 'radio') return;
            
            // data-bytelength 속성 존재여부 검사
            var dByteLen = inpOne.attr('data-bytelength');
            if($.dx.isnullempty(dByteLen)) return;
            if(isNaN(dByteLen)) return;

            // 길이 제한 체크
            dByteLen = parseInt(dByteLen);
            if($.dx.getStrUTF8Length(inpOne.val()) > dByteLen) {
                var errorOne = inpOne.attr('data-label') + ' 은/는 ' + dByteLen + 'bytes 이내로 입력해야 합니다.';
                if($.dx.isnullempty(inpOne.attr('data-label'))) errorOne = '일부 항목이 길이 제한을 초과했습니다.';
                
                errorMsg.push(errorOne);
            }
        });
        
        maybeForm.find("textarea").each(function() {
            var inpOne = $(this);

            // data-bytelength 속성 존재여부 검사
            var dByteLen = inpOne.attr('data-bytelength');
            if($.dx.isnullempty(dByteLen)) return;
            if(isNaN(dByteLen)) return;

            // 길이 제한 체크
            dByteLen = parseInt(dByteLen);
            if($.dx.getStrUTF8Length(inpOne.val()) > dByteLen) {
                var errorOne = inpOne.attr('data-label') + ' 은/는 ' + dByteLen + 'bytes 이내로 입력해야 합니다.';
                if($.dx.isnullempty(inpOne.attr('data-label'))) errorOne = '일부 항목이 길이 제한을 초과했습니다.';
                
                errorMsg.push(errorOne);
            }
        });
    });

    return errorMsg;
}
$.dx.checkFormLengths = checkFormLengths;

/** form 태그 내 길이 체크 유효성 검사 후, 걸렸으면 alert 후 false 리턴, 아니면 true 리턴 */
function alertFormLengths(formObj) {
    var errors = $.dx.checkFormLengths(formObj);
    if(errors.length <= 0) return true;
    alert(errors[0]);
    return false;
}
$.dx.alertFormLengths = alertFormLengths;

/** 주소검색 팝업 호출 */
function openJusoPop(callback) {
    new daum.Postcode({
        oncomplete: function(data) {
            var rtdata = data.roadAddress;
            if(typeof(callback) == 'function') callback(rtdata, data);
        }
    }).open();
};
$.dx.openJusoPop = openJusoPop;

/** 쿠키 관리도구 */
function CookieUtil() {
    this.get = function(name) {
        name = encodeURIComponent(name);
        
        var matches = document.cookie.match(new RegExp(
          "(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
        ));
        return matches ? decodeURIComponent(matches[1]) : null;
    };
    
    this.set = function(name, value, maxAge) {
        name  = encodeURIComponent(name);
        value = encodeURIComponent(value);
        
        if(maxAge != null && typeof(maxAge) != 'undefined') {
            maxAge = parseInt(maxAge);
            document.cookie = name + '=' + value + ';max-age=' + maxAge + ';path=/';
        } else {
            document.cookie = name + '=' + value + ';path=/';
        }
    };
    
    this.remove = function(name) {
        name = encodeURIComponent(name);
        document.cookie = name + '=; max-age=-1;';
    };
};

$.dx.cookie = new CookieUtil();

/** 응답 헤더값 찾기 */
function getResponseHeaderValue(jqXHR, headerKey) {
    return jqXHR.getResponseHeader(headerKey);
}
$.dx.getResponseHeaderValue = getResponseHeaderValue;

/** JWT토큰 수신 처리 */
function receiveJWT(jqXHR) {
    try {
        var order = $.dx.getResponseHeaderValue(jqXHR, "SetAuth");
        if(! $.dx.isnullempty(order)) {
            if(order == 'login') {
                var token = $.dx.getResponseHeaderValue(jqXHR, "Authorization");
                if(! $.dx.isnullempty(token)) {
                    $.dx.cookie.set('dxjwt', token);
                }
            }
            if(order == 'logout') {
                $.dx.cookie.remove('dxjwt');
            }
        }
    } catch(e) {
        $.log(e);
    }
}
$.dx.receiveJWT = receiveJWT;

// AJAX 이벤트 넣기
$.dx.ajaxevents.success.push(function(content, textStatus, jqXHR) {
    $.dx.receiveJWT(jqXHR);
});

/** Toast UI Editor 초기화, Editor 객체 반환 */
function initEditor(obj, edityn, jsonParam) {
    var editParam = {};
    $.each($.dx.editor.config, function(k, v) { editParam[k] = v; });
    
    if(edityn) {
        $.each($.dx.editor.configedit, function(k, v) { editParam[k] = v; });
    } else {
        editParam.viewer = true;
    }
    
    editParam['__uniqs'] = $.dx.randomInt(8);
    editParam.el = $(obj)[0];
    
    if(jsonParam) {
        if(typeof(jsonParam) == 'string') jsonParam = JSON.parse(jsonParam);
        $.each(jsonParam, function(k, v) { editParam[k] = v; });
    }
    
    var editorOne;
    if(edityn) editorOne = new toastui.Editor(editParam);
    else       editorOne = new toastui.Editor.factory(editParam)
    $.dx.editor.instances.push(editorOne);
    return editorOne;
}
$.dx.editor.init = initEditor;

/** Toast UI Editor 제거, 초기화할 때 받은 객체를 넣어야 함 */
function destroyEditor(editorInstance) {
    editorInstance.destroy();
}
$.dx.editor.destroy = destroyEditor;


// 스토리지 관련
$.dx.storage = {};
$.dx.storage.site = 'dx';
$.dx.storage.subs = 3;

/** localStorage 저장 데이터 조회 */
function getLocalSession() {
    if(typeof(localStorage) != 'object') return {};
    
    var strContent = localStorage.getItem($.dx.storage.site + '_' + $.dx.storage.subs + '_locals');
    if($.dx.isnullempty(strContent)) return {};
    
    try{ return JSON.parse(strContent); } catch(e) { $.dx.log('Warning ! Local session loading failed.'); $.dx.log(e); return {}}
}

$.dx.storage.local = {};
$.dx.storage.local.get = getLocalSession;

/** sessionStorage 저장 데이터 조회 */
function getTabSession() {
    if(typeof(sessionStorage) != 'object') return { header : {} };
    
    var strContent = sessionStorage.getItem('djbbs_sessions');
    if($.dx.isnullempty(strContent)) return { header : {} };
    
    try{ return JSON.parse(strContent); } catch(e) { $.dx.log('Warning ! Local session loading failed.'); $.dx.log(e); return {}}
}
$.dx.storage.session = {};
$.dx.storage.session.get = getTabSession;

/** localStorage 에 JSON 저장 */
function saveLocalSession(jsonObj) {
    if(jsonObj == null || typeof(jsonObj) == 'undefined') jsonObj = { header : {} };
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    
    if(typeof(localStorage) != 'object') return;
    localStorage.setItem($.dx.storage.site + '_' + $.dx.storage.subs + '_locals', JSON.stringify(jsonObj));
}
$.dx.storage.local.set = saveLocalSession;

/** sessionStorage 에 JSON 저장 */
function saveTabSession(jsonObj) {
    if(jsonObj == null || typeof(jsonObj) == 'undefined') jsonObj = { header : {} };
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    
    if(typeof(sessionStorage) != 'object') return;
    sessionStorage.setItem($.dx.storage.site + '_' + $.dx.storage.subs + '_locals', JSON.stringify(jsonObj));
}
$.dx.storage.session.set = saveTabSession;

$.dx.storage.cookie = {};
function getLocalSessionFromCookie() {
    var obj = $.dx.cookie.get('djstorage');
    if(obj == null) return null;
    if(typeof(obj) == 'undefined') return null;
    if(typeof(obj) == 'string') {
        try { obj = JSON.parse(obj); } catch(e) { $.log(e); return null; }
    }
    return obj;
}
$.dx.storage.cookie.get = getLocalSessionFromCookie;
function saveLocalSessionOnCookie(jsonObj) {
    if(jsonObj == null || typeof(jsonObj) == 'undefined') jsonObj = {  };
    if(typeof(jsonObj) == 'string') jsonObj = JSON.parse(jsonObj);
    $.dx.cookie.set('djstorage', JSON.stringify(jsonObj));
}
$.dx.storage.cookie.set = saveLocalSessionOnCookie;

// 암호화 기능
$.dx.crypto = {};
$.dx.crypto.currentKey = '';
$.dx.crypto.sha256 = {};
$.dx.crypto.sha256.enc = function(content) {
    return CryptoJS.SHA256(String(content)).toString();
};
$.dx.crypto.aes = {};
$.dx.crypto.aes.enc = function(content, password) {
    return CryptoJS.AES.encrypt(String(content), $.dx.crypto.sha256.enc(password)).toString();
};
$.dx.crypto.aes.dec = function(encrypted, password) {
    return CryptoJS.AES.decrypt(String(encrypted), $.dx.crypto.sha256.enc(password)).toString(CryptoJS.enc.Utf8);
};
$.dx.crypto.getKey = function(callback) {
    var responsed = false;
    var keys = '';
    $.dx.ajax({
        url : $.ctx + '/jsp/session/frontStorageKey.jsp',
        data : {},
        method : 'POST',
        dataType : 'json',
        success : function(res) {
            if(res.success) keys = res.content;
            
            if(responsed) return;
            responsed = true;
            if(! res.success) $.toast(res.message);
            if(typeof(callback) == 'function') callback(keys);
        }, complete : function() {
            if(responsed) return;
            responsed = true;
            if(! res.success) $.toast(res.message);
            if(typeof(callback) == 'function') callback(keys);
        }
    });
};
$.dx.crypto.key = function(callback) {
    if($.dx.crypto.currentKey != '') {
        if(typeof(callback) == 'function') callback($.dx.crypto.currentKey);
    } else {
        $.dx.crypto.getKey(callback);
    }
};

/** 테마 변경 */
function setTheme(theme) {
    theme = String(theme);
    theme = replaceString(replaceString(replaceString(theme, '=', ''), ',', ''), '&', '');
    
    $.dx.theme = theme;
    
    var loaded = $.dx.storage.local.get();
    if(loaded == null || typeof(loaded) == 'undefined') loaded = {};
    loaded.theme = theme;
    $.dx.storage.local.set(loaded);
    // $.dx.storage.cookie.set(loaded);
    
    location.href = $.ctx + '/main/page.do?theme=' + theme;
}
$.dx.setTheme = setTheme;

/** 공통 팝업을 위한 변수들 */
$.dx.pop = {};
$.dx.pop.requests = [];

/** 팝업 호출 요청내역을 위한 일종의 VO */
function PopupCallRequest() {
    this.popupType = '';
    this.popupCallKey = '';
    this.active = true;
    this.callbackFunction = function() {}
    this.ranomizeCallKey = function() {
        var val = Math.floor(Math.random() * 10000000) + '';
        this.popupCallKey = val;
        return val;
    }
    
    this.ranomizeCallKey();
};

/** 팝업 콜백 공통함수 */
function fPopCallback(popType, callKey, jsonData) {
    for(var idx=0; idx<$.dx.pop.requests.length; idx++) {
        var reqOne = $.dx.pop.requests[idx];
        
        if(reqOne.popupType    != popType) continue;
        if(reqOne.popupCallKey != callKey) continue;
        if(! reqOne.active) continue;
        
        if(typeof(jsonData) == 'string') {
            if(jsonData == '') jsonData = null;
            else jsonData = JSON.parse(jsonData);
        }

        reqOne.active = false;
        reqOne.callbackFunction(jsonData);
    }
};
$.dx.pop.callback = fPopCallback;

/** 
 * 그림 그리는 팝업 열기 
 *     option 매개변수는 JSON 객체로 받음.
 *         {
 *             callback : 팝업에서 "저장" 버튼 클릭 시 호출될 콜백함수, 매개변수로 JSON 객체가 들어오는데, 키 image 에 사용자가 그린 그림 데이터가 BASE64 문자열로 들어옴. 반드시 함수를 넣을 것.
 *           , width    : 팝업 가로 길이 (기본값 400, 필히 정수로 입력할 것 ! 문자열로 넣어도 되나, 숫자 외 다른 문자가 일절 들어가선 안됨)
 *           , height   : 팝업 세로 길이 (기본값 300, 필히 정수로 입력할 것 ! 문자열로 넣어도 되나, 숫자 외 다른 문자가 일절 들어가선 안됨)
 *           , msg      : 메시지 (팝업 내에 출력됨) 
 *         }
 * 
 */
function fPopCanvas(option) {
    var vOpt = {};
    if(option != null && typeof(option) == 'object') vOpt = option;
    if(typeof(option) == 'string') vOpt = JSON.parse(option);
    
    var newReq = new PopupCallRequest();
    newReq.popupType = 'canvas';
    if(typeof(vOpt.callback) == 'function') newReq.callbackFunction = vOpt.callback;
    $.dx.pop.requests.push(newReq);
    
    var widths  = 400;
    var heights = 300;
    if(! $.dx.isnullempty(vOpt.width )) widths  = parseInt(vOpt.width );
    if(! $.dx.isnullempty(vOpt.height)) heights = parseInt(vOpt.height);
    
    $.dx.pop.requests.push(newReq);
    window.open($.ctx + '/common/popCanvas.jsp?popCallKey=' + newReq.popupCallKey + '&popMsg=' + encodeURIComponent($.dx.isnullempty(vOpt.msg) ? '' : vOpt.msg), 'dxpop_popcanvas', 'width=' + widths + ', height=' + heights + ', toolbar=no, scrollbar=no, status=no');
}
$.dx.pop.canvas = fPopCanvas;

/** jqGrid 다루는 유틸 함수를 모은 클래스 (호출할 때에는 $.dx.grid. 뒤에 메소드 명을 붙여 호출) */
function JQGridManager() {
    //  jqGrid 활성화 여부 체크하는 함수
    this.isGrid = function isGrid(selector) {
        if( $(selector)[0].grid ) return true;
        return false;
    };

    this.getAllRowIDs = function getAllRowIDs(selector) {
        var jqGrid = $(selector);
        return jqGrid.getDataIDs();
    };
    
    // jqGrid 모든 데이터 조회
    this.getAll = function getAll(selector, filter) {
        var jqGrid = $(selector);
        var ids = jqGrid.getDataIDs();
        var array = [];
        $.each(ids, function(idx, rowId){
            rowData = jqGrid.getRowData(rowId);
            var allow = true;
            
            if(typeof(filter) == 'function') {
                allow = filter(rowData, idx, rowId);
            }
            
            if(allow) {
                rowData['_rowId'] = rowId;
                array.push(rowData);
            }
        });
        return array;
    };

    this.search = function search(selector, filter) {
        return $.dx.grid.getAll(selector, filter);
    };

    // jqGrid 에서 현재 선택된 행의 고유ID값 반환. jqGrid 자체 ID임에 유의 ! 여러 행 선택하는 타입의 경우는 배열이 리턴됨.   호출 예 : $.dx.grid.getSelectedRowIDs('#datagrid')
    this.getSelectedRowIDs = function getSelectedRowIDs(selector) {
        var jqGrid = $(selector);
        var multisel = jqGrid.jqGrid('getGridParam', 'multiselect');
        if(multisel) {
            return jqGrid.jqGrid('getGridParam', 'selarrrow');
        } else {
            return jqGrid.jqGrid('getGridParam', 'selrow');
        }
    };
    // jqGrid 에서 현재 선택된 행의 데이터 반환.   호출 예 : $.dx.grid.getSelectedRows('#datagrid')
    this.getSelectedRows = function getSelectedRows(selector) {
        var jqGrid = $(selector);
        var selectedRows = $.dx.grid.getSelectedRowIDs(selector);
        if(selectedRows == null) return null;
        return $.dx.grid.getRowData(selector, selectedRows);
    };
    // jqGrid 의 특정 행의 데이터 반환.   호출 예 : $.dx.grid.getRowData('#datagrid', '1')
    this.getRowData = function getRowData(selector, rowId) {
        var jqGrid = $(selector);
        if($.isArray(rowId)) {
            var results = [];
            for(var idx=0; idx<rowId.length; idx++) {
                results.push($.dx.grid.getRowData(selector, rowId[idx]));
            }
            return results;
        } else {
            return jqGrid.getRowData(rowId);
        }
    };

    // jqGrid 의 특정 행의 선택 모드 해제 (비동기 함수임에 유의 !) 호출 예 : $.dx.grid.finalizeRowEdit('#datagrid', '1')
    this.finalizeRowEdit = function finalizeRowEdit(selector, rowId, callback) {
        $(selector).jqGrid("saveRow", rowId, false, 'clientArray', null, function() {
            if(typeof(callback) == 'function') callback();
        });
    }
    
    // jqGrid 에서 행을 선택 (raiseselectrow 는 선택사항으로, true 시, 행 선택 처리 후 선택 이벤트가 연쇄적으로 호출된다. true 가 기본값이다.)
    this.select = function select(selector, rowId, raiseselectrow) {
        if(typeof(raiseselectrow) == 'undefined') raiseselectrow = true;
        try {
            if(typeof(rowId) == 'object') {
                // 고유ID 값이 아닌, json 객체 자체를 넣은 경우, 거기서 rowId를 찾는다.
                rowId = rowId['_rowId'];
            }

            $(selector).jqGrid('setSelection', rowId, raiseselectrow);
        } catch(e) {
            app.log(e);
        }
    }

    // jqGrid 첫 행을 선택
    this.selectFirst = function selectFirst(selector) {
        var gridObj = $(selector);
        var rowIDs  = gridObj.jqGrid('getDataIDs');
        if(rowIDs == null) return;
        if(rowIDs.length == 0) return;
        $.dx.grid.select(gridObj, rowIDs[0]);
    }

    // jqGrid 모든 행 선택 해제
    this.resetSelection = function resetSelection(selector) {
        $(selector).jqGrid('resetSelection');
    }
    
    // jqGrid 제거 (원래의 HTML요소로 돌아감)
    this.off = function off(selector) {
        try { $(selector).jqGrid('GridUnload'); } catch(e) { $.log(e); }
    }
};
$.dx.grid = new JQGridManager();
$.dx.isGrid = $.dx.grid.isGrid;


$.dx.progressbar = {};
$.dx.progressbar.indeterminePhase = 0;
$.dx.progressbar.timer = null;

/** 커스텀 프로그레스바 적용 */
function applyProgress() {
    $('.deploy_progress').each(function() {
        var progOne = $(this);
        if(progOne.is('.binded_progress')) return;
        $.dx.progressbar.refresh(progOne);
        progOne.addClass('binded_progress');
    });

    if($.dx.progressbar.timer == null) {
        $.dx.progressbar.timer = setInterval(function() {
            $.dx.progressbar.refreshAll();
            $.dx.progressbar.indeterminePhase++;
            if($.dx.progressbar.indeterminePhase >= 100) $.dx.progressbar.indeterminePhase = 0;
        }, 500);
    }
}

function refreshProgressAll() {
    $('.deploy_progress.binded_progress').each(function() {
        $.dx.progressbar.refresh(this);
    });
}

function refreshProgress(obj) {
    var progOne = $(obj);
    progOne.empty();
    progOne.append("<span class='deploy_progress_inside'></span>");
    progOne.append("<span class='deploy_progress_text'></span>");
    progOne.append("<span class='deploy_progress_indetermine invisible'></span>");

    var values = progOne.attr('data-value');
    var max    = progOne.attr('data-max');
    var msg    = progOne.attr('data-message');
    var percents = 0;

    if(values == null || typeof(values) == 'undefined') values = null;
    if(values == '' || values == '-1' || values == 'null' || values == 'indetermine') values = null;
    if(isNaN(values)) values = null;

    if(max == null || typeof(max) == 'undefined') max = '100';
    if(max == '' || max == 'null') max = '100';
    if(isNaN(max)) max = null;
    max = parseInt(max);
    if(max <= 0) max = 100;

    if(msg == null || typeof(msg) == 'undefined') msg = '';

    if(values != null) {
        values = parseInt(values);
        if(values < 0) values = null;
    }

    if(values == null) {
        progOne.find(".deploy_progress_inside").addClass('invisible');
        progOne.find(".deploy_progress_indetermine").removeClass('invisible').css('left', $.dx.progressbar.indeterminePhase + '%');
    } else {
        progOne.find(".deploy_progress_indetermine").addClass('invisible');
        progOne.find(".deploy_progress_inside").removeClass('invisible');

        percents = Math.floor((values * 100.0) / max);
        progOne.find(".deploy_progress_inside").css('width', percents + '%');
    }

    progOne.find(".deploy_progress_text").text(msg);
}
$.dx.progressbar.apply = applyProgress;
$.dx.progressbar.refresh = refreshProgress;
$.dx.progressbar.refreshAll = refreshProgressAll;
$.dx.applyProgress = applyProgress;
$.dx.refreshProgress = refreshProgress;
$.dx.refreshProgressAll = refreshProgressAll;

/** 창 크기가 변경되었을 때 호출 */
function refreshAutofit() {
    var innerSize = { w : window.innerWidth, h : window.innerHeight }
    var fRefreshEach = function(obj, isDialog) {
        var elemOne = $(obj);
        var sizes = { w : innerSize.w, h : innerSize.h  };
        
        if(isDialog) {
            var diag = $(elemOne.parents('.deploy_dialog').attr('data-dialog'));
            try { sizes = { w : diag.dialog('option', 'width'), h : diag.dialog('option', 'height')  }; } catch(ex) {}
        }
        
        var dataWidthGap = elemOne.attr('data-width-gap');
        if(dataWidthGap) {
            if(! isNaN(dataWidthGap)) sizes.w -= parseInt(dataWidthGap);
        }

        var dataHeightGap = elemOne.attr('data-height-gap');
        if(dataHeightGap) {
            if(! isNaN(dataHeightGap)) sizes.h -= parseInt(dataHeightGap);
        }

        if((! elemOne.is('.scrolltable_header_div')) && (! elemOne.is('tr')) && (! elemOne.is('.only_fit_height'))) elemOne.width(sizes.w);
        if(! elemOne.is('.only_fit_width')) elemOne.height(sizes.h);
    }
    
    $('.deploy_root'  ).find('.dxautofit').each(function() { fRefreshEach(this, false); });
    $('.deploy_dialog').find('.dxautofit').each(function() { fRefreshEach(this,  true); });
}

/** 창 크기에 맞게 크기가 바뀌어야 하는 요소들 이벤트 부여 */
function applyAutofit() {
    var dxroot = $('.deploy_root');
    
    if(dxroot.is('.binded_autofit')) { $.dx.refreshAutofit();  }
    else {
        $(window).on('resize', function() {
            var innerSize = { w : window.innerWidth, h : window.innerHeight }
            dxroot.find('.dxautofit').each(function() { $.dx.refreshAutofit(); });
        });
        
        dxroot.addClass('binded_autofit');
        $.dx.refreshAutofit();
    }
    
    $('.deploy_dialog').each(function() {
        var djdialog = $(this);
        if(djdialog.is('.binded_autofit')) { $.dx.refreshAutofit();  }
        else {
            var diag = $(djdialog.attr('data-dialog'));
            diag.on('dialogresize', function(event, ui) {
                djdialog.find('.dxautofit').each(function() { $.dx.refreshAutofit(); });
            });
                        
            djdialog.addClass('binded_autofit');
            $.dx.refreshAutofit();
        }
    });
}
$.dx.applyAutofit   = applyAutofit;
$.dx.refreshAutofit = refreshAutofit;

/** table 에 스크롤 적용 (헤더 틀고정) */
function applyScrollTable() {
    var dxroot = $('.deploy_root');
    dxroot.find('.target_scroll_table').each(function() { // table 의 바로 바깥에 있는 div 태그
        var divOne = $(this);
        var oldTable = divOne.find("table:not(.scrolltable_header)");
        var headers  = oldTable.find('thead');
        
        if(divOne.find('table.scrolltable_header').length <= 0) {
            // 본래의 테이블이 위치할 div 생성
            divOne.append("<div class='scrolltable_header_div'></div>");
            var divNew = divOne.find(".scrolltable_header_div");
            
            // 헤더 테이블 생성
            divOne.prepend("<table class='table_list scrolltable_header'></table>");
            var tableForHeader = divOne.find('table.scrolltable_header');
            oldTable.find('colgroup').clone().appendTo(tableForHeader);
            headers.detach().appendTo(tableForHeader);
            
            // 본래의 테이블 이동
            oldTable.detach().appendTo(divNew);
            
            // 스크롤 적용
            divNew.css('overflow-y', 'auto');
            
            // 스크롤이 적용되려면, 실제 스크롤 적용 영역에 높이 한도가 반드시 존재해야 함.
            if(typeof(divOne.attr('data-height')) != 'undefined') {
                if(divOne.attr('data-height') == 'auto') { // 자동 설정인 경우 창 크기에 맞게 높이 한도 자동 조절
                    divNew.addClass('dxautofit');
                    
                    var widthGap  = '0';
                    var heightGap = '0';
                    
                    if(typeof(divOne.attr('data-height-gap')) != 'undefined') heightGap = divOne.attr('data-height-gap');
                    
                    divNew.attr('data-width-gap' , widthGap);
                    divNew.attr('data-height-gap', heightGap);
                    $.dx.refreshAutofit();
                } else {
                    divNew.css('height', divOne.attr('data-height') + 'px');
                }
            }
            tableForHeader.css('margin-bottom', '0');
            oldTable.css('margin-top', '0');
        }
    });
};
$.dx.scrollTable = applyScrollTable;

/** 채팅 매니저 호출 시도 */
function loadChatManager() {
    var hiddens = $('#deployx_hidden');
    // 채팅 기능 호출
    if(hiddens.find('.dialog_chatroot').length <= 0) hiddens.append("<div class='div dialog dialog_chatroot'></div>");
    try {
        $.dx.chatman = new ChatManager( $('#deployx_hidden').find('.dialog_chatroot') );
        $.dx.chatman.init();
        $.dx.chatmanloaded = true;
    } catch(e) { 
        $.log('Failed to load ChatManager now. Will be retried after 1 second.');
        
        if(! $.dx.chatmanloaded) {
            // 실패 시 1초 후 다시 시도
            setTimeout(function() {
                $.dx.chatman = new ChatManager( $('#deployx_hidden').find('.dialog_chatroot') );
                $.dx.chatman.init();
                $.dx.chatmanloaded = true;
            }, 1000);
        }
        
    }
}
$.dx.loadchatman = loadChatManager;

/** 로그인되어 있으면 채팅 대화상자 호출 */
function triggerChatManagerOpen() {
    var fLoad = function() {
        if(! $.dx.isnullempty( $.dx.meta.user.id )) $.dx.chatman.show();
    };
    
    if($.dx.chatmanloaded) {
        try { fLoad(); } catch(e) { $.log(e); }
    } else {
        setTimeout(function() {
            fLoad();
        }, 1100);
    }
}
$.dx.triggerchatman = triggerChatManagerOpen;

/** 
 * 외부, 혹은 내부 URL 에 액세스해, 사이트 내용을 가져와 원하는 영역에 붙임. 
 *    매개변수로 JSON객체를 넣는다. url과 area는 필수로, url 에는 해당 URL을, area 에는, 내용이 들어갈 영역을 jQuery 선택자로 넣는다. 
 * 
 */
function putUrlContent(obj) {
    if(obj.area == null || typeof(obj.area) == 'undefined') obj.area = $('body');
    if(obj.data == null || typeof(obj.data) == 'undefined') obj.data = {};
    // if(String(obj.url).indexOf('/') == 0) obj.url = $.ctx + obj.url;
    if(typeof(obj.dataType) == 'undefined' || obj.dataType == null) obj.dataType = 'html';
    if(typeof(obj.method  ) == 'undefined' || obj.method   == null) obj.method   = 'GET';
    
    var oldDataType = String(obj.dataType).toLowerCase();
    if(oldDataType == 'md' || oldDataType == 'markdown') obj.dataType = 'text';
    
    var oldSucc = obj.success;
    obj.success = function(htmlContent) {
        if(oldDataType == 'md' || oldDataType == 'markdown') {
            var convertr = new showdown.Converter();
            if(obj.flavor) convertr.setFlavor(obj.flavor);
            htmlContent = convertr.makeHtml(htmlContent);
        }
        
        $(obj.area).html(htmlContent);
        if(typeof(oldSucc) == 'function') oldSucc(htmlContent);
    };
    
    $.dx.ajax(obj);
}
$.dx.putUrlContent = putUrlContent;

/** 테마 선택기 이벤트 부여 */
function bindThemeChanger() {
    $('.deploy_root ').find('.dx_themeselector').each(function() {
        var selOne = $(this);
        if(selOne.is('.binded_change')) return;
        
        selOne.val($.dx.meta.theme);
        selOne.on('change', function() {
            var sels = $(this);
            if(sels.is('.paused')) return false;
            sels.addClass('paused');
            
            $.dx.setTheme(sels.val());
            
            sels.removeClass('paused');
            return false;
        });
        
        selOne.addClass('binded_change');
    });
}
$.dx.bindThemeChanger = bindThemeChanger;

/** 날짜 형식 문자열을 바로 다른 형식으로 변환 */
function reformatDateString(dateStr, originalFormat, replaceFormat) {
    return moment(dateStr, originalFormat).format(replaceFormat);
}
$.dx.reformatDateString = reformatDateString;

/** 텍스트에 날짜 포맷 적용, 해당 태그에 datefield 클래스와 data-format 속성을 주어야 함 */
function replaceDateFormat() {
    $('.datefield').each(function() {
        var fieldOne = $(this);
        var formats  = fieldOne.attr('data-format');

        if($.dx.isnullempty(formats)) return;
        if(fieldOne.is('.dateformatted')) return;

        var yyyymmdd  = fieldOne.text();
        if($.dx.isnullempty(yyyymmdd)) return;
        
        var formatted = moment(yyyymmdd, 'YYYYMMDD').format(formats);

        fieldOne.attr('data-original', yyyymmdd);
        fieldOne.addClass('dateformatted');
        fieldOne.text(formatted);
    });
}

$.dx.replaceDateFormat = replaceDateFormat;


/** 날짜포맷 적용한 필드 원래대로 복원 */
function rollbackDateFormat() {
    $('.datefield').each(function() {
        var fieldOne = $(this);
        var formats  = fieldOne.attr('data-format');

        if($.dx.isnullempty(formats)) return;
        if(! fieldOne.is('.dateformatted')) return;

        var originals = fieldOne.attr('data-original');
        if($.dx.isnullempty(originals)) return;

        fieldOne.text(originals);
        fieldOne.removeClass('dateformatted');
        fieldOne.removeAttr('data-original');
    });
}
$.dx.rollbackDateFormat = rollbackDateFormat;

/** 이미지를 바로 선택받음 (파일 선택 대화상자가 나타남) 결과는 callback 함수의 매개변수로, BASE64 형식 문자열로 나타남. 이미지 선택을 취소했거나 파일 불러오기 실패 시 callback 함수가 호출될 수 있으나 매개변수에 null 이 들어감. */
function askImageAttach(callback) {
    var ended = false;
    var inputOne = document.createElement('input');
    
    inputOne.type = 'file';
    inputOne.accept = 'image/*';
    inputOne.id = 'tempimg_' + (Math.random() * 999999);
    inputOne.onchange = function(e) {
        if(ended) return;

        const reader = new FileReader();
        reader.onload = function() {
            var res = reader.result;
            ended = true;
            if(typeof(callback) == 'function') callback(res);
        }
        reader.onabort = function() {
            if(ended) return;
            ended = true;
            if(typeof(callback) == 'function') callback(null);
        }
        reader.onerror = function() {
            if(ended) return;
            ended = true;
            if(typeof(callback) == 'function') callback(null);
        }
        reader.readAsDataURL(e.target.files[0]);
    };

    inputOne.onabort = function() {
        if(ended) return;
        ended = true;
        if(typeof(callback) == 'function') callback(null);
    }

    inputOne.click();
}
$.dx.askImageAttach = askImageAttach;

/** 해당 영역을 Canvas 태그로 생성, canvas 객체는 콜백함수에서 액세스해야 함. */
function convertCanvas(area, title, callback) {
    // area 에 클래스 부여 (다크모드 제외)
    $(area).addClass('document_style');
    
    // 가상의 canvas 태그가 만들어질 div 영역
    var pdfCanvasArea = $('#div_hidden_canvas_area');
    if(pdfCanvasArea.length <= 0) { // 없으면 body 안에다 새로 만든다.
        $('body').append("<div class='invisible' id='div_hidden_canvas_area'></div>");
        pdfCanvasArea = $('#div_hidden_canvas_area');
    }
    pdfCanvasArea.empty();

    html2canvas( $(area)[0], title ).then(function(canvas){
        canvas = $(canvas);
        pdfCanvasArea.append(canvas);
        if(typeof(callback) == 'function') callback(canvas);
        canvas.remove();
    });
};
$.dx.convertCanvas = convertCanvas;

/** canvas 에 렌더링된 이미지를 PDF로 변환, jsPDF document 객체로 반환 */
function convertCanvasToPDF(canvasObj, callback) {
    var canvasRaw  = $(canvasObj)[0];
    var imgData    = canvasRaw.toDataURL('image/png');
    var imgWidth   = 210;
    var pageHeight = imgWidth * 1.414;
    var imgHeight  = (canvasRaw.height * imgWidth / canvasRaw.width);
    var heightLeft = imgHeight;
    
    var docOne   = new jsPDF("p", "mm", "a4");
    var position = 0;
    
    docOne.addImage(canvasRaw, "PNG", 0, position, imgWidth, imgHeight, '', false);
    heightLeft -= pageHeight;
    while(heightLeft >= 0) {
        position = heightLeft - imgHeight;
        docOne.addPage();
        docOne.addImage(imgData, 'N', 0, position, imgWidth, imgHeight, '', 'FAST');
        heightLeft -= pageHeight;
    }
    
    if(typeof(callback) == 'function') callback(docOne);
    return docOne;
};
$.dx.convertCanvasToPDF = convertCanvasToPDF;

/** canvas 에 렌더링된 이미지를 PDF로 변환, 새 창으로 출력 */
function convertCanvasPDFtoWindow(canvasObj, callback) {
    var docOne = $.dx.convertCanvasToPDF(canvasObj, callback);
    return docOne.output('dataurlnewwindow');
};
$.dx.convertCanvasPDFtoWindow = convertCanvasPDFtoWindow;

/** canvas 에 렌더링된 이미지를 PDF로 변환, 데이터 URI 문자열로 반환, 이를 iframe 의 src 에 넣어 사용 */
function convertCanvasPDFtoDataUri(canvasObj, callback) {
    var docOne = $.dx.convertCanvasToPDF(canvasObj, callback);
    return docOne.output('datauristring');
};
$.dx.convertCanvasPDFtoDataUri = convertCanvasPDFtoDataUri;

/** 해당 영역을 PDF로 만들어 새 창으로 출력 */
function convertPDF(area, title, callback) {
    $.dx.convertCanvas(area, title, function(canvas) {
        var ret = $.dx.convertCanvasPDFtoWindow(canvas);
        if(typeof(callback) == 'function') callback(ret);
    });
}

$.dx.convertPDF = convertPDF;

/** 해당 영역을 PDF로 만들어 새 창으로 출력, 데이터 URI 문자열로 반환 (콜백함수 매개변수로 받아야 함), 이를 iframe 의 src 에 넣어 사용 */
function convertPDFURI(area, title, callback) {
    $.dx.convertCanvas(area, title, function(canvas) {
        var ret = $.dx.convertCanvasPDFtoDataUri(canvas);
        if(typeof(callback) == 'function') callback(ret);
    });
}

$.dx.convertPDFURI = convertPDFURI;

/** 테이블을 PDF로 만들어 새 창으로 출력 (테스트) */
function convertTablePDF(tableSelectorId, title, callback) {
    applyPlugin(jsPDF);
    var docOne = new jsPDF("p", "mm", "a4");
    docOne.addFileToVFS('nanum.ttf', _base64font);
    docOne.addFont('nanum.ttf', 'NanumGothicCoding', 'normal');
    docOne.setFont('NanumGothicCoding');
    docOne.autoTable({html : '#' + tableSelectorId});
    
    if(typeof(callback) == 'function') callback(docOne);
    return docOne.output('dataurlnewwindow');
}
$.dx.convertTablePDF = convertTablePDF;

/** 특정 사용자의 간단한 정보 불러오기, callback 함수가 호출되며 안에 JSON으로 정보가 담김 */
function getUserSimpleInfo(userId, callback) {
    $.dx.ajax({
        url : $.ctx + '/main/getUserSimpleInfo.do',
        data : { ID : userId },
        dataType : 'JSON',
        type : 'POST',
        success : function(infos) {
            if(typeof(callback) == 'function') callback(infos);
        }, error : function() {
            if(typeof(callback) == 'function') callback(null); 
        }
    });
}
$.dx.getUserSimpleInfo = getUserSimpleInfo;

/** 특정 사용자의 프로필 이미지 불러오기. imgType 의 경우 PROFILE 은 프로필 이미지, SIGN 은 서명, 불러온 후 callback 함수가 호출되며 첫 번째에 이미지, 두 번째에 해당 사용자의 성명이 들어감. */
function getProfileImages(userId, imgType, callback) {
    $.dx.ajax({
        url : $.ctx + '/main/getUserImage.do',
        data : {
            ID : userId,
            IMAGE_TYPE : imgType
        },
        dataType : 'JSON',
        type : 'POST',
        success : function(profiles) {
            if(profiles.length <= 0) { 
                if(typeof(callback) == 'function') callback(null, null); 
            } else {
                if(! $.dx.isnullempty(profiles[0].IMAGES)) {
                    if(typeof(callback) == 'function') callback(profiles[0].IMAGES, profiles[0].NAME);
                } else {
                    if(typeof(callback) == 'function') callback(null, null);
                }
            } 
        }, error : function() {
            if(typeof(callback) == 'function') callback(null, null); 
        }
    });
}
$.dx.getProfileImages = getProfileImages;

/** 사용자의 프로필 이미지 불러오기 */
function loadProfileImages(callback) {
    var liProfile = $('.li_navtop_profile_img');
    liProfile.addClass('invisible');
    
    if($.dx.isnullempty($.dx.meta.user.id)) {
        if(typeof(callback) == 'function') callback(null); 
        return;
    }
    
    $.dx.getProfileImages($.dx.meta.user.id, 'PROFILE', function(res) {
        if($.dx.isnullempty(res)) { 
            if(typeof(callback) == 'function') callback(null);
            return; 
        } else {
            var imgObj = liProfile.find('.img_navtop_profile_img');
            liProfile.removeClass('invisible');
            imgObj.attr('src', res);
            if(typeof(callback) == 'function') callback(res);
        } 
    });
}
$.dx.loadProfileImages = loadProfileImages;

/** 서비스 사용 준비 상태 체크 (콜백함수에서 응답) */
function checkServiceInitialized(callback) {
    // 서버 요청 호출 이후의 작업을 미리 준비하고, 중복호출 방지조치
    var responsed = false;
    var fAfter = function(succ, mess) {
        if(responsed) return;
        responsed = true;
        if(typeof(callback) == 'function') callback(succ, mess);
    }
    
    // 서버 요청 전송
    $.dx.ajax({
        url : $.ctx + '/main/checkAlive.do',
        data : { },
        dataType : 'JSON',
        type : 'POST',
        success : function(res) {
            $.log(res);
            fAfter(res.success, res.message);
        }, error : function() { 
            fAfter(false, '서버와 통신 중 문제가 발생하였습니다.');
        }, finally : function() {
            fAfter(false, '서버로부터 응답을 받지 못했습니다.');
        }
    });
}
$.dx.checkServiceInitialized = checkServiceInitialized;

/** 현재 메뉴의 메타정보 확인 */
function getMenuMetas() {
    var res = {};
    
    // hidden 영역에서 정보 가져오기
    var divHidden = $('#deployx_hidden');
    
    res.ctx    = divHidden.find('.deployx_ctx').text();
    res.theme  = divHidden.find('.deployx_theme').text();
    res.menu  = {};
    
    try { res.maxlen = parseInt(divHidden.find('.deployx_maxlen').text()); } catch(e) { res.maxlen = 1048575; };
    try { res.menu   = JSON.parse(divHidden.find('.deployx_menu').text()); } catch(e) { res.menu   = {} };
    
    return res;
}
$.dx.getMenuMetas = getMenuMetas;

/** 현재 로그인한 세션의 메타정보 확인 */
function getUserMetas() {
    var res = {};
    
    // hidden 영역에서 정보 가져오기
    var divHidden = $('#deployx_hidden');
    
    res.id   = divHidden.find('.deployx_userid'  ).text();
    res.name = divHidden.find('.deployx_username').text();
    
    return res;
}
$.dx.getUserMetas = getUserMetas;

/** 기타 메타정보 조회 */
function getEtcMetas() {
    var res = {};
    
    // hidden 영역에서 정보 가져오기
    var divHidden = $('#deployx_hidden');
    
    res.useChat = divHidden.find('.deployx_usechat').text();
    if(res.useChat == 'Y' || res.useChat == 'y' || res.useChat == 'true') res.useChat = true;
    else res.useChat = false;
    
    res.chatref = divHidden.find('.deployx_chatref').text();
    if(! isNaN(res.chatref)) res.chatref = parseInt(res.chatref);
    else res.chatref = 4000;
    
    res.uploadMax = divHidden.find('.deployx_maxsize').text();
    if(! isNaN(res.uploadMax)) res.uploadMax = parseInt(res.uploadMax);
    else res.uploadMax = 4000;
    
    return res;
}
$.dx.getEtcMetas = getEtcMetas;

/** 메뉴 이동 처리 (현재 사용 X) */
function processGoTo() {
    // hidden 영역에서 정보 가져오기
    var metas = $.dx.getMenuMetas();
    $.ctx = metas.ctx;
    $.dx.meta = metas;
    $.dx.theme = metas.theme;
    $.dx.maxlength = metas.maxlen;
    $.dx.meta.user = $.dx.getUserMetas();
    $.dx.meta.etcs = $.dx.getEtcMetas();
    
    //     현재 메뉴정보 가져오기
    var menuCurrent = metas.menu;
    var usrInfos    = $.dx.meta.user;

    // 가져온 메뉴 정보로, 메인 영역에 컨텐츠 불러와 넣기
    var divMain = $('#div_deployx_main');
    var prgmType = menuCurrent.PROGRAM_TYPE;
    
    // 작업 전, 작업완료 후 수행할 작업들을 미리 준비
    var fAfter = function() {
        $.dx.initApplyDefaults();
    };
    
    // 작업 전, 작업실패 시 수행할 작업들을 미리 준비
    var fError = function(jqXHR, status, errorThrown) {
        $.dx.ajax({
            url : $.ctx + '/common/error404in.jsp',
            data : { menuNo : menuCurrent.MENU_NO },
            dataType : 'html',
            type : 'POST',
            success : function(htmlContentx) {
                divMain.html(htmlContentx);
            }
        });
    };
    
    // 해당 메뉴정보가 있어, 내부 링크 데이터를 불러오는 동작을 미리 정의
    var fGetUrl = function(url) {
        $.dx.ajax({
             url : $.ctx + url,
             data : { menuNo : menuCurrent.MENU_NO, PROGRAM_NO : menuCurrent.PROGRAM_NO },
             dataType : 'html',
             type : 'POST',
             success : function(htmlContent) {
                 if(htmlContent == null) htmlContent = '';
                 if(htmlContent.indexOf('<!DOCTYPE') >= 0) htmlContent = '';
                 
                 try {
                     if($.dx.isnullempty(htmlContent)) fError();
                     else {
                         divMain.html(htmlContent);
                         divMain.find("input.dxbtn:not(.binded_button)").button().addClass('binded_button');
                     }
                 } catch(exHtml) {
                     $.log('/* Error when fill HTML on main area...');
                     $.log(exHtml);
                     $.log(htmlContent);
                     $.log('*/');
                 }
             }, error : function(jqXHR, status, errorThrown) {
                 fError(jqXHR, status, errorThrown);
             }, complete : function() {
                 fAfter();
             }
        });
    };
    
    // 해당 메뉴정보가 없을 때의 동작을 미리 정의
    var fOnNoMenu = function() {
        // 메인 화면 / 대시보드
        var subUrl = 'main.do';
        if(! $.dx.isnullempty(usrInfos.id)) subUrl = 'dashboard.do';
        
        fGetUrl('/main/' + subUrl);
    };
    
    // 프로그램 유형에 따라 다른 동작 수행
    if($.dx.isnullempty(menuCurrent.MENU_NO)) {
        fOnNoMenu();
    } else if(prgmType == '00') {
        // NOTHING (빈 화면, 레벨 1 메뉴들을 매핑시키는 프로그램들을 위한 코드라 의미는 없음)
        fAfter();
    } else if(prgmType == '01') {
        // 게시판 (URL ajax로 호출하여, html 태그 형태로 가져와 메인 영역에 붙임)
        fGetUrl('/main/board.do');
    } else if(prgmType == '02') {
        // 내부 링크 (내부 URL ajax로 호출하여, html 태그 형태로 가져와 메인 영역에 붙임)
        fGetUrl('/' + menuCurrent.PROGRAM_URL);
    } else if(prgmType == '03') {
        // 외부 링크 - 여기서는 아무런 일을 할 필요가 없음 (메뉴 클릭 이벤트에서 URL로 새 창을 띄움)
        // location.href = menuCurrent.PROGRAM_URL;
        fAfter();
    } else if(prgmType == '04') {
        // 자체 프로그램 (DX_PROGRAM 내 컨텐츠 출력)
        fGetUrl('/main/pgContent.do');
    } else {
        // 코드 이상 or 존재하지 않는 메뉴
        fOnNoMenu();
    }
}
$.dx.processGoTo = processGoTo;

/** 화면 전체 공통 이벤트 적용 */
function initApplyDefaults() {
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

    // hidden 영역에서 정보 가져오기
    var metas = $.dx.getMenuMetas();
    $.ctx = metas.ctx;
    $.dx.meta = metas;
    $.dx.theme = metas.theme;
    $.dx.maxlength = metas.maxlen;
    $.dx.meta.user = $.dx.getUserMetas();
    $.dx.meta.etcs = $.dx.getEtcMetas();
    
    // ajax 시 헤더값
    $.each(localData.header, function(k, v) { $.dx.ajaxheader[k] = v; });
    
    // 테마
    if(! isnullempty( localData.theme )) $.dx.theme = localData.theme;
    
    // 엔터키 이벤트
    $.dx.applyEnterSearch();
    
    // 푸터 이벤트
    $(".dxfooter .copyright:not(.binded_click").on('click', function() {
        window.open($.ctx + '/common/license.jsp', 'djcopyright', 'width=580,height=460,toolbar=no,status=no');
    }).addClass('binded_click');
    
    // 메뉴 클릭 범위 조절
    if($.dx.themeoption.menuClickUnit == 'a') $('.deployx_nav li.menu').find("a").addClass('width-fitcontent');
    
    // 에디터 테마
    if( $('.deploy_root').is('.deploy_theme_dark') ) $.dx.editor.config.theme = 'dark';
    else $.dx.editor.config.theme = 'light';
    
    // 테마 선택기 이벤트
    $.dx.bindThemeChanger();
    
    // 지정된 위치에 버전 출력
    $('.dx_version_script').text($.dx.ver);
    $('.dx_build_script').text($.dx.build);
    
    // 로그인 되어 있으면 프로필 이미지 불러오기
    try { $.dx.loadProfileImages(); } catch(e) { $.dx.log(e); }

    // 채팅 기능 호출
    try { if($.dx.meta.etcs.useChat) $.dx.loadchatman(); } catch(e) { $.dx.log(e); }
    
    // 사전 컴파일용 iframe 이 존재하면, src 지정
    $('iframe.iframe_preloading').attr('src', $.ctx + '/common/precompile.jsp');
};
$.dx.initApplyDefaults = initApplyDefaults;

/** 화면 레이아웃 초기화, initApplyDefaults 포함 */
function initPageFrames() {
    if($.dx.initcalled) { $.dx.initApplyDefaults(); return; }
    $.dx.initcalled = true;

    // 메뉴 이동 처리 - 사용 X (nav.jsp 및 MainController 의 /main/page.do URL 구현부에서 대신함)
    // $.dx.processGoTo();
    
    // 기본 초기화 작업 수행
    $.dx.initApplyDefaults();

    // 로그인되어 있으면 채팅 대화상자 호출
    if($.dx.meta.etcs.useChat) $.dx.triggerchatman();
}
$.dx.init = initPageFrames;