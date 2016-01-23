Range = (ace.require 'ace/range')
ace.require 'ace/mode/markdown'
ace.require 'ace/theme/chrome'
ace.require 'ace/ext/language_tools'

_ = require 'lodash'

module.exports =
  Range: Range,
  addResult: (ed, results) ->
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
      ed.__ace_markers__.push m_id

  clearResults: (ed) ->
    if not ed? then return
    ed.getSession().clearAnnotations()
    markers = ed.__ace_markers__ || []
    _.each markers, (mid) -> ed.getSession().removeMarker mid
    ed.__ace_markers__ = []

  create: (element_id, value, options) ->
    value = value || ""
    options = options || {}
    editor = ace.edit(element_id);

    editor.$blockScrolling = Infinity
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

    editor.setValue(value, -1); #-1 so that the content won't be selected, see https://github.com/ajaxorg/ace/issues/1485
    editor.gotoLine(0);

    editor.setOptions {
      fontSize: "15pt"
      enableBasicAutocompletion: true
      enableLiveAutocompletion: true
    }

    editor.addResult = module.exports.addResult
    editor.clearResults = module.exports.clearResults

    editor.getSession().on "change", (delta)->
      options.plugins?.forEach (p) ->
        p editor, delta

    return editor
