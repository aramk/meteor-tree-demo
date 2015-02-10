TemplateClass = Template.treeExample

# Create a temporary collection we can modify on the client without effects on the server.
window.collection = collection = Collections.createTemporary()
Meteor.startup ->
  Collections.copy(Locations, collection)

loadTrees = ->

  tree4Template = null
  delay = 1000
  reactiveSelectionHandle = null

  window.runTestData = runTestData = ->
    window.$tree4 = $tree4 = @$('#tree4')
    if tree4Template
      Blaze.remove(tree4Template)
    data =
      items: collection.find()
      settings:
        autoExpand: true
        multiSelect: true
        selectable: true
        checkboxes: true
        onCreate: -> console.log('onCreate', arguments)
        onEdit: -> console.log('onEdit', arguments)
        # onDelete: -> console.log('onDelete', arguments)

    # tree4Template = Blaze.renderWithData(Template.tree, data, $tree4[0])
    tree4Template = Blaze.renderWithData(Template.crudTree, data, $tree4[0])
    $tree = $('.tree', $tree4)

    # Listen to selections and checks.
    reactiveSelectionHandle = Tracker.autorun ->
      selectedIds = Template.tree.getSelectedIds($tree)
      console.log('selectedIds', selectedIds)

    $tree.on 'select', (e, args) ->
      console.log('select', args)

    $tree.on 'check', (e, args) ->
      console.log('check', args)

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
                      Template.tree.expandNode($tree, result1)
                      # Template.tree.selectNode($tree, result1)
                      # Template.tree.selectNode($tree, result2)
                      Template.tree.setSelectedIds($tree, [result1, result2])
                      Template.tree.setCheckedIds($tree, [result1, result2])
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
  # setInterval runTestData, delay * 6

TemplateClass.rendered = ->
  # Delay loading so errors appear in the console.
  setTimeout loadTrees.bind(@), 1000

TemplateClass.helpers

  locations: -> collection.find()

