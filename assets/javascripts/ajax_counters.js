RMPlus.ACL = (function(my){
  var my = my || {};

  my.expired_ajax_counters = [];

  my.refresh_ajax_counters = function() {
    if (my.expired_ajax_counters && my.expired_ajax_counters.length > 0) {
      var last_expired = my.expired_ajax_counters;
      $.ajax({ url: RMPlus.Utils.relative_url_root + '/ajax_counters/counters',
        type: 'post',
        dataType: 'json',
        data: { counters: my.expired_ajax_counters }
      }).done(function(data) {
        if (data) {
          var key, cnt;
          for (var sch = 0, l = last_expired.length; sch < l; sch ++) {
            key = last_expired[sch];
            cnt = data[key] || '';
            my.draw_counter(key, cnt);
            delete data[key];
          }
          for (key in data) {
            my.draw_counter(key, data[key]);
          }
        }
      }).always(function() {
        $(document.body).trigger('ac:refresh_complete');
      });

      my.expired_ajax_counters = [];
    } else {
      $(document.body).trigger('ac:refresh_complete');
    }
  };

  my.draw_counter = function(counter_id, counter) {
    var c = (counter == 0 || counter == '0') ? '' : counter;
    $('.ac_counter[data-id="' + counter_id + '"]').html(c);
  };

  my.prepare_counters = function(session_stored_counters) {
    $('.ac_counter').each(function() {
      var $this = $(this);
      var counter_id = $this.attr('data-id');

      if (counter_id) {
        if (session_stored_counters && (session_stored_counters[counter_id] || session_stored_counters[counter_id] === 0)) {
          my.draw_counter(counter_id, session_stored_counters[counter_id]);
        } else if (my.expired_ajax_counters.indexOf(counter_id) < 0) {
          my.expired_ajax_counters.push(counter_id);
        }
      }
    });
  };

  my.initialize = function(session_stored_counters) {
    $(document).ready(function() {
      my.prepare_counters(session_stored_counters);
      my.refresh_ajax_counters();
    });
  };

  return my;
})(RMPlus.ACL || {});

$(document).ready(function () {
  $(document.body).on('click', '.ac_refresh', function () {
    RMPlus.ACL.expired_ajax_counters = [];
    $('.ac_refresh').hide();
    $('<div class="loader ac_preloader"></div>').insertAfter($(this));
    RMPlus.ACL.prepare_counters({});
    RMPlus.ACL.refresh_ajax_counters();
    return false;
  });

  $(document.body).on('ac:refresh_complete', function () {
    $('.ac_preloader').remove();
    $('.ac_refresh').show();
  });
});