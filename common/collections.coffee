schema = new SimpleSchema
  name:
    type: String
    index: true
  parent:
    type: String
    index: true
    optional: true

@Locations = new Meteor.Collection('locations')
Locations.attachSchema(schema)
Locations.allow(Collections.allowAll())

# Add some sample data

if Meteor.isServer

  locations =
    'Australia':
      'Victoria':
        'Melbourne':
          'City': {}
        'Geelong': {}
      'New South Wales':
        'Sydney': {}
      'South Australia':
        'Adelaide': {}
      'Queensland':
        'Brisbane': {}

  collection = Locations
  Objects.traverseValues locations, (parentValue, parentName) ->
    parentSelector = {name: parentName}
    result = collection.upsert(parentSelector, {$set: {name: parentName}})
    parent = collection.findOne(parentSelector)
    return unless Types.isObject(parentValue)
    children = Object.keys(parentValue)
    _.each children, (childName) ->
      collection.upsert {name: childName}, {$set: {name: childName, parent: parent._id}}
