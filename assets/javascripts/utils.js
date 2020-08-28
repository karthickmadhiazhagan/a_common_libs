if (!Array.prototype.indexOf) {
  Array.prototype.indexOf = function (searchElement, fromIndex) {
        for(var i = fromIndex||0, length = this.length; i<length; i++)
            if(this[i] === searchElement) return i;
        return -1
  };
}


// jQuery plugin to change the type of the html element easily
(function ($) {
    $.fn.changeElementType = function (newType) {
        var attrs = {};

        $.each(this[0].attributes, function (idx, attr) {
            attrs[attr.nodeName] = attr.nodeValue;
        });

        this.replaceWith(function () {
            return $("<" + newType + "/>", attrs).append($(this).contents());
        });
    };
    $.fn.isNumber = function (n) {
      return !isNaN(parseFloat(n)) && isFinite(n);
    }
})(jQuery);

// jQuery plugin to get string representation of the element
(function ($) {
  $.fn.outerHTML = function () {
    return $(this).clone().wrap('<div></div>').parent().html();
  }
})(jQuery);

// usage:
// var visible = TabIsVisible(); // gives current state
// TabIsVisible(function(){ // registers a handler for visibility changes
//  document.title = vis() ? 'Visible' : 'Not visible';
// });
var TabIsVisible = (function () {
    var stateKey,
        eventKey,
        keys = {
                hidden: "visibilitychange",
                webkitHidden: "webkitvisibilitychange",
                mozHidden: "mozvisibilitychange",
                msHidden: "msvisibilitychange"
    };
    for (stateKey in keys) {
        if (stateKey in document) {
            eventKey = keys[stateKey];
            break;
        }
    }
    return function (c) {
        if (c) document.addEventListener(eventKey, c);
        return !document[stateKey];
    }
})();

// Useful utility functions
RMPlus.Utils = (function (my) {
  var my = my || {};

  my.uniq_id = function () {
    var d = new Date();
    var r = Math.random().toString().split('.')[1];
    rm_id = d.getHours().toString()+d.getMinutes().toString()+d.getSeconds().toString()+d.getMilliseconds().toString()+'-'+r;
    return rm_id;
  };

  // function checks existence of the property in the RMPlus namespace recursively
  my.exists = function (prop) {
    obj = RMPlus;
    var parts = prop.split('.');
    for (var i = 0, l = parts.length; i < l; i++) {
      var part = parts[i];
      if (obj !== null && typeof obj === "object" && part in obj) {
          obj = obj[part];
      }
      else {
          return false;
      }
    }
    return true;
  };

  // useful functions to decorate autocomplete handlers, etc.
  // see http://habrahabr.ru/post/60957/  (rus),
  // http://drupalmotion.com/article/debounce-and-throttle-visual-explanation (eng) for more info
  my.debounce = function (delay, fn) {
    var timer = null;
    return function () {
      var context = this, args = arguments;
      clearTimeout(timer);
      timer = setTimeout(function () {
        fn.apply(context, args);
      }, delay);
    };
  };

  my.throttle = function (threshhold, fn, scope) {
    threshhold || (threshhold = 250);
    var last, deferTimer;
    return function () {
      var context = scope || this;
      var now = +new Date, args = arguments;
      if (last && now < last + threshhold) {
        clearTimeout(deferTimer);
        deferTimer = setTimeout(function () {
          last = now;
          fn.apply(context, args);
        }, threshhold);
      } else {
        last = now;
        fn.apply(context, args);
      }
    };
  };

  my.async_tab_load = function(tab, tab_content, url) {
    tab.attr('data-remote', 'true');
    tab.attr('href', url).click(function() {
      if (tab_content.attr('data-loaded')) {
        $(this).removeAttr('data-remote');
        return;
      }
      tab_content.attr('data-loaded', 1);
    });
  };

  my.append_fast_links = function() {
    var $link = $('<a href="#" class="icon icon-edit rmp-fast-link no_line" target="_blank"></a>');

    $('select.rmp-fast-edit').each(function() {
      var $this = $(this);

      if ($this.data('rmp-fast-link')) { return; }

      var $lnk = $link.clone();
      if ($this.hasClass('select2-hidden-accessible')) {
        $this.data('rmp-fast-link', $lnk).next().after($lnk);
      } else {
        $this.after($lnk).data('rmp-fast-link', $lnk);
      }

      if ($this.attr('modal')) {
        $lnk.addClass('link_to_modal click_out refreshable');
      }
    }).trigger('change');
  };


  my.get_params_from_url = function(url){
    // This function is anonymous, is executed immediately and
    // the return value is assigned to QueryString!
    var query_string = {};
    if(url === "undefined" || url == undefined){
      var query = window.location.search.substring(1);
    }
    else{
      var query = url.split('?')[1];
    }
    var vars = query.split("&");
    for (var i=0;i<vars.length;i++) {
      var pair = vars[i].split("=");
          // If first entry with this name
      if (typeof query_string[pair[0]] === "undefined") {
        query_string[pair[0]] = decodeURIComponent(pair[1]);
          // If second entry with this name
      } else if (typeof query_string[pair[0]] === "string") {
        var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
        query_string[pair[0]] = arr;
          // If third or later entry with this name
      } else {
        query_string[pair[0]].push(decodeURIComponent(pair[1]));
      }
    }
    return query_string;
  };

  my.create_guid = function() {
    var dt = new Date( ).getTime( );
    var gd = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = (dt + Math.random() * 16) % 16 | 0;
      dt = Math.floor(dt / 16);
      return (c == 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
    return gd;
  };

  my.acl_upload_icon = function (acl_icon) {
    if (!acl_icon.id) return acl_icon.text; // optgroup

    var css_classes = acl_icon.id.toLowerCase();
    if ((/^fa-/).test(acl_icon.id)){
        css_classes += ' rm-icon';
    }
    return "<span class='lu_img no_redirect " + css_classes + "' href='#' style='border-bottom: none;'>" + acl_icon.text + "</span>";
  };

  my.find_upload_css_styles = function(exclude_fonts, only_font_awesome) {
    var btnClasses = [];
    var sSheetList = document.styleSheets;
    for (var i = 0; i < sSheetList.length; i++) {
      var ruleList = document.styleSheets[i].cssRules;
      for (var rule = 0; rule < ruleList.length; rule++) {
        if (typeof ruleList[rule].selectorText != 'undefined') {
          if(only_font_awesome){
              var regex = /\.fa-(.*):before/;
          }else{
              var regex = exclude_fonts ? /(^\.sd_btn_)|(^\.lb_btn_)|(^\.acl_icon_)/ : /(^\.sd_btn_)|(^\.lb_btn_)|(^\.acl_icon_)|\.fa-(.*):before/;
          }
          if (regex.test(ruleList[rule].selectorText)) {
            btnClasses.push(ruleList[rule].selectorText.split('::before')[0]);
          }
        }
      }
    }
    return btnClasses;
  };

  my.acl_prepare_css_styles = function(css_select, exclude_fonts, only_font_awesome) {
    var css_classes = my.find_upload_css_styles(exclude_fonts, only_font_awesome);
    var orig_value = css_select.val();
    for (var s=0; s<css_classes.length; s++) {
        var css_name = css_classes[s].split('.')[1];
        var clear_name = css_name.split(/sd_btn_|lb_btn_|acl_icon_/);
        clear_name = (clear_name.length == 2) ? clear_name[1] : clear_name[0];
        if (css_select.find("option[value='"+css_name+"']").length == 0 ) {
            css_select.append($('<option></option>').val(css_name).html(clear_name).attr('data-test', 1));
        }
    }

    var css_options = css_select.find('option').sort(function (a,b) {
        if ($(a).val() > $(b).val()) return 1;
        else if ($(a).val() < $(b).val()) return -1;
        else return 0
    });

      css_select.empty().append(css_options);

    css_select.val(orig_value);
  };

  my.wordwrap = function(str, width, brk) {
    brk = brk || '\n';
    width = width || 75;

    if (!str) { return str; }

    var regex = '.{1,'  + width + '}(\\s|$)|\\S+?(\\s|$)';

    return str.match(RegExp(regex, 'g')).join(brk);
  };

  my.image_by_css = function(css) {
    var $obj = $('<span class="' + css + '"></span>');
    $(document.body).append($obj);
    var bg = $obj.css('background-image');
    if (bg == 'none') {
      return '';
    }
    $obj.remove();
    return bg.replace('url(','').replace(')','').replace(/\"/gi, '');
  };

  my.paste_text_to_textarea = function(e, value) {
    var scrollPos = e.scrollTop;
    var method = ((e.selectionStart || e.selectionStart == '0') ? 1 : (document.selection ? 2 : false));
    var strPos;
    if (method === 2) {
      e.focus();
      var range = document.selection.createRange();
      range.moveStart('character', -e.value.length);
      strPos = range.text.length;
    }
    else if (method === 1) {
      strPos = e.selectionStart;
    }

    var front = (e.value).substring(0, strPos);
    var back = (e.value).substring(strPos, e.value.length);
    e.value = front + value + back;
    strPos = strPos + value.length;
    if (method === 2) {
      e.focus();
      var range = document.selection.createRange();
      range.moveStart('character', -e.value.length);
      range.moveStart('character', strPos);
      range.moveEnd('character', 0);
      range.select();
    } else if (method === 1) {
      e.selectionStart = strPos;
      e.selectionEnd = strPos;
      e.focus();
    }
    e.scrollTop = scrollPos;
  };

  my.seconds_to_string = function(seconds, options) {
    var days_lbl = '', with_days, blank, truncate_zeros;
    if (options) {
      days_lbl = options.days_lbl;
      with_days = options.day_include;
      blank = options.blank;
      truncate_zeros = options.truncate_zeros;
    } else {
      blank = '&times;';
    }

    if (!seconds || seconds <= 0) {
      return blank;
    }
    seconds = Math.floor(seconds);

    var parts = [86400, 3600, 60, 1];
    var result = '';

    if (!with_days) {
      parts[0] = null;
    }

    var mul = null,
        all_blank = true,
        was_zeros = truncate_zeros;

    for (var sch = 0; sch < 4; sch ++) {
      mul = parts[sch];
      if (mul) {
        parts[sch] = Math.floor(seconds / mul);
        seconds = Math.floor(seconds - parts[sch] * mul);
      }

      if (sch === 0 && !parts[sch]) {
        parts[sch] = null;
      }

      if (was_zeros) {
        if (parts[sch] === null || parts[sch] <= 0) {
          parts[sch] = null;
        } else {
          was_zeros = false;
        }
      }

      if (parts[sch] !== null && sch > 0 && !all_blank) {
        if (parts[sch] < 10) {
          parts[sch] = '0' + parts[sch].toString();
        } else {
          parts[sch] = parts[sch].toString();
        }
      }

      if (all_blank && parts[sch]) {
        all_blank = false;
      }

      if (parts[sch]) {
        result += parts[sch];
        if (sch === 0) {
          result += days_lbl + ' ';
        } else if (sch < 3) {
          result += ':';
        }
      }
    }

    if (all_blank) {
      return blank;
    } else {
      return result || blank;
    }
  };

  my.number_format = function(num, round) {
    if (!round && round !== 0) {
      round = 2;
    }
    var m = Math.pow(10, round);
    num = Math.round(num * m) / m;
    num = num.toString();

    var p = num.split(/\.|\,/);
    if (p.length === 2) {
      while (p[1][p[1].length - 1] === '0') {
        p[1] = p[1].substring(0, p[1].length - 1);
      }

      if (p[1].length > round) {
        p[1] = p[1].substring(0, round);
      }
    }

    if (p[0].length > 3) {
      p[0] = p[0].replace(/(\d)(?=(\d\d\d)+([^\d]|$))/g, '$1 ')
    }

    if (p.length === 1 || !p[1]) {
      return p[0];
    } else {
      return p[0] + '.' + p[1];
    }
  };

  my.set_interval = function(value, options) {
    var scope = options.scope || this,
        interval = options.interval,
        on_tick_callback = options.tick;

    return setInterval(function(context) {
      value = on_tick_callback.call(context, value);
    }, interval, scope);
  };

  my.set_timer = function(seconds, options) {
    var scope = this,
        on_tick_callback,
        on_complete_callback;
    if (options) {
      scope = options.scope;
      on_tick_callback = options.tick;
      on_complete_callback = options.complete
    }

    if (!seconds || isNaN(seconds) || seconds <= 0) {
      if (on_tick_callback) {
        on_tick_callback.call(scope, 0);
      }
      if (on_complete_callback) {
        on_complete_callback.call(scope);
      }
      return;
    }

    if (on_tick_callback) {
      on_tick_callback.call(scope, seconds);
    }

    var interval_pointer = my.set_interval(seconds, {
      scope: scope,
      interval: 1000,
      tick: function (vl) {
        vl -= 1;

        if (on_tick_callback) {
          on_tick_callback.call(this, vl);
        }

        if (vl <= 0) {
          if (on_complete_callback) {
            on_complete_callback.call(this);
          }
          clearInterval(interval_pointer);
        }
        return vl;
      }
    });
    return interval_pointer;
  };

  my.create_bootstrap_modal = function($elem, ajax) {
    var id = $elem.attr('id');
    var target = $elem.attr('data-target') || (id ? ('modal-' + id) : 'form_ajax');
    var $target;
    if (target === 'current') {
      $target = $elem.closest('.modal');
    } else {
      $target = $('#' + target);
    }
    if ($target.length === 0) {
      $target = $('<div id="' + target + '" class="modal I fade" role="dialog" aria-hidden="true" data-height="90%" style="z-index: 1060;"></div>');
      $(document.body).prepend($target);
    } else {
      $target.removeAttr('data-width');
      $target.removeAttr('data-fixed-height');
      $target.attr('data-height', '90%');
    }

    if ($elem.hasClass('acl-user-modal')) {
      $target.html('<div class="big_loader form_loader"></div>');
      $target.attr('data-width', '70%');
      $target.attr('data-height', '80%');
    } else {
      if (ajax) {
        $target.html('<div class="loader form_loader"></div>');
      }
      var width = $elem.attr('data-width');
      var height = $elem.attr('data-height');
      var fixed_height = $elem.attr('data-fixed-height');
      if (width) {
        $target.attr('data-width', width);
      } else if (!$target.attr('data-width')) {
        $target.attr('data-width', '1050px');
      }
      if (height) {
        $target.attr('data-height', height);
      }
      if (fixed_height) {
        $target.attr('data-fixed-height', fixed_height);
      }
    }

    return $target;
  };

  my.replace_with_loader = function($elem) {
    if (!$elem || $elem.length === 0) {
      return;
    }
    if ($elem.get(0).tagName === 'FORM') {
      $elem = $elem.find(':submit');
    }

    if ($elem && $elem.length > 0) {
      if ($elem.hasClass('acl-fake-ajax-hidden')) {
        return;
      }
      var tag = 'div';
      if ($elem.get(0).tagName === 'BUTTON') {
        tag = 'button';
      }
      $elem.after('<' + tag + ' class="loader acl-fake-ajax-loader" style="width:'+$elem.outerWidth().toString()+'px; height: '+$elem.outerHeight().toString()+'px;">&nbsp;</' + tag + '>');
      $elem.addClass('acl-fake-ajax-hidden');
      $elem.hide();
    }
  };
  my.restore_with_loader = function($elem) {
    $('.acl-fake-ajax-loader').remove();
    $elem.removeClass('acl-fake-ajax-hidden');
    $elem.show();
  };

  return my;
})(RMPlus.Utils || {});


$(document).ready(function () {

  $(document.body).on('change', 'select.rmp-fast-edit', function () {
    var $this = $(this);
    var sb_val = $this.val();
    if (parseInt(sb_val)) {
      var edit_field = $this.attr('data-edit-url').split('0').join(sb_val);
      $this.data('rmp-fast-link').attr('href', edit_field);
    } else {
      var new_field =  $this.attr('data-add-url');
      $this.data('rmp-fast-link').attr('href', new_field);
    }
  });
  RMPlus.Utils.append_fast_links();

  $(document.body).on('click', '#acl-icons-select', function(e) {
    $('#acl-icon-files').trigger('click');
    e.preventDefault();
    return false;
  });

  $(document.body).on('change', '#acl-icon-files', function() {
    if (!this.files || this.files.length == 0) {
        alert(this.getAttribute('data-no-files'));
        return;
    }

    var $container = $('#acl-upload-icons');
    $container.find('.thumbnails').remove();
    $container.hide().parent().prepend('<div class="loader"></div>');
    $('#acl-icons-submit').prop('disabled', true);
    $('#errorExplanation').remove();

    var files = 0;
    var errors = '';
    var max_resolution = (this.getAttribute('data-resolution') || '').split('x');

    var acl_upload_icons_append_thumbnail = function(img) {
        var $thumbnails_container = $container.find('.thumbnails');
        if ($thumbnails_container.length == 0) {
            $thumbnails_container = $('<div class="thumbnails"></div>');
            $container.append($thumbnails_container);
        }
        $thumbnails_container.append('<div class="lb-attach-cont"><div class="lb-attach-bg" style="display: block; background-image: url(' + img.src + '); background-repeat: no-repeat; width: ' + max_resolution[0] + 'px; height: ' + max_resolution[1] + 'px;"></div></div>');
    };

    var acl_upload_icons_complete_check = function() {
        $container.show().parent().find('.loader').remove();
        $('#acl-icons-submit').prop('disabled', $container.find('.thumbnails .lb-attach-cont').length == 0);
        if (errors && errors.length > 0) {
            $container.parents('.modal-body').prepend('<div id="errorExplanation"><ul>' + errors + '</ul></div>');
        }
    };

    var acl_upload_icons_check_resolution = function(file) {
        var fr = new FileReader;
        fr.onload = function() {
            var img = new Image;

            img.onload = function() {
                var $files_field = $('#acl-icon-files');
                if (this.width > max_resolution[0] || this.height > max_resolution[1]) {
                    errors += '<li>' + this.file.name + ' - ' + $files_field.attr('data-resolution-exceed') + '</li>';
                } else {
                    acl_upload_icons_append_thumbnail(this);
                    this.file.valid = true;
                }
                files += 1;
                if (files == $files_field.get(0).files.length) {
                    files = -1;
                    acl_upload_icons_complete_check();
                }
            };
            img.file = this.file;
            img.src = this.result;
        };
        fr.file = file;
        fr.readAsDataURL(file);
    };

    var accepted = this.getAttribute('accept').split(',') || [];

    for (var sch = 0; sch < this.files.length; sch ++) {
        var ext = (this.files[sch].name.split('.') || []).pop();

        if (accepted.indexOf(this.files[sch].type) == -1 && accepted.indexOf(ext) == -1 && accepted.indexOf('image/' + ext) == -1) {
            errors += '<li>' + this.files[sch].name + ' - ' + this.getAttribute('data-not-available-ext') + '</li>';
            files += 1;
        } else if (this.files[sch].size > parseInt(this.getAttribute('data-filesize'))) {
            errors += '<li>' + this.files[sch].name + ' - ' + this.getAttribute('data-filesize-exceed') + '</li>';
            files += 1;
        } else {
            acl_upload_icons_check_resolution(this.files[sch]);
        }
    }
    if (files == this.files.length) {
        files = -1;
        acl_upload_icons_complete_check();
    }
  });

  $(document.body).on('click', '#acl-icons-submit', function() {
    var $this = $(this);
    $this.after('<div class="loader" style="width:' + $this.outerWidth().toString()+'px; height: ' + $this.outerHeight().toString() + 'px;"></div>');
    $this.hide();
    $this.parents('.modal:first').find(':input').prop('disabled', true);
    $(document.body).data('acl_icon_upload_icons', $this);
    $('#errorExplanation').remove();

    var $files_field = $('#acl-icon-files');
    var files = $files_field.get(0).files;
    var available_files = [];
    var url = $files_field.attr('data-upload-url');
    var uploaded = 0;
    var errors = '';
    var css_link = '';

    var acl_upload_complete = function(container) {
        if (uploaded >= available_files.length) {
            uploaded = -1;
            $(document.body).data('acl_icon_upload_icons').show().nextAll('.loader').remove();
            var $container = container;
            $container.find(':input').prop('disabled', false);
            if (errors && errors.length > 0) {
                $container.find('.modal-body').prepend('<div id="errorExplanation"><ul>' + errors + '</ul></div>');
            } else {
                $('#content').find('.flash').remove();
                $('#content').prepend('<div class="flash notice">' + $files_field.attr('data-success') +'</div>');
                $container.modal('hide');
            }

            if (css_link) {
                $('#acl-generated-icons').remove();
                $(document.head).append(css_link);
            }
        }
    };

    var acl_upload_icon = function(url, file) {
        var form_data = new FormData();
        form_data.append('css_icon', file);

        $.ajax({ type: 'POST', url: url, processData: false, contentType: false, data: form_data }).done(function(txt) {
            css_link = txt;
        }).fail(function(txt) {
            if (txt && txt.responseText.length > 0) {
                errors += '<li>' + txt.responseText + '</li>';
            }
        }).always(function() {
            uploaded ++;
            acl_upload_complete($("form[action='"+url+"']").parent().parent());
        });
    };

    var sch = 0;
    for (sch = 0; sch < files.length; sch ++) {
        if (files[sch].valid) {
            available_files.push(files[sch]);
        }
    }

    for (sch = 0; sch < available_files.length; sch++) {
        acl_upload_icon(url, available_files[sch]);
    }

    acl_upload_complete($("form[action='"+url+"']").parent().parent());
  });

  $(document.body).on('click', '.acl_ajax_edit', function () {
    var static = this.getAttribute('data-static');
    var form_div = RMPlus.Utils.create_bootstrap_modal($(this), !static);
    form_div.modal('show');

    var url = this.tagName == 'A' ? this.href : this.getAttribute('data-url');
    var data = eval(this.getAttribute('data-callback'));
    if (!static && url && url !== '#') {
      form_div.load(url, data, function () {
        $('.tabs-buttons').hide();
        RMPlus.LIB.resize_bs_modal(form_div);
      });
    }
    return false;
  });

  $(document.body).on('click', '.acl-tree-list.acl-remote-reloadable ul li a, .acl-split-container a.acl-remote-reloadable', function() {
    var $this = $(this);

    if ($this.hasClass('selected')) { return false; }

    $('.acl-split-container .acl-fullscreen-loading-mask').remove();
    $('.acl-split-container').prepend("<div class='acl-fullscreen-loading-mask'><div class='form_loader big_loader'></div></div>");

    $.ajax({
      method: 'GET',
      url: this.href,
      context: this
    }).done(function(data) {
      $('.acl-split-right').html('').append(data);
      $('.acl-split-left a.selected').removeClass('selected');
      $(this).addClass('selected');
    }).always(function() {
      $('.acl-fullscreen-loading-mask').remove();
    });
    return false;
  });

  $(document.body).on('click', '.acl-tree-list ul li, .acl-tree-list ul', function (e) {
    var $this = $(this);
    if ($this.hasClass('acl-tree-parent')) {
      $this.toggleClass('closed');
    }
    e.stopPropagation();
  });

  $(document.body).on('click', '.acl-tree-list ul li a, .acl-tree-list ul a', function (e) {
    e.stopPropagation();
  });

  $(document.body).on('click', '.acl-macros-list legend', function() {
    $(this).closest('.acl-macros-list').toggleClass('closed');
  });

  $(document.body).on('click', '.acl-macros-list .acl-macros-item td', function() {
    var $this = $(this),
        macros_text = $this.closest('.acl-macros-item').find('.acl-macros-text').html(),
        field = $(this).closest('.acl-macros-list').attr('data-field');

    if (field) {
      field = $(field);
    } else {
      field = $(this).closest('form').find('.acl-macros-target');
    }
    if (field.length) {
      RMPlus.Utils.paste_text_to_textarea($(field).get(0), macros_text);
    }
  });

  $(document.body).on('click', '.acl-expander .acl-expander-handler', function(e) {
    var $expander = $(this).closest('.acl-expander');
    var url = $expander.attr('data-url');
    if (url && !$expander.hasClass('acl-expander-loaded')) {
      $expander.toggleClass('open').addClass('acl-expander-loading');
      var $data = $expander.find('.acl-expander-data');
      $.ajax({
        method: 'GET',
        url: url
      }).done(function (data) {
        $data.html(data);
      }).always(function () {
        $expander.addClass('acl-expander-loaded').removeClass('acl-expander-loading')
      });
    } else {
      $expander.toggleClass('open');
    }
    e.preventDefault();
  });

  $(document.body).on('change', '.acl-file-upload', function() {
    var max_file_size = parseInt(this.getAttribute('data-max-file-size')) || 1024;
    if (this.files && this.files.length == 1) {
      if (this.files[0].size > max_file_size) {
        alert(this.getAttribute('data-max-file-size-message'));
        $(this).val('');
        return false;
      }
      var accept_exts = this.getAttribute('data-accept');
      if (accept_exts) {
        if (this.files[0].name.search(new RegExp('\\.(' + accept_exts + ')$', 'i')) == -1) {
          alert(this.getAttribute('data-wrong-file-extension-message'));
          $(this).val('');
          return false;
        }
      }
    }
  });

  (function() {
    var fake_ajax_handler = function (e, confirm) {
      if (e.type === 'confirm:complete' && !confirm) {
        return;
      }
      RMPlus.Utils.replace_with_loader($(this));
    };

    $(document.body).on('submit', '.acl-fake-ajax', fake_ajax_handler);
    $(document.body).on('click', 'a.acl-fake-ajax:not([data-confirm])', fake_ajax_handler);
    $(document.body).on('confirm:complete', 'a.acl-fake-ajax[data-confirm]', fake_ajax_handler);

  })();
});



