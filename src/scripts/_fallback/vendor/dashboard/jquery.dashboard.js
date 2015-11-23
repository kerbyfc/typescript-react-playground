(function($) {
  'use strict';

  	function Dashboard(dashboard, options) {
  		this.options = $.extend({}, this.options, options);
  		this.$       = $(dashboard);
  		this.columns = this.$.find(this.options.columnClass);
  		this.sector  = this.$.find(this.options.sectorClass);

		this._createWidgets(this);

		this.widgetReady    = null;
		this.widgetDragging = null;

		$(document).on({
			mousemove: $.proxy(this.dragMove, this),
			touchmove: $.proxy(this.dragMove, this),
			mouseup:   $.proxy(this.dragStop, this),
			touchend:  $.proxy(this.dragStop, this)
		});

		$(this.options.container).on({
			scroll:    $.proxy(this.onScroll, this)
		});
  	};

  	Dashboard.prototype = {
  		onScroll: function(e) {
  			if (this.widgetDragging != null) {
  				this.scroll = true;
  			}
  		},

  		addWidget: function(wid) {
  			var widget;

			widget 				  = wid[0]
			widget.$              = wid;
			widget.dashboard      = this;

			widget.dragOffsetLeft = widget.dragOffsetTop = widget.clickOffsetLeft = widget.clickOffsetTop = 0;

			widget.$
				.on({
					mousedown:  $.proxy(this.dragStart, widget),
					touchstart: $.proxy(this.dragStart, widget)
				}, this.options.headerClass);
  		},

  		_createWidgets: function(dashboard) {
  			var widget;
			var widgets = dashboard.$.find(this.options.widgetClass);

			var i = widgets.length;
			while(i--) {

				widget = widgets[i];

				widget.$               = widgets.eq(i);
				widget.dashboard       = dashboard;

				widget.dragOffsetLeft = widget.dragOffsetTop = widget.clickOffsetLeft = widget.clickOffsetTop = 0;

				widget.$
					.on({
						mousedown:  $.proxy(this.dragStart, widget),
						touchstart: $.proxy(this.dragStart, widget)
					}, this.options.headerClass);
			}
  		},

  		dragStart: function(e) {

			var target = $(e.target);
			if(target.hasClass('jdash-collapse') || target.parents().is(this.dashboard.options.toolbarClass))
				return;

			this.dashboard.max = 0;
			for (var i = 0; i < this.dashboard.columns.length; i++) {
				var height = $(this.dashboard.columns[i]).height();

				if (height > this.dashboard.max) {
					this.dashboard.max = height
				}
			}

			if(this.dashboard.widgetReady == null && this.dashboard.widgetDragging == null) {

				var offset = $(this).offset();
				var mouse  = Dashboard.prototype.getMouseLoc(e);

				this.dragOffsetLeft  = offset.left;
				this.dragOffsetTop   = offset.top;
				this.clickOffsetLeft = mouse.x - offset.left;
				this.clickOffsetTop  = mouse.y - offset.top;

				this.dashboard.widgetReady = this;
			}

			return false;
		},

		dragStop: function(e) {

			if(this.widgetDragging == null) {
				this.widgetReady = null;
				return;
			}

			var widget = this.widgetDragging;

			var offset = $(widget).offset();

			$(widget).insertBefore(this.sector);

			widget.style.marginBottom = (-widget.offsetHeight - parseFloat($(widget).css('marginTop'))) + 'px';
			widget.style.top          = (offset.top  - this.sector.offset().top) + 'px';
			widget.style.left         = (offset.left - this.sector.parent().offset().left - parseFloat($(widget).css('marginLeft'))) + 'px';

			this.sector.animate({ height: $(widget).height() }, 200);

			$(widget).animate({ left: 0, top: 0 }, 200, '', function() {
				this.style.marginBottom = $(this).css('marginTop');
				this.dashboard.sector.hide();
				$(this).removeClass(this.dashboard.options.draggingClass);
			});

			this.options.onMoved($(widget).attr('id'), $(widget).closest(this.options.columnClass).index(), $(widget).index())

			this.widgetReady    = null;
			this.widgetDragging = null;
		},

		dragMove: function(e) {

			var widget;

			if(this.widgetDragging == null && this.widgetReady != null) {

				this.widgetDragging = this.widgetReady;
				this.widgetReady    = null;

				widget = this.widgetDragging;

				$(widget).addClass(this.options.draggingClass);
				widget.style.marginBottom = (-$(widget).outerHeight() - parseFloat($(widget).css('marginTop'))) + 'px';

				this.sector.insertAfter(widget);
				this.sector[0].style.display = 'block';
				this.sector[0].style.height  = $(widget).height() + 'px';
			}

			if(this.widgetDragging != null) {

				var clientY = e.clientY;
				if(typeof clientY == 'undefined') {
					var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
					clientY = touch.clientY - $(window).scrollTop();
				}

				if(clientY < $(window).height() / 2 - 200){
					$(this.options.container).scrollTo({top:'-=30px', left:'=0'});
				}

				if((clientY > $(window).height() / 2 + 200) && ($(this.options.container).scrollTop() + $(this.options.container).height() <= this.max + $(this.widgetDragging).height() )){
					$(this.options.container).scrollTo({top:"+=30px", left:'=0'});
				}

				widget = this.widgetDragging;

				var mouse = Dashboard.prototype.getMouseLoc(e);

				var widgetleft = mouse.x - widget.dragOffsetLeft - widget.clickOffsetLeft;
				var widgettop  = mouse.y - widget.dragOffsetTop  - widget.clickOffsetTop;

				var column, other, shift = false;

				var widgetoffset = $(widget).offset();
				var widgetcenter = widgetoffset.left + widget.offsetWidth/2;
				var widgetcolumn = this.sector.parent();

				widget.style.left = widgetleft + 'px';
				widget.style.top  = widgettop  + 'px';

				/* checks the columns before and after the one containing
				 * the dragged widget to determine what column this widget
				 * should be placed in
				 */
				if(widgetcolumn.prev(this.options.columnClass).length && (column = widgetcolumn.prev()[0]) && widgetcenter + 10 < $(column).offset().left + column.offsetWidth) {

					column.appendChild(this.sector[0]);
					widgetoffset = $(widget).offset();
					shift = true
				}
				else if(widgetcolumn.next(this.options.columnClass).length && (column = widgetcolumn.next()[0]) && widgetcenter - 10 > $(column).offset().left) {

					column.appendChild(this.sector[0]);
					widgetoffset = $(widget).offset();
					shift = true
				}

				/*
				 * checks the widgets before and after the widget being
				 * dragged to determine where it should be placed
				 */
				if(other = this.sector.prev()[0]) {
					if(other === widget) other = $(other).prev()[0];

					if(other && widgetoffset.top + 10 < $(other).offset().top + other.offsetHeight/2) {

						other.parentNode.insertBefore(this.sector[0], other);
						widgetoffset = $(widget).offset();
						shift = true
					}
				}
				if(other = this.sector.next()[0]) {

					if(other === widget) other = $(other).next()[0];
					if(other && widgetoffset.top + widget.offsetHeight - 10 > $(other).offset().top + other.offsetHeight/2) {

						other.parentNode.insertBefore(this.sector[0], other.nextSibling);
						widgetoffset = $(widget).offset();
						shift = true
					}
				}

				if (shift || this.scroll ){
					widget.dragOffsetLeft = widgetoffset.left - widgetleft;
					widget.dragOffsetTop  = widgetoffset.top  - widgettop;

					widget.style.left = (mouse.x - widget.dragOffsetLeft - widget.clickOffsetLeft) + 'px';
					widget.style.top  = (mouse.y - widget.dragOffsetTop  - widget.clickOffsetTop)  + 'px';

					this.scroll = false;
				}
			}
		},

		getMouseLoc: function(e) {
			if(typeof e.pageX == 'undefined')
				e = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
			return { x: e.pageX, y: e.pageY };
		}
  	}

  	$.fn.dashboard = function(option, parameter) {
        return this.each(function() {
            var data = $(this).data('dashboard'), options = typeof option == 'object' && option;

            // Initialize the dashboard.
            if (!data) {
                $(this).data('dashboard', ( data = new Dashboard(this, options)));
            }

            // Call dashboard method.
            if ( typeof option == 'string') {
                data[option](parameter);
            }
        });
    };

    $.fn.dashboard.Constructor = Dashboard;

})(jQuery);