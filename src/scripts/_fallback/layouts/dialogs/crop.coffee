"use strict"

ImageCrop = require "image.crop"
require "layouts/dialogs/confirm.coffee"

class App.Layouts.CropDialog extends App.Layouts.ConfirmDialog

  template: "dialogs/crop"

  ui:
    _.extend {}, @::ui, image_crop : "#image-crop"

  initialize: (options) ->
    {@callback} = options
    self = @
    super options

    if not options.file  or  not (options.file instanceof File)
      throw new Error "Убедись, что в конструктор передана картинка: ключ - file; значение - экземпляр класса File"

    fr = new FileReader()
    # При прочтении файла как data-base64
    fr.onload = ->
      self.file_data = @result
      image = new Image()
      # При прочтении файла как экземпляр класса Image
      image.onload = ->
        # Если картинка уж очень большая по отношению к видимой области, вычисляется коэфициент ресайза
        resize_k = do =>
          result_k = 1
          visible_width = document.width - 200
          visible_height = document.height - 200

          if visible_width < @naturalWidth
            result_width_k = @naturalWidth / visible_width
          if visible_height < @naturalHeight
            result_height_k = @naturalHeight / visible_height

          result_k = _.max [result_k, result_width_k, result_height_k]

        # Высчитать размеры canvas, съинициализировать crop
        self.ui.image_crop.prop("width", image.naturalWidth/resize_k)
        self.ui.image_crop.prop("height", image.naturalHeight/resize_k)
        ImageCrop self.ui.image_crop, self.file_data, resize_k

      image.src = self.file_data
    fr.readAsDataURL options.file


  accept: (e) ->
    e.preventDefault()

    if ImageCrop.crop_beyond
      App.Helpers.confirm
        cancel : null
        confirm: App.t 'global.ok'
        title  : App.t 'crop-image.crop_beyond'
    else
      @callback(
        ImageCrop.get_results(
          @options.max_side
        )
      )
      @cropped = true
      @destroy()


  onDestroy: ->
    unless @cropped
      @callback()
