TemplateClass = Template.tree

TemplateClass.rendered = ->
  data = @data
  

TemplateClass.createData = (docs, args) ->
  collection = Collections.get(docs)
  docs = Collections.getItems(docs)
  args = _.extend({
    getChildren: (doc) -> collection.find({parent: doc._id}).fetch()
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
  
  collection ?= args.collection
  unless collection
    throw new Error('No collection found when generating tree data')
  
  data = []
  rootDocs = _.filter docs, (doc) -> !args.hasParent(doc)
  _.each rootDocs, (doc) ->
    datum = args.toData(doc)
    data.push(datum)
  data
