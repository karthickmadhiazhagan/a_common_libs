if ($.fn.select2) {
  $.fn.select2.defaults.set("placeholder", ' ');
  $.fn.select2.amd.require('select2/data/select').prototype.query = function (params, callback) {
    var data = [];
    var self = this;
    var term = params.term || '';
    var ary = term.split(';');
    var $options = this.$element.children();

    if (ary.length > 1) {
      data = this.$element.val() || [];
      $options.each(function () {
        var $option = $(this);

        if (!$option.is('option') && !$option.is('optgroup')) {
          return;
        }

        var option = self.item($option);

        for (var sch = 0; sch < ary.length; sch ++) {
          var tmp_term = $.trim(ary[sch]);
          if (!tmp_term) {
            continue;
          }
          var matches = self.matches({ term: tmp_term }, option);

          if (matches !== null) {
            if (matches.children) {
              for (var sch2 = 0; sch2 < matches.children.length; sch2++) {
                data.push(matches.children[sch2].id);
              }
            } else {
              data.push(matches.id);
            }
          }
        }
      });
      this.$element.val(data);
      this.$element.trigger('change');
      this.container.trigger('close', {});
    } else {
      $options.each(function () {
        var $option = $(this);

        if (!$option.is('option') && !$option.is('optgroup')) {
          return;
        }

        var option = self.item($option);

        var matches = self.matches(params, option);

        if (matches !== null) {
          data.push(matches);
        }
      });

      callback({
        results: data
      });
    }
  };

  (function ($, undefined) {
    $.fn.select2.defaults.templateSelection = function (selection) {
      return selection && (!Array.isArray(data) || data.length > 0) ? selection.text : undefined;
    }
  }(jQuery));

  $.fn.select2.amd.define('select2/data/ajax-adapter-with-defaults', [
        './ajax',
        '../utils',
        'jquery',
        'select2/data/maximumInputLength',
        'select2/data/maximumSelectionLength',
        'select2/data/tags',
        'select2/data/tokenizer'
      ],
      function(AjaxAdapter, Utils, $, MaximumInputLength, MaximumSelectionLength, Tags, Tokenizer) {
        function AjaxAdapterWithDefaults ($element, options) {

          function TmpAdapter() {
            this.minimumInputLength = options.get('minimumInputLength');
            this.defaultResults = options.get('defaultResults');

            TmpAdapter.__super__.constructor.call(this, $element, options);

            var self = this;
            var data = [];
            if (!this.defaultResults) {
              if (options.options.ajax.defaultData && options.options.ajax.defaultData.length) {
                data = options.options.ajax.defaultData;
                this.addOptions(this.convertToOptions(data));
              } else {
                var $options = this.$element.children();
                $options.each(function () {
                  var $option = $(this);

                  if (!$option.is('option')) {
                    return;
                  }

                  data.push(self.item($option));
                });
              }

              this.defaultResults = data;
            }
          }
          var dataAdapter = Utils.Extend(TmpAdapter, AjaxAdapter);
          TmpAdapter.prototype.query = function (params, callback) {
            var defaultResults = (typeof this.defaultResults == 'function') ? this.defaultResults.call(this) : this.defaultResults;
            if (defaultResults && (!params.term || params.term.length < this.minimumInputLength)){
              var processedResults = this.processResults(defaultResults, params.term);
              callback(processedResults);
              // ArrayAdapter.__super__.query.call(this, params, callback);
            } else {
              TmpAdapter.__super__.query.call(this, params, callback);
            }
          };

          if (options.get('maximumInputLength') > 0) {
            dataAdapter = Utils.Decorate(dataAdapter, MaximumInputLength);
          }

          if (options.get('maximumSelectionLength') > 0) {
            dataAdapter = Utils.Decorate(dataAdapter, MaximumSelectionLength);
          }

          if (options.get('tags')) {
            dataAdapter = Utils.Decorate(dataAdapter, Tags);
          }

          if (options.get('tokenSeparators') != null || options.get('tokenizer') != null) {
            dataAdapter = Utils.Decorate(dataAdapter, Tokenizer);
          }

          if (options.get('query') != null) {
            var Query = require(options.get('amdBase') + 'compat/query');

            dataAdapter = Utils.Decorate(dataAdapter, Query);
          }

          if (options.get('initSelection') != null) {
            var InitSelection = require(options.get('amdBase') + 'compat/initSelection');

            dataAdapter = Utils.Decorate(dataAdapter, InitSelection);
          }

          return new dataAdapter($element, options);
        }

        return AjaxAdapterWithDefaults;
      });

  $.fn.select2.amd.define('select2/dropdown/instructions', [
    'require',
    'select2/utils',
    'select2/dropdown',
    'select2/dropdown/search',
    'select2/dropdown/hidePlaceholder',
    'select2/dropdown/infiniteScroll',
    'select2/dropdown/attachBody',
    'select2/dropdown/minimumResultsForSearch',
    'select2/dropdown/selectOnClose',
    'select2/dropdown/closeOnSelect'], function(require, Utils, Dropdown, DropdownSearch, HidePlaceholder, InfiniteScroll, AttachBody, MinimumResultsForSearch, SelectOnClose, CloseOnSelect) {
    function Instructions($element, options) {
      var inst = Dropdown;

      function TmpInstructions () {}
      TmpInstructions.prototype.render = function (decorated) {
        var $rendered = decorated.call(this);

        var $instruction = $('<div class="select2-instruction select2-instruction--dropdown"></div>');

        this.$instructionContainer = $instruction;

        $rendered.prepend(this.$instructionContainer);

        return $rendered;
      };
      TmpInstructions.prototype.bind = function (decorated, container, $container) {
        var self = this;

        decorated.call(this, container, $container);

        container.on('results:all', function (params) {
          var showInstruction = self.showInstruction(params.query);

          var message = this.options.get('translations').get('inputTooShortWithDefault');
          if (!message) {
            message = this.options.get('translations').get('inputTooShort');
          }
          self.$instructionContainer.html(message({ minimum: this.options.get('minimumInputLength'), input: (params.query && params.query.term) || '', params: params }));

          if (showInstruction) {
            self.$instructionContainer.removeClass('select2-instruction--hide');
          } else {
            self.$instructionContainer.addClass('select2-instruction--hide');
          }
        });
      };

      TmpInstructions.prototype.showInstruction = function(_, params) {
        if (params && params.term && params.term.length >= this.options.get('minimumInputLength')) {
          return false;
        } else {
          return true;
        }
      };
      inst = Utils.Decorate(inst, TmpInstructions);

      if (!options.get('multiple')) {
        inst = Utils.Decorate(inst, DropdownSearch);
      }

      if (options.get('minimumResultsForSearch') !== 0) {
        inst = Utils.Decorate(inst, MinimumResultsForSearch);
      }

      if (options.get('closeOnSelect')) {
        inst = Utils.Decorate(inst, CloseOnSelect);
      }

      if (
          options.get('dropdownCssClass') != null ||
          options.get('dropdownCss') != null ||
          options.get('adaptDropdownCssClass') != null
      ) {
        var DropdownCSS = require(options.get('amdBase') + 'compat/dropdownCss');

        inst = Utils.Decorate(inst, DropdownCSS);
      }

      inst = Utils.Decorate(inst, AttachBody);

      return new inst($element, options);
    }

    return Instructions;
  });


  RMPlus.Utils = (function(my) {
    var my = my || {};

    // Function makes select2 combobox out of text field
    // Accepts jquery selector and init data (as a js array)
    my.makeSelect2MultiCombobox = function(selector, init_data){
      var $selector = $(selector);
      // add combobox flag, if not already present
      if ($selector.attr('data-multicombobox') !== "true") {
        $selector.attr('data-multicombobox', 'true');
      }

      init_data = init_data || $selector.val();

      if (Object.prototype.toString.call(init_data) === '[object String]') {
        if (init_data.length > 0){
          init_data = init_data.split(',');
        }
        else {
          init_data = [];
        }
      }

      // make data array with objects with id and text properties out of ordinary values array (select2 requirement)
      var data_select2 = [];
      for (var i = 0, len = init_data.length; i < len; i++){
        data_select2[i] = {id: init_data[i], text: init_data[i]};
      }

      // populate text field with init values
      if ($selector.val() === "") {
        $selector.val(init_data);
      }

      // You can't enter text in select2 textfield without createSearchChoice function defined
      $selector.select2({
        createSearchChoice: function(term, data){
          if ($(data).filter(function() { return this.text.localeCompare(term) === 0; }).length === 0){
            return {id:term, text:term};
          }
        },
        multiple: true,
        width: 'resolve',
        data: data_select2
      });
    };

    my.makeSelect2Combobox = function(selector, width){
      var get_url = selector.getAttribute('data-get-url') || '';
      var post_url = selector.getAttribute('data-post-url') || '';
      var model_attribute = selector.getAttribute('data-model-attribute') || 'name';
      var width = width || "400px";

      var placeholder = RMPlus.Utils.combobox_placeholder;
      var min_search_length = parseInt(selector.getAttribute('data-min-search-length')) || 0;

      var data_select2 = [];
      var init_value = undefined;
      var $selector = $(selector);
      if (selector.tagName.toLowerCase() === 'select'){
        init_value = ($selector.val() || '').toString();
        $.each($selector.children(), function(){
          data_select2.push({id: this.value, text: this.textContent });
        });
        // $selector.children().remove();
        // $selector.changeElementType('input');
      }

      var ComboboxAdapter;

      $.fn.select2.amd.require([
        'select2/data/array',
        'select2/utils'
      ], function (ArrayData, Utils) {

        ComboboxAdapter = function($element, options) {
          ComboboxAdapter.__super__.constructor.call(this, $element, options);
        };

        ComboboxAdapter.prototype.current = function (callback) {
          var data = {};
          if (init_value) {
            for (var sch = 0; sch < data_select2.length; sch ++) {
              if (data_select2[sch].id.toString() == init_value) { data = data_select2[sch]; break; }
            }
          }
          callback(data);
        };
        ComboboxAdapter.prototype.query = function (params, callback) {
          var data = {}, found = false, text, term;
          data.results = [];
          if (params.term) {
            for (var i = 0, len = data_select2.length; i < len; i++) {
              text = data_select2[i].text.toLocaleUpperCase();
              term = params.term.toLocaleUpperCase();
              if (text.localeCompare(term) === 0) {
                found = true;
                break;
              }
            }
            if (!found){
              data.results.push({ id: params.term, text: params.term });
            }
          }
          for (var i = 0, len = data_select2.length; i < len; i++) {
            text = data_select2[i].text.toUpperCase();
            term = params.term.toUpperCase();
            if (text.indexOf(term) >= 0) {
              data.results.push(data_select2[i]);
            }
          }
          callback(data);
        };

        Utils.Extend(ComboboxAdapter, ArrayData);
      });

      $selector.select2({ width: width,
        placeholder: placeholder,
        allowClear: true,
        minimumInputLength: min_search_length,
        containerCssClass: 'hint--error hint--top hint--rounded',
        dataAdapter: ComboboxAdapter,
        tags: true
      })
          .on("change blur close", function(event){
            $('#s2id_' + selector.id).removeAttr('data-hint');
            $('#s2id_' + selector.id).removeClass('hint--always');

            var result = $selector.val();
            found = false;

            if (!result) return;

            for (var i = 0, len = data_select2.length; i < len; i++) {
              if (data_select2[i].id === $.trim(result)){
                return;
              }
              if (typeof data_select2[i].id === 'undefined') {
                if (data_select2[i].id.localeCompare(result) === 0) {
                  found = true;
                  break;
                }
              }
            }
            if (!found) {
              var ajax_object = {};
              ajax_object[model_attribute] = $.trim(result);
              $.ajax({
                url: post_url,
                type: 'post',
                dataType: 'json',
                data: ajax_object,
                beforeSend: function() {
                  $('#s2id_' + selector.id + ' .select2-chosen').addClass('select2-spinner');
                  var $form = $(selector.form);
                  $form.find('input[name="commit"]').prop('disabled', 'disabled');
                  $form.on("submit", function(event){
                    event.preventDefault();
                  });
                },
                success: function(data){
                  data_select2.splice(0, 0, {id: data.id, text: data[model_attribute]});
                  data_select2.sort(function(a, b){
                    var nameA=$.trim(a.text.toLowerCase()),
                        nameB=$.trim(b.text.toLowerCase());
                    if (nameA === "")
                      return -1;
                    if (nameA < nameB)
                      return -1;
                    if (nameA > nameB)
                      return 1;
                    if (nameA === nameB)
                      return 0;
                  });
                  $selector.find('[data-select2-tag]').remove();
                  $selector.append('<option value="' + data.id + '">' + data[model_attribute] + '</option>').val(data.id);
                },
                error: function(jqXHR, textStatus, error){
                  var $select2_container = $('#s2id_' + selector.id);

                  if (jqXHR.status === 404) {
                    $select2_container.attr('data-hint', RMPlus.Utils.combobox_404);
                  } else {
                    $select2_container.attr('data-hint', RMPlus.Utils.combobox_error);
                  }
                  $select2_container.addClass('hint--always');
                  $selector.val('');
                },
                complete: function(jqXHR, textStatus){
                  $('#s2id_' + selector.id + ' .select2-chosen').removeClass('select2-spinner');
                  var $form = $(selector.form);
                  $form.find('input[name="commit"]').removeProp('disabled');
                  $form.off("submit");
                }
              });
            }
          }).on("click", function(event) {
        $('#s2id_' + selector.id).removeClass('hint--always');
        $('#s2id_' + selector.id).removeAttr('data-hint');
      });
    };

    return my;
  })(RMPlus.Utils || {});

  $(document).ready(function() {
    $('select.select2, input[type="hidden"], input.ui-autocomplete-input').each(function () {
      if (this.getAttribute('data-combobox') === 'true') {
        RMPlus.Utils.makeSelect2Combobox(this);
      }
      else {
        if (this.tagName.toLowerCase() === 'select') {
          var select2_width = this.getAttribute('data-select2-width');
          var placeholder = this.getAttribute('placeholder') || ' ';
          if (select2_width != undefined) {
            $(this).select2({width: select2_width, allowClear: true, placeholder: placeholder});
          }
          else {
            $(this).select2({width: '400px', allowClear: true, placeholder: placeholder});
          }
        }
      }
    });
  });
}