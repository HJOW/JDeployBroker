/**
 * input 필드 Masking 적용을 위한 lib
 *    MaskUtil 키워드를 통해 액세스
 *    예)
 *        MaskUtil.maskNumber($('#maskNumber'), 'int');
 */

function MaskClass() {
    /** MaskUtil 사용 준비. MaskUtil 하위 메소드들의 이용을 위해서는 이 메소드를 먼저 호출해야 한다. */
    this.prepare = function prepare() {
        if(typeof($.fn.maskutil) != 'function') {
            $.fn.maskutil = function() { return true };
            $.fn.value = $.fn.val;
            $.fn.val = function(newVal) {
                if(typeof(newVal) != 'undefined') {
                    if($(this).is('.mask_applied')) return MaskUtil.val(this, newVal);
                    return $.fn.value.call(this, newVal);
                }
                
                if($(this).is('.mask_applied')) return MaskUtil.val(this);
                return $.fn.value.call(this);
            }
        }
    }
    
    /** 
     * MaskUtil 사용 준비 + 적용. MaskUtil.prepare 함수가 같이 호출된다. input 요소들에 특정 class들이 들어가 있으면 마스킹을 적용시킨다. 
     *     인식 가능한 클래스 : mask_int, mask_float
     *
     */
    this.apply = function apply() {
        MaskUtil.prepare();
        $('.mask_int').each(function() {
            MaskUtil.maskNumber($(this), 'int');
        });
        
        $('.mask_float').each(function() {
            MaskUtil.maskNumber($(this), 'float');
        });
    }
    
    /** MaskUtil 사용 종료. MaskUtil.prepare 함수 호출 전으로 최대한 되돌린다. */
    this.destroy = function destroy() {
        if(typeof($.fn.maskutil) != 'function') {
            $('.mask_applied').each(function() {
                MaskUtil.unmask(this); 
            });
            $.fn.val = $.fn.value;
        }
        
        $.fn.value = null;
        $.fn.maskutil = null;
    }
    
    /** 
     * 
     * 해당 input 필드에 마스킹을 적용한다.
     * 
     * @param selector : input 필드 선택자 (예: $('#inp_bid'))  
     * @param types    : 유형 (int, float 중에서 사용 가능)
     * 
    */
    this.maskNumber = function maskNumber(selector, types) {
        var comp = $(selector);
        
        if(! comp.is('input')) throw '해당 컴포넌트는 input 요소가 아닙니다.';
        if(comp.is('.mask_applied')) return; // 이미 마스킹 처리된 컴포넌트는 건너뛰기
        
        // 기존 어트리뷰트 백업
        
        var atx = comp.attr('min');
        if(typeof(atx) != 'undefined') { comp.attr('data-n-min', atx); }
        comp.removeAttr('min');
        
        atx = comp.attr('max');
        if(typeof(atx) != 'undefined') { comp.attr('data-n-max', atx); }
        comp.removeAttr('max');
        
        atx = comp.attr('step');
        if(typeof(atx) != 'undefined') { comp.attr('data-n-step', atx); }
        comp.removeAttr('step');
        
        comp.attr('data-m-mtype', comp.attr('type'));
        
        // 텍스트 타입으로 변경
        
        comp.attr('type', 'text');
        comp.attr('data-n-mtype', types);
        
        // 변경 이벤트 적용
        
        var fChange = function() {
            if($(this).is('.mask_lockedevents')) return;
            MaskUtil.onChange($(this), types);
        };
        
        comp.on('change', fChange);
        comp.on('keyup' , fChange);
        comp.on('blur'  , fChange);
        comp.addClass('mask_applied');
        comp.addClass('mask_applied_number');
        
        comp.trigger('change');
    }
    
    /** 값 변경 시 호출될 액션 */
    this.onChange = function(selector, types) {
        var comp = $(selector);
        
        var valStr = comp.value();
        if(typeof(valStr) == 'string') valStr = valStr.replace(/,/g, "");
        
        var noFloat = false;
        if(valStr.indexOf('.') == valStr.length - 1) noFloat = true;
        
        var valNum = 0;
        if(types == 'int') {
            valNum = parseInt(valStr);
        } else {
            valNum = parseFloat(valStr);
        }
        
        if(isNaN(valNum)) {
            comp.value('');
        } else {
            valStr = Number(valNum).toLocaleString();
            if(noFloat) valStr = valStr + '.';
            comp.value( valStr );
        }
    }
    
    /** 
     * 
     * 해당 input 필드에 마스킹을 적용 해제한다. change 와 keyup, blur 이벤트가 사라지므로 주의 !
     * 
     * @param selector : input 필드 선택자 (예: $('#inp_bid'))
     * 
    */
    this.unmaskNumber = function unmaskNumber(selector) {
        var comp = $(selector);
        var befVal = comp.val();
        
        if(! comp.is('input')) throw '해당 컴포넌트는 input 요소가 아닙니다.';
        if(! comp.is('.mask_applied')) return; // 이미 마스킹 처리된 컴포넌트에만 사용 가능
        if(! comp.is('.mask_applied_number')) return;
        
        comp.val('');
        comp.off('change');
        comp.off('keyup');
        comp.off('blur');
        
        if(comp.attr('data-n-min')) {
            comp.attr('min', comp.attr('data-n-min'));
            comp.removeAttr('data-n-min');
        }
        
        if(comp.attr('data-n-max')) {
            comp.attr('min', comp.attr('data-n-max'));
            comp.removeAttr('data-n-max');
        }
        
        if(comp.attr('data-n-step')) {
            comp.attr('min', comp.attr('data-n-step'));
            comp.removeAttr('data-n-step');
        }
        
        comp.removeAttr('data-n-mtype');
        
        comp.attr('type', comp.attr('data-m-mtype'));
        comp.removeAttr('data-m-mtype');
        
        comp.removeClass('mask_applied');
        comp.removeClass('mask_applied_number');
        comp.val(befVal.replace(/,/g, ""));
    }
    
    /** 
     * 
     * 해당 input 필드에 마스킹을 적용 해제한다.
     * 
     * @param selector : input 필드 선택자 (예: $('#inp_bid'))
     * 
    */
    this.unmask = function unmask(selector) {
        var comp = $(selector);
        
        if(! comp.is('input')) throw '해당 컴포넌트는 input 요소가 아닙니다.';
        if(! comp.is('.mask_applied')) return; // 이미 마스킹 처리된 컴포넌트에만 사용 가능
        
        if(comp.is('.mask_applied_number')) MaskUtil.unmaskNumber(selector);
    };
    
    /** 값을 변경하거나, 해당 input 필드의 값 반환 */
    this.val = function val(selector, newVal){
        var comp = $(selector);
        comp.addClass('mask_lockedevents');
        
        if(typeof(newVal) != 'undefined') {
            // 두 번째 매개변수 존재 시, 값 세팅
            comp.value(newVal);
            if(comp.is('.mask_applied')) {
                MaskUtil.onChange(comp, comp.attr('data-n-mtype'));
            }
        }
        
        var value = null;
        if(comp.is('.mask_applied')) value = comp.value().replace(/,/g, "");
        else value = comp.value();
        
        comp.removeClass('mask_lockedevents');
        return value;
    }
}
var MaskUtil = new MaskClass();