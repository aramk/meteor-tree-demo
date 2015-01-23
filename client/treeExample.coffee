TemplateClass = Template.treeExample

# Create a temporary collection we can modify on the client without effects on the server.
collection = Collections.createTemporary()
Meteor.startup ->
  Collections.copy(Locations, collection)

loadTrees = ->

  data1 = [
    {
      label: 'node1',
      children: [
        { label: 'child1' },
        { label: 'child2' }
      ]
    },
    {
      label: 'node2',
      children: [
        { label: 'child3' }
      ]
    }
  ]
  @$('#tree1').tree(data: data1)

  data2 = Template.tree.createData(collection)
  @$('#tree2').tree(data: data2)

  # Updating the data should update the tree.

TemplateClass.rendered = ->
  # Delay loading so errors appear in the console.
  setTimeout loadTrees.bind(@), 1000

TemplateClass.helpers

  locations: -> collection.find()

