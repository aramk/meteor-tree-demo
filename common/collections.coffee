schema = new SimpleSchema
  name:
    label: 'Name'
    type: String

@Animals = new Meteor.Collection('animals')
Animals.attachSchema(schema)
Animals.allow(Collections.allowAll())

# Add some sample data

if Meteor.isServer

  _.each ['Dog', 'Cat', 'Mouse'], (name) ->
    Animals.upsert({name: name}, {$set: {name: name}})
