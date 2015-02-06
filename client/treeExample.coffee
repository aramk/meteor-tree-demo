TemplateClass = Template.treeExample

# Create a temporary collection we can modify on the client without effects on the server.
collection = Collections.createTemporary()
Meteor.startup ->
  Collections.copy(Locations, collection)

loadTrees = ->

  data1 = [
    {
      id: 'abc',
      label: 'node1',
      children: [
        { label: 'child1' },
        { label: 'child2' }
      ]
    },
    {
      id: 'def',
      label: 'node2',
      children: [
        { label: 'child3' }
      ]
    }
  ]
  $tree1 = window.$tree1 = @$('#tree1').tree(data: data1)

  _.delay(
    ->
      node = $tree1.tree('getNodeById', 'abc')
      $tree1.tree('updateNode', node, {label: 'node1 - updated'})

      # $tree1.tree('loadData', [
      #   {
      #     id: 1,
      #     label: 'node1 - updated'
      #   }
      # ])
    1000
  )

  # window.$tree3 = @$('#tree3 .tree')

  # data2 = Template.tree.createData(collection)
  # @$('#tree2').tree(data: data2)

  tree4Template = null
  delay = 1000
  runTestData = ->
    window.$tree4 = $tree4 = @$('#tree4')
    if tree4Template
      Blaze.remove(tree4Template)
    data =
      items: collection.find()
      settings:
        autoExpand: true
    tree4Template = Blaze.renderWithData(Template.tree, data, $tree4[0])

    # Updating the data should update the tree.
    _.delay(
      ->
        collection.insert {name: 'New Zealand'}, (err, result1) ->
          _.delay(
            ->
              collection.insert {name: 'Auckland', parent: result1}, (err, result2) ->
                _.delay(
                  ->
                    au = collection.findOne({name: 'Australia'})
                    collection.update result1, {name: 'New Zealand!', parent: au._id}, (err, result3) ->
                      $tree = $('.tree', $tree4)
                      Template.tree.expandNode($tree, result1)
                      Template.tree.selectNode($tree, result1)
                      Template.tree.selectNode($tree, result2)
                      _.delay(
                        ->
                          Template.tree.deselectNode($tree, result1)
                          collection.remove result2, (err, result3) ->
                            _.delay(
                              -> collection.remove result1, (err, result4) ->
                              delay
                            )
                        delay
                      )
                  delay
                )
            delay
          )
      delay
    )

  # Runs tests to show reactive changes.
  runTestData()
  setInterval runTestData, delay * 6

  # window.go = ->
  #   runTestData()
  #   setInterval runTestData, 15000

TemplateClass.rendered = ->
  # Delay loading so errors appear in the console.
  setTimeout loadTrees.bind(@), 1000

TemplateClass.helpers

  locations: -> collection.find()

