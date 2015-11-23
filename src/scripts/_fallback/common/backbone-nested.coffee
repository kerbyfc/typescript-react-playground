module.exports =
  class App.Common.BackboneNested extends Backbone.Model
    nestCollection : (attributeName, nestedCollection) ->
      #setup nested references
      for item, i in nestedCollection
        @attributes[attributeName][i] = nestedCollection.at(i).attributes

      nestedCollection.bind 'reset', (initiative) =>
        @attributes[attributeName] = initiative.toJSON() or []

      #create empty arrays if none
      nestedCollection.bind 'add', (initiative) =>
        if not @get(attributeName)
          @attributes[attributeName] = []
        @get(attributeName).splice(initiative.collection.indexOf(initiative), 0, initiative.attributes)

        @trigger 'change', @, {}

      nestedCollection.bind 'remove', (initiative) =>
        updateObj = {}
        updateObj[attributeName] = _.without(@get(attributeName), initiative.attributes)
        @set(updateObj)

        @trigger 'change', @, {}

      nestedCollection.bind 'invalid', (initiative) =>
        @trigger 'invalid', arguments...

      nestedCollection.bind 'change', (initiative) =>
        @trigger 'change', arguments...

      nestedCollection
