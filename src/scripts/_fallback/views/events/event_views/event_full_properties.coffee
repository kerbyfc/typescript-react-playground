"use strict"

require "behaviors/events/entity_info.coffee"

class animatedRegion extends Marionette.Region

  attachHtml: (view) ->
    if view.options.isAnimated
      @$el.empty().append(view.el)
      @$el.hide().toggle('slide', {direction: view.options.direction or 'right'}, 400)
    else
      super

class AnalysisItemView extends Marionette.ItemView

  template: 'events/event_views/event_full_properties/ent_advanced'

  templateHelpers: ->
    entries: @options.entries
    entry: @options.entry

  triggers:
    'click .eventAnalisysItem__more': 'back'

class AnalysisInfoView extends Marionette.ItemView

  template: 'events/event_views/event_full_properties/ent'

  events:
    'click [data-type="entity"]': 'show_more'

  show_more: (e) ->
    @trigger 'show_more', $(e.currentTarget), @model

class AnalysisView extends Marionette.LayoutView

  template: 'events/event_views/event_full_properties/analysis'

  regions:
    tech:
      regionClass: animatedRegion
      selector: '#tech'

  events:
    'click .eventAnalisys__name'    : 'select_prot_doc'
    'show_more'                     : 'show_more'
    'back'                          : 'back'

  show_more: (elem, model) ->
    condition = model.get('conditions')[elem.data('condition')]
    entries   = _.findWhere condition, {ENTRY_ID: elem.data 'entries'}
    entry     = entries.entries[elem.data('entry')]

    @_showAdvTechInfo model, entries, entry, true

  back: ({collection, model, view}) ->
    @_showMainTechInfo model, true, 'left'

  initialize: ->
    @protected_documents = @model.get('protected_documents')

  select_prot_doc: (e) ->
    $(e.target).closest('.eventAnalisys__list').find('._selected').removeClass('_selected')
    $(e.target).closest('.eventAnalisys__item').addClass('_selected')

    protected_document = new Backbone.Model _.findWhere @protected_documents, PROT_DOCUMENT_ID: $(e.target).data('id')

    @_showMainTechInfo protected_document

  onShow: ->
    if @protected_documents.length
      @_showMainTechInfo new Backbone.Model @protected_documents[0]

      @$('.eventAnalisys__list li:first-child .eventAnalisys__item').addClass '_selected'

  _showAdvTechInfo: (model, entries, entry, isAnimated = false) ->
    @tech.show new AnalysisItemView
      model       : model
      entries     : entries
      entry       : entry
      isAnimated  : isAnimated

    Marionette.bindEntityEvents @, @tech.currentView, @events

  _showMainTechInfo: (model, isAnimated = false, direction = 'right') ->
    @tech.show new AnalysisInfoView
      model: model
      isAnimated: isAnimated
      direction: direction

    Marionette.bindEntityEvents @, @tech.currentView, @events

class MessagesView extends Marionette.LayoutView

  template: 'events/event_views/event_full_properties/messages'

  regions:
    messages_table      : "#messages_table"

  initialize: ->

    @messages_table_ = new App.Views.Controls.TableView
      collection: new Backbone.Collection @model.get 'messages'
      config:
        default:
          sortCol: "SEVERITY"
        columns: [
          {
            id          : "SEVERITY"
            name        : ""
            field       : "SEVERITY"
            width       : 50
            resizable   : false
            sortable    : true
            cssClass    : "center"
            formatter   : (row, cell, value, columnDef, dataContext) ->
              switch dataContext.get(columnDef.field)
                when 'error'
                  return '<i class="fontello-icon-cancel-circle"></i>'
                when 'warning'
                  return '<i class="fontello-icon-attention-4"></i>'
                when 'info'
                  return '<i class="fontello-icon-info-circle-1"></i>'
          }
          {
            id          : "MODULE"
            name        : App.t 'events.events.module'
            field       : "MODULE"
            resizable   : true
            sortable    : true
            width       : 200
            formatter   : (row, cell, value, columnDef, dataContext) ->
              locale = App.t('events.events', { returnObjectTrees: true })

              return locale["module_" + dataContext.get(columnDef.field)]
          }
          {
            id          : "CODE"
            name        : App.t 'events.events.message'
            resizable   : true
            sortable    : true
            minWidth    : 500
            field       : "CODE",
            formatter   : (row, cell, value, columnDef, dataContext) ->
              locale = App.t('events.events.messages_code', { returnObjectTrees: true })

              if locale[dataContext.get(columnDef.field)]
                return locale[dataContext.get(columnDef.field)]
              else
                return dataContext.get 'TEXT'
          }
        ]

  onShow: ->
    @messages_table.show @messages_table_
    @messages_table_.resize 200, 930

class EventFullPropertiesGeneral extends Marionette.ItemView

  template:  'events/event_views/event_full_properties/general'

  behaviors:
    EntityInfo:
      targets       : '.popover_info'
      behaviorClass : App.Behaviors.Events.EntityInfo

  events:
    "click .tag__delete"   : "tags_delete"

  tags_delete: (e) ->
    e?.preventDefault()

    @model.deleteTags([$(e.currentTarget).data('tag-id')])
    .done =>
      @render()
    .fail ->
      throw new Error("Can't delete tag")

module.exports = class EventFullProperties extends Marionette.LayoutView

  template: 'events/event_views/event_full_properties'

  regions:
    eventContent        : '#event_content'
    general             : '#eventDetailsExtended__general'
    analysis            : '#eventDetailsExtended__analisys'
    messages            : "#eventDetailsExtended__errors"

  onShow: ->
    @general.show  new EventFullPropertiesGeneral model: @model
    @analysis.show new AnalysisView model: @model
    @messages.show new MessagesView model: @model
