(function($) {
    $.widget("ui.sortable", $.ui.sortable, {
        _mouseStart: function (event) {
            var autoscroll = $(event['target']).parents('.autoscroll');
            if(autoscroll.length > 0)
            {
                autoscroll.css("position", "static");
            }
            return this._super(event);
        },
        refresh: function (event) {
            var r = this._super(event);
            var autoscroll = $('.autoscroll');
            if(autoscroll.length > 0)
            {
                autoscroll.css("position", "");
            }
            return r;
        }
    });
})(jQuery);
