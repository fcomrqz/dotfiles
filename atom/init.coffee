atom.commands.add 'atom-text-editor',
  'custom:inline-comment':   ->
    atom.workspace.getActiveTextEditor()?.insertText('/* ? */')
