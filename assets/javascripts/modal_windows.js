$(document).ready(function() {
  $(document.body).on('click', '.link_to_modal:not(.mw-link)', function(e) {
    e.preventDefault();
    $(this).modal_window('click_to_link');
  });
  $(document).ajaxStop(function() {
    // destroy orphans windows (who has no parent link)
    $("body > div.modal_window:not(.mw-dynamic)").modal_window('destroy_if_needed');
  });
});

!function($) {
  "use strict"; // jshint ;_;

  var modal_window = function(element, options) {
    this.current_id = RMPlus.Utils.create_guid();
    this.$element = $(element);
    this.$element.addClass('mw-link');
    this.options = $.extend(true, {}, $.fn.modal_window.defaults, options || {});

    this.loaded = false;

    this.detect_link_options();
    this.detect_modal_window();
    this.detect_mask();

    if (this.options.link_opts.over_parent_window) {
      this.$parent_window = this.$element.closest('div.modal_window');
      if (this.$parent_window.length == 0) {
        this.$parent_window = undefined;
        this.options.link_opts.over_parent_window = false;
      }
    }

    this.visible = false;
    this.loading = false;
    this.listen();
  };

  modal_window.prototype = {
    constructor: modal_window,
    detect_link_options: function() {
      var classes = this.$element.attr('class');
      if (classes && classes.length > 0) {
        classes = classes.split(' ');
        var cl = '';
        for (var sch = 0; sch < classes.length; sch ++) {
          cl = classes[sch].replace('-', '_');
          if (this.options.link_opts[cl] == false) {
            this.options.link_opts[cl] = true;
          }
        }
      }
    },
    detect_modal_window: function() {
      if (this.$window) { return; }

      var $div = this.$element.data('window');

      if (!$div) {
        var id = this.$element.attr('id');
        if (!id || id.length == 0) {
          id = RMPlus.Utils.create_guid();
        }
        $div = $("#modal-" + id);
      }

      if ($div.length == 0) {
        this.$window = $("<div id='modal-" + id + "' class='modal_window" + (this.options.link_opts.click_out ? ' click_out' : '') + "'></div>");
      } else {
        this.$window = $div;
        if (this.$window.text() != '') { this.loaded = true; }
      }

      this._append_mobile_close();

      if (this.options.link_opts.mw_mobile) {
        this.$window.css('z-index', $.fn.modal_window.mobile_z_index);
      } else {
        this.$window.css('z-index', $.fn.modal_window.z_index);
      }
      this.$window.data('modal_window', this);
      $(document.body).prepend(this.$window);
    },
    detect_mask: function() {
      if (this.$mask) { return; }
      this.$mask = $("<div class='mw-drop-mask'></div>");
      $(document.body).prepend(this.$mask);
    },
    listen: function() {
      this.$element.on('click.modal_window', $.proxy(this.click_to_link, this));
      if (!this.options.link_opts.click_out) {
        this.$window.on('mouseleave.modal_window', $.proxy(this.mouse_leave_window, this));
      }
      this.$mask.on('click.modal_window, contextmenu.modal_window', $.proxy(this.hide, this));
      this.$window.on('click.modal_window', '.mw-close', $.proxy(this.hide, this));
      $(window).resize($.proxy(this.window_resize, this));
    },

    // EVENTS //
    click_to_link: function(e) {
      if (e) { e.preventDefault(); }
      this.$window.data('modal_window', this);

      if (this.options.link_opts.refreshable || (!this.loaded && !this.options.link_opts.static_content_only)) {
        this.load();
      } else {
        this.show();
      }
    },
    mouse_leave_window: function(evt) {
      if (evt.target.nodeName.toLowerCase() != 'select' && !$.contains(this.$window[0], evt.target)) {
        this.hide();
      }
    },
    window_resize: function() {
      if (this.visible) {
        this.show();
      }
    },
    // END EVENTS //

    hide_windows: function($parent) {
      $parent = $parent || $(document.body);
      $parent.find('.modal_window:visible').not(this.$window).modal_window('hide');
    },

    show: function() {
      var offset = {};
      if (this.options.link_opts.mw_mobile) {
        offset = this._get_position_mobile();
        this.$window.css('height', offset.height);
        this.$window.css('width', offset.width);
      } else {
        offset = this._get_position();
      }

      this.$window.css('left', offset.left);
      this.$window.css('top', offset.top);
      this.$window.removeClass(this.options.window_top_class + ' ' + this.options.window_bottom_class + ' ' + this.options.window_left_class + ' ' + this.options.window_right_class + ' ' + this.options.window_block_class);
      this.$window.addClass(offset.class_lr).addClass(offset.class_tb).addClass(offset.class_block);

      if (!this.visible) {
        if (this.options.link_opts.over_parent_window) {
          this.$window.zIndex(this.$parent_window.zIndex() + 2);
        }
        this.$window.show().trigger('modal_window_shown');
        this.show_mask();
        this.$element.trigger('modal_window_shown');
        this.visible = true;

        this.$window.find('input, select, textarea').filter(':visible:first').focus();

        if (this.options.link_opts.over_parent_window) {
          this.hide_windows(this.$parent_window);
        } else {
          this.hide_windows();
        }
      }
    },
    hide: function() {
      if (this.visible) {
        this.$window.hide().trigger('modal_window_hidden');
        this.$element.trigger('modal_window_hidden');
        this.hide_mask();
        this.visible = false;
      }
    },
    show_mask: function() {
      if (this.$window.prev()[0] !== this.$mask[0]) {
        this.$window.before(this.$mask);
      }
      this.$mask.zIndex(this.$window.zIndex() - 1);
      this.$mask.css(this._make_mask_css()).addClass('mw-mask-show');

      $(window).on('resize.modal_window.' + this.current_id, $.proxy(function() {
        this.$mask.css(this._make_mask_css());
      }, this));
    },
    hide_mask: function() {
      this.$mask.removeClass('mw-mask-show');
      $(window).off('resize.modal_window.' + this.current_id);
    },
    load: function() {
      if (this.loading) { return; }
      this.loading = true;
      this.append_loader();
      var ajax_params = {};

      if (this.$element[0].tagName == 'A' || this.$element.attr('data-href')) {
        ajax_params.url = this.$element.attr('href') || this.$element.attr('data-href');
        ajax_params.type = (this.$element.attr('data-method') || this.$element.attr('data-modal-method') || '').toUpperCase() || 'GET';
        if (this.$element.attr('data-callback')) {
          var clb = this.$element.attr('data-callback');
          ajax_params.data = eval(clb);
        }
      } else {
        var $frm = this.$element.closest('form');
        ajax_params.url = $frm.attr('action');
        ajax_params.data = $frm.serialize();
        ajax_params.type = ($frm.attr('method') || '').toUpperCase() || 'GET';
      }

      if ($.fn.jquery >= '1.9') {
        ajax_params.method = ajax_params.type;
        delete ajax_params.type;
      }

      $.ajax(ajax_params).always($.proxy(function(html) { this.complete_load(html.responseText || html); }, this));
    },
    append_loader: function() {
      var hide_obj = this.$element;
      if (this.options.link_opts.parent_loader) {
        hide_obj = this.$element.closest('.parent_loader');
      }
      var offset = hide_obj.offset();
      var h = hide_obj.outerHeight();
      var w = hide_obj.outerWidth();
      hide_obj.addClass('invisible_link');
      this.$loader_object = hide_obj;

      if (!this.$loader) {
        this.$loader = $('<div class="mw_loader loader">&nbsp;</div>');
      }
      $(document.body).append(this.$loader);
      this.$loader.css('left', offset.left)
          .css('top', offset.top)
          .css('width', w)
          .css('height', h)
          .show();
    },
    remove_loader: function() {
      if (this.$loader_object) {
        this.$loader_object.removeClass('invisible_link');
        this.$loader_object = undefined;
      }

      if (this.$loader) {
        this.$loader.remove();
      }
    },
    complete_load: function(result_data) {
      this.remove_loader();
      this.$window.html(result_data);
      this._append_mobile_close();
      this.loading = false;
      this.loaded = true;
      this.show();
    },
    destroy_if_needed: function() {
      if (this.$window && this.$element && !$.contains(document.documentElement, this.$element[0])) {
        this.destroy();
      }
    },
    destroy: function() {
      this.$window.remove();
      this.$window = undefined;
      this.$mask.remove();
      this.$mask = undefined;
      this.$element.removeClass('mw-link');
      this.$element.off('.modal_window').removeData('modal_window');
      $(window).off('resize.modal_window.' + this.current_id);
      this.$element = undefined;
    },


    _get_position: function(rect) {
      var scroll = { top: $(document).scrollTop(), left: $(document).scrollLeft() };
      var offset = rect;

      if (!offset) {
        offset = this.$element.offset();
        offset.top = offset.top - scroll.top;
        offset.left = offset.left - scroll.left;
      }

      offset.width = offset.width || this.$element.outerWidth();
      offset.height = offset.height || this.$element.outerHeight();

      var mw_width = this.$window.outerWidth();
      var mw_height = this.$window.outerHeight();
      var doc_w = $(window).outerWidth();
      var doc_h = $(window).outerHeight();
      var margin = 7;

      offset.class_lr = offset.width == 0 ? '' : this.options.window_right_class;
      offset.class_tb = offset.width == 0 ? '' : this.options.window_bottom_class;
      offset.class_block = '';

      if (this.options.link_opts.block_preferred) {
        offset.class_block = this.options.window_block_class;
        if ((this.options.link_opts.left_preferred || doc_w < mw_width + offset.left) && mw_width < offset.left + offset.width) {
          offset.left = offset.left + offset.width + margin;
        } else { offset.width = -margin; }

        if ((this.options.link_opts.top_preferred || doc_h < mw_height + offset.top + offset.height) && mw_height < offset.top) {
          offset.height = 0;
        } else { offset.top = offset.top + offset.height; }
      }

      if ((this.options.link_opts.left_preferred || doc_w < mw_width + offset.left + offset.width + margin) && mw_width < offset.left) {
        // try to display left if preferred left or no space at right
        offset.left = offset.left - margin - mw_width + scroll.left;
        offset.class_lr = this.options.window_left_class;
      } else {
        offset.left = offset.left + offset.width + margin + scroll.left;
      }

      if ((this.options.link_opts.top_preferred || doc_h < offset.top + mw_height - offset.height) && mw_height < offset.top + offset.height) {
        // try to display as preferred no space bottom or top-preferred and
        offset.top = offset.top + scroll.top + offset.height - mw_height;
        offset.class_tb = this.options.window_top_class;
      } else {
        offset.top = offset.top + scroll.top;
      }
      delete offset.width;
      delete offset.height;

      return offset;
    },
    _get_position_mobile: function () {
      var offset = {};

      offset.top = 50;
      offset.left = 0;
      offset.width = $(window).outerWidth();
      offset.height = $(window).outerHeight() - 50;

      offset.class_lr = '';
      offset.class_tb = '';
      offset.class_block = '';

      return offset;
    },
    _append_mobile_close: function () {
      if (this.options.link_opts.mw_mobile) {
        this.$window.addClass('mw-mobile');

        if (this.$window.find('.mw-close').length == 0) {
          this.$window.prepend('<div class="mw-close fa"></div>');
        }
      }
    },
    _make_mask_css: function() {
      return {
        width  : Math.max(document.documentElement.scrollWidth,  $(window).width()),
        height : Math.max(document.documentElement.scrollHeight, $(window).height())
      }
    }
  };

  $.fn.modal_window = function(option) {
    return this.each(function() {
      var $this = $(this)
          , data = $this.data('modal_window')
          , options = typeof option == 'object' && option;
      if (!data) {
        if ($this.hasClass('modal_window')) { return; }
        $this.data('modal_window', (data = new modal_window(this, options)));
      }
      if (typeof option == 'string') { data[option]( ); }
    });
  };

  $.fn.modal_window.defaults = {
    window_top_class: 'mw-top',
    window_bottom_class: 'mw-bottom',
    window_left_class: 'mw-left',
    window_right_class: 'mw-right',
    window_block_class: 'mw-block',
    link_opts: {
      click_out: false,
      over_parent_window: false,
      static_content_only: false,
      refreshable: false,
      parent_loader: false,
      block_preferred: false,
      left_preferred: false,
      top_preferred: false,
      mw_mobile: false
    }
  };
  $.fn.modal_window.z_index = 1100;
  $.fn.modal_window.mobile_z_index = 10000;

  $.fn.modal_window.Constructor = modal_window;
} (window.jQuery);

!function($) {
  "use strict";

  var modal_window_single = function(element, options) {
    this.current_id = RMPlus.Utils.create_guid();
    this.options = $.extend(true, {}, $.fn.modal_window.defaults, options || {});

    this.$window = $(element);
    this.detect_options();

    this._append_mobile_close();

    this.$window.css('z-index', $.fn.modal_window.z_index);
    $(document.body).prepend(this.$window);

    this.detect_mask();

    this.visible = false;
    this.listen();
  };

  modal_window_single.prototype = $.extend({}, $.fn.modal_window.Constructor.prototype, {
    constructor: modal_window_single,
    detect_options: function() {
      var classes = this.$window.attr('class');
      if (classes && classes.length > 0) {
        classes = classes.split(' ');
        var cl = '';
        for (var sch = 0; sch < classes.length; sch ++) {
          cl = classes[sch].replace('-', '_');
          if (cl in this.options.link_opts && this.options.link_opts[cl] == false) {
            this.options.link_opts[cl] = true;
          }
        }
      }
    },
    listen: function() {
      if (!this.options.link_opts.click_out) {
        this.$window.on('mouseleave.modal_window_single', $.proxy(this.mouse_leave_window, this));
      }
      this.$mask.on('click.modal_window_single', $.proxy(this.hide, this));
      this.$window.on('click.modal_window_single', '.mw-close', $.proxy(this.hide, this));
      $(window).resize($.proxy(this.window_resize, this));
    },
    window_resize: function() {
      if (this.visible && this.current_point) {
        this.show(this.current_point);
      }
    },
    show: function(point) {
      this.current_point = point;
      var offset = {};
      if (this.options.link_opts.mw_mobile) {
        offset = this._get_position_mobile();
        this.$window.css('height', offset.height);
        this.$window.css('width', offset.width);
      } else {
        offset = this._get_position( { top: point.top, left: point.left, width: 1, height: 1 } );
      }

      this.$window.css('left', offset.left);
      this.$window.css('top', offset.top);
      this.$window.removeClass(this.options.window_top_class + ' ' + this.options.window_bottom_class + ' ' + this.options.window_left_class + ' ' + this.options.window_right_class + ' ' + this.options.window_block_class);
      this.$window.addClass(offset.class_lr).addClass(offset.class_tb).addClass(offset.class_block);

      if (!this.visible) {
        this.$window.show().trigger('modal_window_shown');
        this.show_mask();
        this.visible = true;

        this.$window.find('input, select, textarea').filter(':visible:first').focus();

        if (this.options.link_opts.over_parent_window) {
          this.hide_windows(this.$parent_window);
          this.$window.zIndex(this.$parent_window.zIndex() + 2);
        } else {
          this.hide_windows();
        }
      }
    },
    hide: function() {
      if (this.visible) {
        this.$window.hide().trigger('modal_window_hidden');
        this.hide_mask();
        this.visible = false;
      }
    },
    destroy_if_needed: function() {
      return false;
    },
    destroy: function() {
      this.$mask.remove();
      this.$mask = undefined;
      this.$window.off('.modal_window_single').removeData('modal_window_single');
      $(window).off('resize.modal_window.' + this.current_id);
      this.$window = undefined;
    }
  });

  $.fn.modal_window_single = function(option) {
    return this.each(function() {
      var $this = $(this)
          , data = $this.data('modal_window_single')
          , options = typeof option == 'object' && option;
      if (!data) {
        $this.data('modal_window_single', (data = new modal_window_single(this, options)));
      }
      if (typeof option == 'string') { data[option]( ); }
    });
  };

  $.fn.modal_window_single.Constructor = modal_window_single;
} (window.jQuery);