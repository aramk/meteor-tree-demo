Meteor.startup ->

  Meteor.publish 'locations', -> Locations.find()
