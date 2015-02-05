TemplateClass = Template.tree

TemplateClass.created = ->
  data = @data
  items = data.items
  cursor = Collections.getCursor(items)
  @collection = Collections.get(items)
  @model = data.model ? new TreeModel(collection: @collection)
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
        console.log('added', newDoc)
        data = model.docToNodeData(newDoc, {children: false})
        sortResults = getSortedIndex($tree, newDoc)
        nextSiblingNode = sortResults.nextSiblingNode
        if nextSiblingNode
          $tree.tree('addNodeBefore', data, nextSiblingNode)
        else
          $tree.tree('appendNode', data, sortResults.parentNode)

      changed: (newDoc, oldDoc) ->
        console.log('changed', newDoc, oldDoc)
        node = getNode($tree, newDoc._id)
        # Only get one level of children and find their nodes. Children in deeper levels will be
        # updated by their own parents.
        data = model.docToNodeData(newDoc, {children: false})
        childDocs = model.getChildren(newDoc)
        data.children = _.map childDocs, (childDoc) ->
          getNode($tree, childDoc._id)
        $tree.tree('updateNode', node, data)
        parent = newDoc.parent
        if parent != oldDoc.parent
          sortResults = getSortedIndex($tree, newDoc)
          nextSiblingNode = sortResults.nextSiblingNode
          if nextSiblingNode
            $tree.tree('moveNode', node, nextSiblingNode, 'before')
          else
            $tree.tree('moveNode', node, sortResults.parentNode, 'inside')

      removed: (oldDoc) ->
        console.log('removed', oldDoc)
        node = getNode($tree, oldDoc._id)
        $tree.tree('removeNode', node)

####################################################################################################
## AUXILIARY
####################################################################################################

getDomNode = (template) ->
  unless template then throw new Error('No template provided')
  template.find('.tree')

getTemplate = (domNode) ->
  domNode = $(domNode)[0]
  unless domNode then throw new Error('No domNode provided')
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

getSortedIndex = ($tree, doc) ->
  template = getTemplate($tree)
  $tree = template.$tree
  model = template.model
  collection = template.collection
  parent = model.getParent(doc)
  parentNode = getParentNode($tree, parent)
  # This array will include the doc itself.
  siblings = model.getChildren(collection.findOne(parent))
  siblings.sort(model.compareDocs)
  maxIndex = siblings.length - 1
  sortedIndex = maxIndex
  _.some siblings, (sibling, i) ->
    if sibling._id == doc._id
      sortedIndex = i
  if siblings.length > 1 && sortedIndex != maxIndex
    nextSiblingDoc = siblings[sortedIndex + 1]
    nextSiblingNode = getNode($tree, nextSiblingDoc._id)
    # $tree.tree('addNodeBefore', data, nextSiblingNode)
  # else
    # $tree.tree('appendNode', data, parentNode)
  result =
    siblings: siblings
    maxIndex: maxIndex
    sortedIndex: sortedIndex
    nextSiblingNode: nextSiblingNode
    parentNode: parentNode

####################################################################################################
## MODEL
####################################################################################################

class TreeModel

  constructor: (args) ->
    @collection = args.collection
    unless @collection
      throw new Error('No collection provided when creating tree data')
  
  getChildren: (doc) ->
    # Search for root document if doc is undefined
    id = doc?._id ? null
    children = @collection.find({parent: id}).fetch()
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
