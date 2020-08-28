(function($){
  $.fn.serializeHash = function() {
    var hash = {};
    /***
    * Original idea https://github.com/sdrdis/jquery.serialize-hash
    * New realization Kovalevskiy Vasil
    * Fully new algorithm to generate result hash and detecting objects/arrays
     Example:
     ---------- HTML ----------
     <form id="form">
     <input type="hidden" name="firstkey" value="val1" />
     <input type="hidden" name="secondkey[0]" value="val2" />
     <input type="hidden" name="secondkey[1]" value="val3" />
     <input type="hidden" name="secondkey[key][]" value="val4" />
     <input type="hidden" name="secondkey[key][]" value="val5" />
     <input type="hidden" name="secondkey[ary][][k1]" value="1" />
     <input type="hidden" name="secondkey[ary][][k2]" value="1" />
     <input type="hidden" name="secondkey[ary][][k1]" value="2" />
     <input type="hidden" name="secondkey[ary][][k2]" value="2" />

     </form>
     ---------- JS ----------
     $('#form').serializeHash()
     should return :
     {
       firstkey: 'val1',
       secondkey: {
         0: 'val2',
         1: 'val3',
         key: ['val4', 'val5'],
         ary: [
          { k1: 1, k2: 1},
          { k1: 1, k2: 1}
         ]
       }
     }
     ***/
    function is_hash_has_key(hash, key) {
      if (/\[\]/.test(key)) {
        return false;
      }
      var res = $.extend(true, {}, hash);
      var keys = key.split(/[\[\]]+/);
      for (var sch = 0; sch < keys.length; sch ++) {
        var k = keys[sch];
        if (!k || k == '') { continue; }
        if (Array.isArray(res) || !res.hasOwnProperty(k)) {
          return false;
        }
        res = res[k];
      }

      return true;
    }

    function normalize(params, key, value) {
      var keys = /[\[\]]*([^\[\]]+)\]*(.*)/.exec(key);

      var k = keys[1];
      var after = keys[2];
      if (!k) {
        if (!value && key == '[]') {
          return [v];
        } else {
          return;
        }
      }

      var reg;

      if (!after || after == '') {
        params[k] = value;
      } else if (after == '[') {
        params[key] = value;
      } else if (after == '[]') {
        params[k] = params[k] || [];
        if (!Array.isArray(params[k])) {
          console.log('wrong params; expected Array for param "' + k + '"');
          return;
        }
        if (Array.isArray(value)) {
          params[k] = params[k].concat(value);
        } else {
          params[k].push(value);
        }
      } else if ((reg = /^\[\]\[([^\[\]]+)\]$/.exec(after)) || (reg = /^\[\](.+)$/.exec(after))) {
        var child_key = reg[1];
        params[k] = params[k] || [];
        if (!Array.isArray(params[k])) {
          console.log('wrong params; expected Array for param "' + k + '"');
          return;
        }
        var lst = params[k][params[k].length - 1];
        if (lst && !Array.isArray(lst) && !is_hash_has_key(lst, child_key)) {
          normalize(lst, child_key, value)
        } else {
          var tmp = normalize({}, child_key, value);
          if (Array.isArray(tmp)) {
            params[k] = params[k].concat(tmp);
          } else {
            params[k].push(tmp);
          }
        }
      } else {
        params[k] = params[k] || {};
        if (Array.isArray(params[k])) {
          console.log('wrong params; expected Hash for param "' + k + '"');
          return;
        }
        params[k] = normalize(params[k], after, value)
      }

      return params;
    }

    var els = $(this).find(':input').get();
    $.each(els, function() {
      if (this.name && !this.disabled && (this.checked || /select|textarea/i.test(this.nodeName) || /hidden|text|search|tel|url|email|password|datetime|date|month|week|time|datetime-local|number|range|color/i.test(this.type))) {
        var val = $(this).val();
        hash = normalize(hash, this.name, val);
      }
    });
    return hash;
  };
})(jQuery);