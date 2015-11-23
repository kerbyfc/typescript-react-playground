"use strict"

co = require "co"

module.exports = class EventMain extends Marionette.LayoutView

  className: 'eventDetail__contentWrap'

  _getEventProperties: (headers, content) ->

    properties = {}

    properties.encrypted = content.ENCRYPTED

    properties

  _findText: (item, stop_if_text = false) ->
    text = []

    _.each item.children, (elem) =>
      if parseInt(elem.IS_TEXT, 10) is 1
        text.push elem.OBJECT_CONTENT_ID
      else
        if elem.children? and not stop_if_text
          text = _.union text, @_findText(elem)

    return text

  _getAttachments: (content) ->
    co =>
      attachments = []

      if content.children
        for elem in content.children when elem.KIND is 'child'
          att =
            filename      : elem.FILE_NAME
            encrypted     : elem.ENCRYPTED
            mime          : elem.MIME
            content_id    : elem.OBJECT_CONTENT_ID
            size          : elem.CONTENT_SIZE_STORED
            object_id     : elem.OBJECT_ID

          if parseInt(elem.IS_TEXT, 10) is 0
            att.text = yield @_findText(elem)
          else
            att.text = [elem.OBJECT_CONTENT_ID]

          attachments.push att

      attachments

  downloadAttach: (e) ->
    e?.preventDefault()

    content_id = @data.attachments[$(e.currentTarget).data('index')]?.content_id

    if content_id isnt undefined
      @model.downloadAttach(content_id)

  chunkData: (data, len) ->
    _size = Math.ceil(data.length/len)
    _ret  = new Array(_size)

    for _i in [0.._size]
      _offset = _i * len
      _ret[_i] = data.substring(_offset, _offset + len)

    _ret

  _showProgress: (attach_element) ->
    attach_element.find('.btn-group').addClass('load__progress')

  _hideProgress: (attach_element) ->
    attach_element.find('.btn-group').removeClass('load__progress')

  _showTextForAttach: (attachment) ->

  _showEmbededObject: (attachment) ->
    url_params = $.param
      object_id   : attachment.object_id
      content_id  : attachment.content_id

    if attachment.mime is 'application/pdf'
      dimension = ' width="100%" height="100%" '

    $('[data-region="content"]').contents().find('html')
    .empty().append("""
        <object classid="CLSID:106E49CF-797A-11D2-81A2-00E02C015623" #{dimension or ''}>
        <param name="src" value="#{App.Config.server}/api/object/content?#{url_params}">
        <param name="negative" value="yes">
          <embed #{dimension or ''} src="#{App.Config.server}/api/object/content?#{url_params}" type="#{attachment.mime}" negative=yes>
      </object>""")

  showAttach: (e) ->
    e?.preventDefault()

    return if @data.attachments.length is 0

    # cancel previous request
    $.xhrPool.abortAll()

    if e
      return if $(e.target).hasClass('caret')

      $target         = $(e.currentTarget)
      $activeAttach   = $target.closest('.eventInfo__attachment').find('li.active')

      # if already showed nothing to do
      return if $target.hasClass('.active')

      # Если было выделено вложение - снимаем выделение
      @_hideProgress($activeAttach)
      $activeAttach.removeClass('active')

      # Делаем активным текущее вложение
      @_showProgress($target)
      $target.addClass('active')

      index = $target.find('a').data('index')
    else
      $target = @$('[data-region="eventParts"] li:first')

      $target.addClass('active')
      @_showProgress($target)

      index = 0

    return if index is undefined

    # Unactive text link
    $('.text-message > a').removeClass('active')

    # Если это картинка или pdf то покажем его
    if @data.attachments[index].mime.substr(0, 5) is 'image' or @data.attachments[index].mime is 'application/pdf'
      @_showEmbededObject(@data.attachments[index])

      @_hideProgress($target)
    else
      co =>
        try
          if @data.attachments[index].text?.length
            @text = (yield @model.getContent(@data.attachments[index].text))
        catch e
          @text = null
          return

        @_hideProgress($target)

        if @text
          @content = @chunkData(@text, 1024 * 25)
          @showed_chunk = 0

          $('.text').contents().find('html').empty().append('<pre></pre>')
          $('.text').contents().find('html > pre').css({
            "word-break": "break-all"
            "white-space": "pre-wrap"
            "padding": "10px"
          }).text(@content[0])

  initialize: ->
    # Грузим форматы для отображения типов аттачей
    @formats = App.request('bookworm', 'fileformat').pretty()

  _needLoadMoreData: (e) =>
    if @content?.length
      if $(e.target).contents().height() - $(e.target).scrollTop() < $(e.target).contents().height() * 0.6
        if @showed_chunk isnt -1 and @showed_chunk isnt @content.length
          @showed_chunk = @showed_chunk + 1

          @ui.text.contents().find('html > pre').append(@content[@showed_chunk])

  onShow: ->
    $(@ui.text.contents()).scroll _.throttle(@_needLoadMoreData, 100)
