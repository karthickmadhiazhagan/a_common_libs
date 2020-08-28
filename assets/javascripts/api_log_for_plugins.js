/**
 * Created by gladyshevae on 24.01.17.
 */

function toggleLogSelection(el) {
    var checked = $(this).prop('checked');
    var boxes = $(this).parents('table').find('input[name=ids\\[\\]]:not(.served)');
    if(checked){
        boxes.prop('checked', checked);
        boxes.trigger('change');
    }
}

function change_served(el) {
    var $this = $(this);
    var checked = $this.prop('checked');
    var value = $this.prop('value');
    var loader = '<div class="mw_loader loader">&nbsp;</div>';
    if(checked){
        $this.addClass('served');
    }else{
        $this.removeClass('served');
    }
    $this.parent().append(loader);
    $this.hide();
    $.ajax({ url: RMPlus.Utils.relative_url_root + '/api_log_for_plugins/' + value + '/log_served',
        type: 'GET',
        success: function(data) {
            $this.parent().find('.loader').remove();
            $this.show();
        }
    })
}

function filter_log(el) {
    var $this = $(this);
    var value = $(this).val();
    if(value != undefined && value != 'undefined' && value != ''){
        window.location.href = RMPlus.Utils.relative_url_root + '/api_log_for_plugins/?plugin_code=' + value;
    }else{
        window.location.href = RMPlus.Utils.relative_url_root + '/api_log_for_plugins/';
    }
}

$(document).ready(function(){
    var api_log_for_plugin = $('#api_log_for_plugin');
    api_log_for_plugin.find('thead input[type=checkbox].toggle-selection').on('change', toggleLogSelection);
    api_log_for_plugin.find('tbody input[type=checkbox]').on('change', change_served);
    api_log_for_plugin.find('select#plugin_code').on('change', filter_log);
});