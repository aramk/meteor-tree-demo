TemplateClass = Template.tree

TemplateClass.created = ->
  data = @data
  items = data.items
  cursor = Collections.getCursor(items)
  collection = Collections.get(items)
  @model = data.model ? new TreeModel(collection: collection)
  # Allow modifying the underlying logic of the tree model.
  _.extend(@model, data.settings)

TemplateClass.rendered = ->
  data = @data
  items = data.items
  cursor = Collections.getCursor(items)
  collection = Collections.get(items)
  settings = _.extend({
    collection: collection
  }, data.settings)

  $tree = @$('.tree')
  model = @model
  isLoaded = false
  loadDf = null
  loadTree = (data) ->
    docs = Collections.getItems(items)
    data ?= model.docsToNodeData(docs)
    if isLoaded
      $tree.tree('loadData', data)
    else
      $tree.tree(data: data)
    isLoaded = true

  throttledLoadTree = _.throttle(loadTree, 500)
  throttledLoadTree()

  @autorun ->
    Collections.observe cursor,
      added: (newDoc) ->
        data = model.docToNodeData(newDoc, {children: false})
        console.log('added', newDoc)
        parent = model.getParent(newDoc)
        if parent
          parentNode = $tree.tree('getNodeById', parent)
        else
          parentNode = $tree.tree('getTree')
        $tree.tree('appendNode', data, parentNode)
      changed: (newDoc, oldDoc) ->
        node = $tree.tree('getNodeById', newDoc._id)
        # Only get one level of children and find their nodes. Children in deeper levels will be
        # updated by their own parents.
        data = model.docToNodeData(newDoc, {children: false})
        childDocs = model.getChildren(newDoc)
        data.children = _.map childDocs, (childDoc) ->
          $tree.tree('getNodeById', childDoc._id)
        $tree.tree('updateNode', node, data)
        console.log('changed', newDoc, oldDoc)
      removed: (oldDoc) ->
        node = $tree.tree('getNodeById', oldDoc._id)
        $tree.tree('removeNode', node)


class TreeModel

  constructor: (args) ->
    @collection = args.collection
    unless @collection
      throw new Error('No collection provided when creating tree data')
  
  getChildren: (doc) -> @collection.find({parent: doc._id}).fetch()
  
  hasChildren: (doc) -> @getChildren(doc).length == 0

  getParent: (doc) -> doc.parent

  hasParent: (doc) -> @getParent(doc)?

  docToNodeData: (doc, args) ->
    args = _.extend({
      children: true
    }, args)
    data =
      id: doc._id
      label: doc.name
    if args.children
      childrenDocs = @getChildren(doc)
      childrenData = _.map childrenDocs, @docToNodeData, @
      data.children = childrenData
    data

  docsToNodeData: (docs) ->
    data = []
    rootDocs = _.filter docs, (doc) => !@hasParent(doc)
    _.each rootDocs, (doc) =>
      datum = @docToNodeData(doc)
      data.push(datum)
    data
