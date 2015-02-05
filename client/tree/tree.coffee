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

  $tree = @$tree = @$('.tree')
  model = @model
  docs = Collections.getItems(items)
  treeData = model.docsToNodeData(docs)
  $tree.tree(data: treeData, autoOpen: settings.autoExpand)

  @autorun ->
    Collections.observe cursor,
      added: (newDoc) ->
        data = model.docToNodeData(newDoc, {children: false})
        console.log('added', newDoc)
        parent = model.getParent(newDoc)
        parentNode = getParentNode($tree, parent)
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
        parent = newDoc.parent
        if parent != oldDoc.parent
          parentNode = getParentNode($tree, parent)
          $tree.tree('moveNode', node, parentNode, 'inside')
      removed: (oldDoc) ->
        node = $tree.tree('getNodeById', oldDoc._id)
        $tree.tree('removeNode', node)

####################################################################################################
## AUXILIARY
####################################################################################################

getDomNode = (template) ->
  unless !template then throw new Error('No template provided')
  template.find('.tree')

getTemplate = (domNode) ->
  unless !domNode then throw new Error('No domNode provided')
  domNode = $(domNode)[0]
  Blaze.getView(domNode).templateInstance()

getSettings = (domNode) -> getTemplate(domNode).data.settings ? {}

getNode = ($tree, id) -> $tree.tree('getNodeById', id)

getRootNode = ($tree) -> $tree.tree('getTree')

getParentNode = ($tree, parent) ->
  if parent
    getNode($tree, parent)
  else
    getRootNode($tree)

expandNode = ($tree, id) -> $tree.tree('openNode', getNode($tree, id))

collapseNode = ($tree, id) -> $tree.tree('closeNode', getNode($tree, id))

####################################################################################################
## MODEL
####################################################################################################

class TreeModel

  constructor: (args) ->
    @collection = args.collection
    unless @collection
      throw new Error('No collection provided when creating tree data')
  
  getChildren: (doc) ->
    children = @collection.find({parent: doc._id}).fetch()
    children.sort(@compareDocs)
    children
  
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
    rootDocs.sort(@compareDocs)
    _.each rootDocs, (doc) =>
      datum = @docToNodeData(doc)
      data.push(datum)
    data

  compareDocs: (docA, docB) ->
    if docA.name < docB.name then -1 else 1

publicProperties =
  getDomNode: getDomNode
  getTemplate: getTemplate
  expandNode: expandNode
  collapseNode: collapseNode

_.extend(TemplateClass, publicProperties)
