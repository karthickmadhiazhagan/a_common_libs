$(document).ready(function(){
  $(document.body).on('click', 'div.period_picker_input, .period_picker_max_min', function(){
    $('div.period_picker_box .period_picker_cell[data-date="' + moment().format('YYYY-MM-DD') + '"]').addClass('acl_picker_today');
    // $('div.period_picker_box.xdsoft_noselect.visible.active .period_picker_cell[data-date="' + moment().format('YYYY-MM-DD') + '"]').addClass('acl_picker_today');
  });
  var original_buildFilterRow = buildFilterRow;

  buildFilterRow = function(field, operator, values){
    original_buildFilterRow.apply(this, arguments);
    var fieldId = field.replace('.', '_');
    var filterOptions = availableFilters[field];

    if (filterOptions['type'] === 'acl_date_time' || filterOptions['type'] === 'acl_date_month') {
      var td_value = $('#tr_' + field).find('td.values');
      td_value.html('');
      td_value.append('<span><input type="text" name="v['+ field +'][]" id="values_'+ fieldId +'_1" size="10" class="value" /></span>'+
          '<span style="display: none;"> — <input type="text" name="v['+ field +'][]" id="values_'+ fieldId +'_2" size="10" class="value"/></span>');

      if($().periodpicker){
        var opts;
        if (filterOptions['type'] === 'acl_date_time') {
          opts = datetimepickerOptions;
        } else {
          opts = monthperiodpickerOptions;
        }
        $('#values_'+fieldId+'_1').val(values[0]).periodpicker(opts);
        $('#values_'+fieldId+'_2').val(values[1]).periodpicker(opts);
      }
    }
  };

  var original_enableValues = enableValues;

  enableValues = function(field, indexes){
    original_enableValues.apply(this, arguments);
    $('#values_' + field + '_1' + ' + .period_picker_input').prev().hide();
    $('#values_' + field + '_2' + ' + .period_picker_input').prev().hide();
  };
});