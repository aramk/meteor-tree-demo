Meteor.startup ->

  Meteor.publish 'animals', -> Animals.find()
