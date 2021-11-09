atom.commands.add 'atom-text-editor',
  'custom:inline-comment':   ->
    atom.workspace.getActiveTextEditor()?.insertText('/* ? */')

atom.commands.add 'atom-workspace',
  'custom-tree-view:toggle': ->
    treeView = atom.packages.getActivePackage("tree-view").mainModule.getTreeViewInstance()
    if treeView.isVisible()
      treeView.toggleFocus()
    else
      treeView.toggle()
      treeView.toggleFocus()

atom.commands.add 'atom-workspace',
  'custom:hide': ->
    if atom.workspace.getRightDock().isVisible()
      treeView = atom.packages.getActivePackage("tree-view").mainModule.getTreeViewInstance()
      if treeView.isVisible()
        treeView.toggle()
      else
        atom.commands.dispatch atom.workspace.getElement(), 'github:toggle-git-tab'
