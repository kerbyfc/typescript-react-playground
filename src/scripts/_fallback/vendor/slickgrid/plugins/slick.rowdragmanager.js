(function ($) {
  // register namespace
  $.extend(true, window, {
    "Slick": {
      "RowDragManager": RowDragManager
    }
  });

  function RowDragManager(options) {
    var _grid,
      _canvas,
      _delta,
      _dragging,
      proxy, guide,
      _self = this,
      _handler = new Slick.EventHandler(),
      _defaults = {
        cancelEditOnDrag: false
      };

    function init(grid) {
      options = $.extend(true, {}, _defaults, options);
      _grid = grid;
      _canvas = _grid.getCanvasNode();

      _handler
        .subscribe(_grid.onDragInit, handleDragInit)
        .subscribe(_grid.onDragStart, handleDragStart)
        .subscribe(_grid.onDrag, handleDrag)
        .subscribe(_grid.onDragEnd, handleDragEnd);
    }

    function destroy() {
      if(proxy)
        proxy.remove();
      if(guide)
        guide.remove();

      _handler.unsubscribeAll();
    }

    function handleDragInit(e, dd) {
      // prevent the grid from cancelling drag'n'drop by default
      e.stopImmediatePropagation();
    }

    function handleDragStart(e, dd) {
      var cell = _grid.getCellFromEvent(e);

      if (options.cancelEditOnDrag && _grid.getEditorLock().isActive()) {
        _grid.getEditorLock().cancelCurrentEdit();
      }

      /*if (_grid.getEditorLock().isActive() || !/move|selectAndMove/.test(_grid.getColumns()[cell.cell].behavior)) {
        return false;
      }*/
      var selectedRows = _grid.getSelectedRows().sort();
      dd.selectedRows = selectedRows;

      var rowHeight = _grid.getOptions().rowHeight;
      dd.rowHeight = rowHeight;

      $rows_item = $('.slick-row',_grid.getCanvasNode());
      dd.offsetTop = $rows_item.eq(0).position().top;

      //var cellNode = $rows_item.eq(cell.row);
      var cellNode = $(_grid.getCellNode(cell.row, cell.cell)).parents('.slick-row');
      var pos = cellNode.offset();

      _delta = {
        left : e.pageX - pos.left,
        top  : e.pageY - pos.top + ($(e.target).hasClass('selected') ? selectedRows.indexOf(cell.row)*rowHeight : 0),
      }

      _dragging = true;

      //e.stopImmediatePropagation();

      if (selectedRows.length == 0 || $.inArray(cell.row, selectedRows) == -1) {
        selectedRows = [cell.row];
        _grid.setSelectedRows(selectedRows);
      }

      var k = 0;

      $rows_item.each(function(i){
        var top;
        if(selectedRows.indexOf(i)==-1){
          top = k++*rowHeight;
        }else{
          $(this).addClass('hide-row');
          if(options.sortable){
            top = -10000;
            $(this).hide();
          }else{
            top = dd.offsetTop + k++*rowHeight;
          }
        }
        $(this).css('top', top);
      });

      var css = {
        "position": "absolute",
        "zIndex": 99998,
        "width": $(_canvas).innerWidth(),
        "height": selectedRows.length * rowHeight,
      };

      $selNode = $rows_item.filter('.hide-row');

      dd.selectionProxy = $('<div>')
        .addClass('slick-reorder-proxy')
        .css(css)
        .css({
          top: pos.top,
          left: pos.left
        });

      var columns = _grid.getColumns();

      $selNode.each(function(i){
        var div = $('<div>')
          .addClass(i % 2 ? "even" : "odd")
          .width($(this).width())
          .height(rowHeight);
        $(this).find('.slick-cell').each(function(i){
          div.append(
            $('<div>').html($(this).html())
              .width(columns[i].width)
              .height(rowHeight)
              .css('float', 'left')
          );
        });
        dd.selectionProxy.append(div);
      });

      proxy = dd.selectionProxy
        .appendTo(document.body);

      guide = dd.guide = $('<div>');

      if(options.sortable){
        dd.guide
          .addClass('slick-reorder-guide')
          .css(css).appendTo(_canvas);
      }

      dd.insertBefore = -1;
      _self.onAfterDragStart.notify(dd);
      handleDrag(e, dd);
    }

    function handleDrag(e, dd) {

      if(!_dragging){ return }

      //e.stopImmediatePropagation();

      var top = e.pageY - $(_canvas).offset().top;
      var left = e.pageX - $(_canvas).offset().left;

      dd.selectionProxy.css("top", e.pageY - _delta.top);
      dd.selectionProxy.css("left", e.pageX - _delta.left);

      var rowHeight = _grid.getOptions().rowHeight;
      var $row_item;

      if(!options.sortable){
        $row_item = $('.slick-row',_grid.getCanvasNode());

        $row_item.each(function(i){
          $(this).css('top', dd.offsetTop + i*rowHeight);
        });
        return;
      }

      dd.selectionProxy.find('>div').each(function(i){
        $(this)
          .removeClass("even").removeClass("odd")
          .addClass((dd.insertBefore + i) % 2 ? "even" : "odd")
      });

      $row_item = $('.slick-row:not(.hide-row)',_grid.getCanvasNode());

      var insertBefore = Math.max(0, Math.min(Math.round(top / rowHeight), $row_item.length));

      if (insertBefore !== dd.insertBefore) {
        var eventData = {
          "rows": dd.selectedRows,
          "insertBefore": insertBefore
        };

        $row_item.each(function(i){
          var top;

          $(this)
            .removeClass("even").removeClass("odd")
            .addClass(i % 2 ? "odd" : "even")

          if(i<insertBefore){
            top = i*rowHeight
          }else{
            top = i*rowHeight+rowHeight*dd.selectedRows.length;
          }

          $(this).css('top', top);
        });

        if (_self.onBeforeMoveRows.notify(eventData) === false) {
          dd.guide.css("top", -1000);
          dd.canMove = false;
        } else {
          dd.guide.css("top", insertBefore * rowHeight + dd.offsetTop);
          dd.canMove = true;
        }

        dd.insertBefore = insertBefore;
      }
    }

    function handleDragEnd(e, dd) {
      if (!_dragging) {
        return;
      }
      _dragging = false;
      //e.stopImmediatePropagation();

      if (dd.canMove) {
        var eventData = {
          "rows": dd.selectedRows,
          "insertBefore": dd.insertBefore
        };

        _self.onMoveRows.notify(eventData);

        if(dd.cancelSortable){
          dd.guide.remove();
          dd.selectionProxy.remove();
          return;
        }

        dd.selectionProxy.animate({
          left: dd.guide.offset().left,
          top: dd.guide.offset().top,
        }, 800, 'easeOutBounce', function() {
          dd.guide.remove();
          $(this).remove();
          _self.onAfterMoveRows.notify(eventData);
        });
      }else{
        dd.guide.remove();
        dd.selectionProxy.remove();

        $(_canvas).find('.hide-row').removeClass("hide-row");
      }
    }

    $.extend(this, {
      "onAfterDragStart" : new Slick.Event(),
      "onBeforeMoveRows" : new Slick.Event(),
      "onMoveRows"       : new Slick.Event(),
      "onAfterMoveRows"  : new Slick.Event(),
      "init"             : init,
      "destroy"          : destroy
    });
  }
})(jQuery);