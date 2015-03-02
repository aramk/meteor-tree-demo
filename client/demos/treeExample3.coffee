TemplateClass = Template.treeExample3

# Create a temporary collection we can modify on the client without effects on the server.
window.collection = collection = Collections.createTemporary()

loadTrees = ->

  treeTemplate = null
  delay = 1000
  reactiveSelectionHandle = null

  window.runTestData = runTestData = ->
    console.log('Refresh tree')
    Collections.removeAllDocs(collection)
    Collections.copy(Locations, collection)

    for i in [0..1000]
      collection.insert({name: 'Entity ' + i})

    window.$tree = $tree = @$('#tree')
    # if treeTemplate
    #   Blaze.remove(treeTemplate)
    # data =
    #   items: collection.find()
    #   settings:
    #     autoExpand: true
    #     multiSelect: true
    #     selectable: true
    #     # checkboxes: true
    #     onCreate: -> console.log('onCreate', arguments)
    #     onEdit: -> console.log('onEdit', arguments)
    #     # onDelete: -> console.log('onDelete', arguments)

    # treeTemplate = Blaze.renderWithData(Template.tree, data, $tree[0])
    # # treeTemplate = Blaze.renderWithData(Template.crudTree, data, $tree[0])
    # $tree = $('.tree', $tree)

    # # Listen to selections and checks.
    # reactiveSelectionHandle = treeTemplate.autorun ->
    #   selectedIds = Template.tree.getSelectedIds($tree)
    #   console.log('selectedIds', selectedIds)

    # $tree.on 'select', (e, args) ->
    #   console.log('select', args)

    # $tree.on 'check', (e, args) ->
    #   console.log('check', args)

    items = collection.find().fetch()
    console.log('collection', items)

    model = new TreeModel(collection: collection)
    data = _.map items, (item) -> model.docToNodeData(item)
    console.log('data', data)
    $tree.tree({
      data: data
    })

    # i = 0
    # setInterval(
    #   ->
    #     collection.insert({name: 'Entity ' + i})
    #     i++
    #   50
    # )

  # Runs tests to show reactive changes.
  # runTestData()
  # setInterval runTestData, delay * 6

TemplateClass.rendered = ->
  # Delay loading so errors appear in the console.
  setTimeout loadTrees.bind(@), 1000

TemplateClass.helpers

  locations: -> collection.find()

