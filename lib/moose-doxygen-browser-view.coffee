{View, $} = require "atom-space-pen-views"

module.exports =
  class DoxygenBrowserView extends View
    params: null

    @content: (params, self) ->
      doxyURL = "http://mooseframework.org/docs/doxygen/#{params.mode}/class#{params.className}.html"

      @div style: "width: 100%; height: 100%", =>
        @div class:"moose-doxygen inline",  =>
          @button "◀", outlet:"back", style:"float:left", class:"btn"
          @button "▶", outlet:"forward", style:"float:left", class:"btn"
        @tag "webview", src:"#{doxyURL}", useragent:"#{params.useragent}", outlet:"webview"

    initialize: (params, self) ->
      @params = params
      console.log "params", params
      console.log "@params", @params
      @self = self
      @back.on "click", =>
        @webview[0].goBack()
      @forward.on "click", =>
        @webview[0].goForward()

    getTitle: ->
      console.log "title", @params.className
      return @params.className

    getIconName: ->
      return "book"
