DoxygenBrowserView = null # require when needed
{CompositeDisposable} = require 'atom'
path = require 'path'
url = require 'url'

reMooseFramework = /\/moose\/framework\/(include|src)\/[^\/]+/
reMooseModules = /\/moose\/modules\/[^\/]+\/(include|src)\/[^\/]+/
reCFile = /^(.+)\.[Ch]$/

createDoxygenView = (mode, className) ->

  params = {
    mode: mode
    className: className.match(/^\/(.*)/)[1]
    useragent: atom.config.get("moose-doxygen.browser.useragent"),
  }

  DoxygenBrowserView ?= require "./moose-doxygen-browser-view"
  new DoxygenBrowserView params, this

module.exports =

  view: null
  browserView: null
  subscriptions: null

  config:
    browser:
      type: "object"
      properties:
        position:
          default: "right"
          type: "string"
          enum: ["top", "right", "bottom", "left"]
        size:
          type: "integer"
          default: 600
        useragent:
          type: "string"
          description: "default is iOS9 for iPhone."
          default: "Mozilla/5.0 (iPhone; CPU iPhone OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A344 Safari/601.1"

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'moose-doxygen:open': => @open()

    atom.deserializers.add
      name: 'DoxygenBrowserView'
      deserialize: (uriToOpen) ->
        {protocol, host, pathname} = url.parse(uriToOpen)
        createDoxygenView host, pathname

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'moose-doxygen:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      createDoxygenView host, pathname

  open: ->
    # get the current file name and path
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    file = editor.getPath()
    filePath = path.dirname file
    fileName = path.basename file

    # only process .h and .C files
    match = fileName.match reCFile
    return if not match
    fileRoot = match[1]

    # are we in framework?
    if filePath.match reMooseFramework
      mode = 'moose'
    else if filePath.match reMooseModules
      mode = 'modules'
    else
      atom.notifications.addError 'Not a recognized MOOSE path.', dismissable: true
      return

    atom.workspace.open "moose-doxygen://#{mode}/#{fileRoot}",
      searchAllPanes: true
      split: atom.config.get "moose-doxygen.browser.position"

  deactivate: ->
    @browserPanel.destroy()
    @subscriptions.dispose()
    @view.destroy()

  browserHide: ->
    @browserPanel?.hide()
    @browserPanel = null
