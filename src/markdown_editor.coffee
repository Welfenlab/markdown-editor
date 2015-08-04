Ace = require 'brace'
Range = Ace.acequire 'ace/range'
require 'brace/mode/markdown'
require 'brace/theme/chrome'
require 'brace/ext/language_tools'

_ = require 'lodash'

module.exports =
  create: (element_id, value, options) ->
    value = value || ""
    options = options || {}
    editor = ace.edit(element_id);

    editor.setTheme 'ace/theme/chrome'
    editor.getSession().setMode 'ace/mode/markdown'
    ### this is tutor app logic .. move it there
    if ko.isObservable(options.readOnly)
      options.readOnly.subscribe (v) => editor.setReadOnly(v)
      editor.setReadOnly(options.readOnly())
    ###
    if options.readOnly
      editor.setReadOnly(true)
    if options.maxLines
      editor.setOptions
        maxLines: options.maxLines
    else
      editor.setOptions
        maxLines: "Infinity"

    editor.setValue(value);
    editor.gotoLine(0);


    #editor.renderer.setShowGutter false
    editor.setOptions {
      fontSize: "15pt"
      enableBasicAutocompletion: true
      enableLiveAutocompletion: true
    }

    editor.addResult = (results) ->
      ed = editor
      annos = ed.getSession().getAnnotations()
      for result in results
        annos.push
          row: result.lineNumber
          column: result.column
          text: result.description
          type: result.type

      ed.getSession().setAnnotations annos

      for result in results
        rng = new Range.Range result.lineNumber, result.column-1,
            result.lineNumber, result.column + result.length - 1
        m_id = ed.getSession().addMarker rng, result.type, "background"
        ed.__ko_ace_markers__.push m_id

    editor.clearResults = ->
      ed = editor
      if not ed? then return
      ed.getSession().clearAnnotations()
      markers = ed.__ko_ace_markers__ || []
      _.each markers, (mid) -> ed.getSession().removeMarker mid
      ed.__ko_ace_markers__ = []

    editor.getSession().on "change", (delta)->
      options.plugins?.forEach (p) ->
        p editor, delta

    return editor