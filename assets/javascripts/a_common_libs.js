// Namespace declaration
var RMPlus = (function (my) {
  var my = my || {};
  return my;
})(RMPlus || {});

RMPlus.ACL = (function(my){
  var my = my || {};

  my.apply_ajaxable_custom_field = function($select) {
    if (!$.fn.select2) { return; }
    if ($select.hasClass('acl-ajaxable')) { return; }
    var multiple = $select.prop('multiple');
    var url = $select.attr('data-url');
    var project_id = $select.attr('data-project-id');
    var customized_id = $select.attr('data-customized-id');

    $select.addClass('acl-ajaxable').select2({
      minimumInputLength: 3,
      selectOnClose: false,
      multiple: multiple,
      escapeMarkup: function (m) { return m; },
      width: '400px',
      placeholder: ' ',
      allowClear: true,
      ajax: {
        url: url,
        dataType: 'json',
        delay: 200,
        cache: true,
        data: function (params) {
          return { q: params.term, project_id: project_id, customized_id: customized_id };
        },
        processResults: function(data, params) {
          return { results: data };
        }
      }
    });
  };

  my.load_issue_edit_form = function(issue_id, wiki_js, calendar_js, callback) {
    var container = $('#acl-issue-edit-form');
    if (my.enable_ajax_edit_form === "true" && !container.hasClass('acl-edit-form-loaded')) {
      if (container.hasClass('acl-edit-form-loading')) {
        var interval = setInterval(function() {
          if (container.hasClass('acl-edit-form-loaded')) {
            clearInterval(interval);
            callback.apply(this);
          }
        }, 100);
      } else {
        container.addClass('acl-edit-form-loading');
        $.ajax({
          method: 'GET',
          url: RMPlus.Utils.relative_url_root + '/issues/' + issue_id + '/acl_edit_form?wiki_js=' + (wiki_js ? 1 : 0) + '&calendar_js=' + (calendar_js ? 1 : 0),
          context: container
        }).always(function () {
          $(this).addClass('acl-edit-form-loaded');
          $(this).removeClass('acl-edit-form-loading');
        }).done(function (html) {
          $(this).html(html);
          if (callback) {
            callback.apply(this);
          }
        });
      }
    } else {
      if (callback) {
        callback.apply(this);
      }
    }
  };

  return my;
})(RMPlus.ACL || {});