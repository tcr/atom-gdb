{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'
path = require 'path'
fs = require 'fs'

module.exports = AtomGdb =
  atomGdbView: null
  modalPanel: null
  subscriptions: null
  breakPoints: []
  config:
    debuggerCommand:
      type: 'string'
      default: 'qtcreator -client -debug'
    startupDirectory:
      type: 'string'
      default: '/home'
    executablePath:
      type: 'string'
      default: ''

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb:start': => @start()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'atom-gdb:toggle_breakpoint': => @toggle_breakpoint()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  start: ->
    console.log 'Starting debugger...'
    commandWords = atom.config.get('atom-gdb.debuggerCommand').split " "
    command = commandWords[0]
    args = commandWords[1..commandWords.length]
    args.push atom.config.get('atom-gdb.executablePath')
    stdout = (output) -> console.log("stdout:", output)
    stderr = (output) -> console.log("stderr:", output)
    exit = (return_code) -> console.log("Exit with ", return_code)
    process.chdir atom.config.get('atom-gdb.startupDirectory')
    childProcess = new BufferedProcess({command, args, stdout, stderr, exit})

  toggle_breakpoint: ->
    editor = atom.workspace.getActiveTextEditor()
    filename = path.basename(editor.getPath())
    row = editor.getCursorBufferPosition().row + 1
    @breakPoints.push {filename:filename, line:row}
    console.log("Added breakpoint:", filename, ":", row)
    @updateGdbInit()

  updateGdbInit: ->
    process.chdir atom.config.get('atom-gdb.startupDirectory')
    outputFile = fs.createWriteStream(".gdbinit")
    bps = @breakPoints
    outputFile.on 'open', (fd) ->
      outputFile.write "set breakpoint pending on\n"
      outputFile.write "b " + bp.filename + ":" + bp.line + "\n" for bp in bps
      outputFile.end()
      return
