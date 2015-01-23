TemplateClass = Template.tree

TemplateClass.rendered = ->
  data = @data
  items = data.items
  cursor = Collections.getCursor(items)
  collection = Collections.get(items)
  settings = _.extend({
    collection: collection
  }, data.settings)

  $tree = @$('.tree')
  isLoaded = false
  loadDf = null
  loadTree = ->
    data = TemplateClass.createData(items, settings)
    if isLoaded
      $tree.tree('loadData', data)
    else
      $tree.tree(data: data)
    isLoaded = true

  throttledLoadTree = _.throttle loadTree, 500
  throttledLoadTree()

  Collections.observe cursor,
    added: throttledLoadTree
    changed: throttledLoadTree
    removed: throttledLoadTree

TemplateClass.createData = (docs, args) ->
  args ?= {}
  collection = args.collection ? Collections.get(docs)
  docs = Collections.getItems(docs)
  args = _.extend({
    getChildren: (doc) ->
      unless collection
        throw new Error('No collection provided when creating tree data')
      collection.find({parent: doc._id}).fetch()
    hasChildren: (doc) -> @getChildren(doc).length == 0
    hasParent: (doc) -> doc.parent?
    toData: (doc) ->
      childrenDocs = @getChildren(doc)
      childrenData = _.map childrenDocs, @toData, @
      {
        id: doc._id
        label: doc.name
        children: childrenData
      }
  }, args)
  
  data = []
  rootDocs = _.filter docs, (doc) -> !args.hasParent(doc)
  _.each rootDocs, (doc) ->
    datum = args.toData(doc)
    data.push(datum)
  data
