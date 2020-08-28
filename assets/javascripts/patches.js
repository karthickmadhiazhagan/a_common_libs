
// Rewrite of the redmine 'observeSearchfield' function from application.js
// Avoids checking for input value in a loop, shorter and cleaner code
//
// Note the event handler function is wrapped in RMPlus.Utils.debounce function call.
// debounce is deferring function execution for amount of milliseconds specified in the first argument
// As a result, autocomplete behaviour is more user-friendly, and it avoids doing useless checks and
// requests to server while the user is still typing.
!(function($){
  if ($.fn.popover) {
    $.fn.popover.Constructor.prototype.applyPlacement = function (offset, placement) {

      var $tip = this.tip()
          , width = $tip[0].offsetWidth
          , height = $tip[0].offsetHeight
          , actualWidth
          , actualHeight
          , delta
          , replace

      $tip
          .offset(offset)
          .addClass(placement)
          .addClass('in')

      actualWidth = $tip[0].offsetWidth
      actualHeight = $tip[0].offsetHeight

      if (placement == 'top' && actualHeight != height) {
        offset.top = offset.top + height - actualHeight
        replace = true
      }

      if (placement == 'bottom' || placement == 'top') {
        delta = 0

        if (offset.left < 0) {
          delta = offset.left * -2
          offset.left = 0

          $tip.css({left: 0})

          actualWidth = $tip[0].offsetWidth
          actualHeight = $tip[0].offsetHeight
        }

        this.replaceArrow(delta - width + actualWidth, actualWidth, 'left')
      } else {
        this.replaceArrow(actualHeight - height, actualHeight, 'top')
      }

      if (replace) $tip.offset(offset)
    };

    $.fn.popover.Constructor.prototype.replaceArrow = function (delta, dimension, position) {
      this
          .arrow()
          .css(position, delta ? (50 * (1 - (delta + this.arrow()[0].offsetWidth) / dimension) + "%") : '')
    };

    $.fn.popover.Constructor.prototype.old_init = $.fn.popover.Constructor.prototype.init;
    $.fn.popover.Constructor.prototype.init = function (type, element, options) {
      var res = this.old_init(type, element, options);
      if (options && options.resize_elem) {
        var v_this = this;
        $(options.resize_elem).on('resize', function () {
          if (v_this.tip().hasClass('in')) v_this.show();
        });
      }
      return res;
    };
  }
})(window.jQuery);

(function(){

  // store original reference to the method, may be useful for future refactoring
  var showTab_without_patches  = showTab;

  showTab = function (name, url, container) {
    var $tab = $('#tab-' + name);
    container = (typeof container == 'undefined' ? 'div.tabs' : container.toString( ));
    var $par_ul = $tab.parents(container).first();
    $par_ul.find('li a').each(function (index) {
      $(this).removeClass('selected');
      var tab_name = $(this).attr('id').split('tab-')[1];
      // console.log(tab_name)
      $('#tab-content-' + tab_name).hide();
    });
    $('#tab-content-' + name).show();
    $tab.addClass('selected');
    $('#tab-content-' + name + ' a[id^="mod-w"]').each(function(){
      this.id = this.id.slice(0,-this.id.split('-').slice(-1)[0].length)+name;
    });
    //replaces current URL with the "href" attribute of the current link
    //(only triggered if supported by browser)
    // if ('replaceState' in window.history) {
    //   window.history.replaceState(null, document.title, url);
    // }

    var loc = location.href.split('#');
    var loc_tabbed = loc[0].split('tab=');
    var loc_clear = loc_tabbed[0];
    if (loc_tabbed.length>1) {
      var loc_vars = loc_tabbed[1].split('&')
      for (var l=1;l<loc_vars.length; l++) {
        loc_clear = loc_clear+'&'+loc_vars[l];
      }
    }

    if (loc_clear[loc_clear.length-1] == '?' || loc_clear[loc_clear.length-1] == '&') {
      loc_clear = loc_clear.substring(0, loc_clear.length - 1)
    }

    var q_pos = loc_clear.indexOf('?');
    if (q_pos == -1) {
      loc_clear = loc_clear + '?tab=' + name;
    } else {
      loc_clear = loc_clear + '&tab=' + name;
    }
    if ('replaceState' in window.history) {
      window.history.replaceState(null, document.title, loc_clear);
    }
    return false;
  }

  var observeSearchfield_without_patches = observeSearchfield;

  observeSearchfield = function(fieldId, targetId, url){
    $('body').on('keyup click mousemove', '#' + fieldId, RMPlus.Utils.debounce(300, function(){
      var $this = $(this);
      $this.addClass('autocomplete');
      // console.log('good function!');
      var value = $this.val();
      var old_value = $this.attr('data-value-was');
      if (value !== old_value) {
        $this.attr('data-value-was', value);
        $.ajax({
          url: url,
          type: 'get',
          data: {q: value},
          success: function(data){ if (targetId) $('#'+targetId).html(data); },
          beforeSend: function(){ $this.addClass('ajax-loading'); },
          complete: function(){ $this.removeClass('ajax-loading'); }
        });
      }
    }));
  };


  if (window['jsToolBar']) {
    jsToolBar.prototype.old_showPreview = jsToolBar.prototype.showPreview;
    jsToolBar.prototype.showPreview = function(event) {
      if (event.target.tagName === 'LI') {
        return;
      }
      if (event.target.tagName === 'SPAN') {
        event.target = event.target.parentNode;
        Object.defineProperty(event, 'target', { value: event.target.parentNode, enumerable: true });
      }
      jsToolBar.prototype.old_showPreview.call(this, event);
    }
  }
})();

$(document).ready(function () {
  $('#content').off('click', 'div.jstTabs a.tab-preview');
  $(document.body).on('click', 'div.jstTabs a.tab-preview', function(event) {
    var tab = $(event.target);

    var url = tab.data('url');
    var form = tab.parents('form');
    var jstBlock = tab.parents('.jstBlock');

    var element = encodeURIComponent(jstBlock.find('.wiki-edit').val());
    var attachments = form.find('.attachments_fields input').serialize();


    jstBlock.find('.wiki-preview').addClass('loading').html('<div class="form_loader big_loader"></div>');
    jstBlock.find('.wiki-preview').height(jstBlock.find('.wiki-edit').height());
    $.ajax({
      url: url,
      type: 'post',
      data: "text=" + element + '&' + attachments,
      success: function(data) {
        jstBlock.find('.wiki-preview').removeClass('loading');
        jstBlock.find('.wiki-preview').html(data);
      }
    });

    return false;
  });
});