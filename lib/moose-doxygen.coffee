DoxygenBrowserView = null # require when needed
{CompositeDisposable} = require 'atom'
path = require 'path'

reMooseFramework = /\/moose\/framework\/(include|src)\/[^\/]+/
reMooseModules = /\/moose\/modules\/[^\/]+\/(include|src)\/[^\/]+/
reCFile = /^(.+)\.[Ch]$/

module.exports =

  view: null
  browserPanel: null
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
      doxyURL = "http://mooseframework.org/docs/doxygen/moose/class#{fileRoot}.html"
    else if filePath.match reMooseModules
      doxyURL = "http://mooseframework.org/docs/doxygen/modules/class#{fileRoot}.html"
    else
      atom.notifications.addError 'Not a recognized MOOSE path.', dismissable: true
      return

    position = atom.config.get("moose-doxygen.browser.position")
    params = {
      url: doxyURL,
      size: atom.config.get("moose-doxygen.browser.size"),
      useragent: atom.config.get("moose-doxygen.browser.useragent"),
      position: position
    }

    DoxygenBrowserView ?= require "./moose-doxygen-browser-view"
    @view = new DoxygenBrowserView params, this

    @browserPanel = switch position
      when "top"    then atom.workspace.addTopPanel item: @view
      when "right"  then atom.workspace.addRightPanel item: @view
      when "bottom" then atom.workspace.addBottomPanel item: @view
      when "left"   then atom.workspace.addLeftPanel item: @view

  deactivate: ->
    @browserPanel.destroy()
    @subscriptions.dispose()
    @view.destroy()

  browserHide: ->
    @browserPanel?.hide()
    @browserPanel = null
