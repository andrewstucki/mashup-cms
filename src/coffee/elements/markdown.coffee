getScrollHeight = ($prevFrame) ->
  
  if $prevFrame[0].scrollHeight isnt `undefined`
    $prevFrame[0].scrollHeight
  else if $prevFrame.find("html")[0].scrollHeight isnt `undefined` and $prevFrame.find("html")[0].scrollHeight isnt 0
    $prevFrame.find("html")[0].scrollHeight
  else
    $prevFrame.find("body")[0].scrollHeight

syncPreview = ->
  $ed = window.ace.edit("editor")
  $prev = $("#preview")
  editorScrollRange = ($ed.getSession().getLength())
  previewScrollRange = (getScrollHeight($prev))
  
  scrollFactor = $ed.getFirstVisibleRow() / editorScrollRange
  
  $prev.scrollTop scrollFactor * previewScrollRange
  return

$ ->
  asyncLoad = (filename, cb) ->
    ((d, t) ->
      leScript = d.createElement(t)
      scripts = d.getElementsByTagName(t)[0]
      leScript.async = 1
      leScript.src = filename
      scripts.parentNode.insertBefore leScript, scripts
      leScript.onload = ->
        cb and cb()
        return

      return
    ) document, "script"
    return

  hasLocalStorage = ->
    storage = undefined
    try
      storage = localStorage  if localStorage.getItem
    storage

  getUserProfile = ->
    p = undefined
    try
      p = JSON.parse(localStorage.profile)
      p = $.extend(true, profile, p)
    catch e
      p = profile
    profile = p
    return

  updateUserProfile = (obj) ->
    localStorage.clear()
    localStorage.profile = JSON.stringify($.extend(true, profile, obj))
    return

  prefixed = (prop) ->
    testPropsAll prop, "pfx"

  testProps = (props, prefixed) ->
    for i of props
      return (if prefixed is "pfx" then props[i] else true)  if dillingerStyle[props[i]] isnt `undefined`
    false

  testPropsAll = (prop, prefixed) ->
    ucProp = prop.charAt(0).toUpperCase() + prop.substr(1)
    props = (prop + " " + domPrefixes.join(ucProp + " ") + ucProp).split(" ")
    testProps props, prefixed

  normalizeTransitionEnd = ->
    transEndEventNames =
      WebkitTransition: "webkitTransitionEnd"
      MozTransition: "transitionend"
      OTransition: "oTransitionEnd"
      msTransition: "msTransitionEnd"
      transition: "transitionend"

    transEndEventNames[prefixed("transition")]

  generateRandomFilename = (ext) ->
    "dillinger_" + (new Date()).toISOString().replace(/[\.:-]/g, "_") + "." + ext

  getCurrentFilenameFromField = ->
    $("#filename > span[contenteditable=\"true\"]").text()

  setCurrentFilenameField = (str) ->
    $("#filename > span[contenteditable=\"true\"]").text str or profile.current_filename or "Untitled Document"
    return

  getTextInElement = (node) ->
    return node.data  if node.nodeType is 3
    txt = ""
    if node = node.firstChild
      loop
        txt += getTextInElement(node)
        break unless node = node.nextSibling
    txt

  countWords = (string) ->
    words = string.replace(/W+/g, " ").match(/\S+/g)
    words and words.length or 0

  init = ->
    unless hasLocalStorage()
      sadPanda()
    else
      $.support.transitionEnd = normalizeTransitionEnd()
      getUserProfile()
      initAce()
      initUi()
      marked.setOptions
        gfm: true
        tables: true
        pedantic: false
        sanitize: false
        smartLists: true
        smartypants: false
        langPrefix: "lang-"

      converter = marked
      bindPreview()
      bindNav()
      bindKeyboard()
      bindDelegation()
      bindFilenameField()
      bindWordCountEvents()
      autoSave()
      initWordCount()
      refreshWordCount()
    return

  initAce = ->
    editor = ace.edit("editor")
    return

  initUi = ->
    fetchTheme profile.theme, ->
      $theme.find("li > a[data-value=\"" + profile.theme + "\"]").addClass "selected"
      editor.getSession().setUseWrapMode true
      editor.setShowPrintMargin false
      editor.getSession().setMode "ace/mode/markdown"
      editor.getSession().setValue profile.currentMd or editor.getSession().getValue()
      previewMd()
      return

    $preview.css "backgroundImage", (if profile.showPaper then "url(\"" + paperImgPath + "\")" else "url(\"\")")
    $autosave.html (if profile.autosave.enabled then "<i class=\"icon-remove\"></i>&nbsp;Disable Autosave" else "<i class=\"icon-ok\"></i>&nbsp;Enable Autosave")
    $wordcount.html (if not profile.wordcount then "<i class=\"icon-remove\"></i>&nbsp;Disabled Word Count" else "<i class=\"icon-ok\"></i>&nbsp;Enabled Word Count")
    githubUser = $import_github.attr("data-github-username")
    githubUser and Notifier.showMessage("What's Up " + githubUser, 1000)
    setCurrentFilenameField()
    $(".dropdown-toggle").dropdown()
    return

  clearSelection = ->
    editor.getSession().setValue ""
    previewMd()
    return

  saveFile = (isManual) ->
    updateUserProfile currentMd: editor.getSession().getValue()
    isManual and Notifier.showMessage(Notifier.messages.docSavedLocal)
    return

  autoSave = ->
    if profile.autosave.enabled
      autoInterval = setInterval(->
        saveFile()
        return
      , profile.autosave.interval)
    else
      clearInterval autoInterval
    return

  resetProfile = ->
    localStorage.clear()
    profile.autosave.enabled = false
    delete localStorage.profile

    window.location.reload()
    return

  changeTheme = (e) ->
    $target = $(e.target)
    if $target.attr("data-value") is profile.theme
      return
    else
      $theme.find("li > a.selected").removeClass "selected"
      $target.addClass "selected"
      newTheme = $target.attr("data-value")
      $(e.target).blur()
      fetchTheme newTheme, ->
        Notifier.showMessage Notifier.messages.profileUpdated
        return

    return

  fetchTheme = (th, cb) ->
    name = th.split("/").pop()
    asyncLoad "/js/theme-" + name + ".js", ->
      editor.setTheme th
      cb and cb()
      updateBg name
      updateUserProfile theme: th
      return

    return

  updateBg = (name) ->
    document.body.style.backgroundColor = bgColors[name]
    return

  previewMd = ->
    unmd = editor.getSession().getValue()
    md = converter(unmd)
    $preview.html("").html md
    refreshWordCount()
    return

  refreshWordCount = (selectionCount) ->
    msg = "Words: "
    msg += selectionCount + " of "  if selectionCount isnt `undefined`
    $wordcounter.text msg + countWords(getTextInElement($preview[0]))  if profile.wordcount
    return

  updateFilename = (str) ->
    f = undefined
    if typeof str is "string"
      f = str
    else
      f = getCurrentFilenameFromField()
    updateUserProfile current_filename: f
    return

  fetchMarkdownFile = ->
    _doneHandler = (a, b, response) ->
      a = b = null
      resp = JSON.parse(response.responseText)
      document.getElementById("downloader").src = "/files/md/" + resp.data
      return
    _failHandler = ->
      alert "Roh-roh. Something went wrong. :("
      return
    unmd = editor.getSession().getValue()
    mdConfig =
      type: "POST"
      data: "unmd=" + encodeURIComponent(unmd)
      dataType: "json"
      url: "/factory/fetch_markdown"
      error: _failHandler
      success: _doneHandler

    $.ajax mdConfig
    return

  fetchHtmlFile = ->
    _doneHandler = (jqXHR, data, response) ->
      resp = JSON.parse(response.responseText)
      document.getElementById("downloader").src = "/files/html/" + resp.data
      return
    _failHandler = ->
      alert "Roh-roh. Something went wrong. :("
      return
    unmd = editor.getSession().getValue()
    config =
      type: "POST"
      data: "unmd=" + encodeURIComponent(unmd)
      dataType: "json"
      url: "/factory/fetch_html"
      error: _failHandler
      success: _doneHandler

    $.ajax config
    return

  fetchPdfFile = ->
    _doneHandler = (jqXHR, data, response) ->
      resp = JSON.parse(response.responseText)
      document.getElementById("downloader").src = "/files/pdf/" + resp.data
      return
    _failHandler = ->
      alert "Roh-roh. Something went wrong. :("
      return
    unmd = editor.getSession().getValue()
    config =
      type: "POST"
      data: "unmd=" + encodeURIComponent(unmd)
      dataType: "json"
      url: "/factory/fetch_pdf"
      error: _failHandler
      success: _doneHandler

    $.ajax config
    return

  showHtml = ->
    _doneHandler = (jqXHR, data, response) ->
      resp = JSON.parse(response.responseText)
      textarea = $("#modalBodyText")
      $(textarea).val resp.data
      $("#myModal").on("shown.bs.modal", (e) ->
        $(textarea).focus().select()
        return
      ).modal()
      return
    _failHandler = ->
      alert "Roh-roh. Something went wrong. :("
      return
    unmd = editor.getSession().getValue()
    config =
      type: "POST"
      data: "unmd=" + encodeURIComponent(unmd)
      dataType: "json"
      url: "/factory/fetch_html_direct"
      error: _failHandler
      success: _doneHandler

    $.ajax config
    return

  sadPanda = ->
    alert "Sad Panda - No localStorage for you!"
    return

  showAboutInfo = ->
    $(".modal-header h3").text "What's the deal with Dillinger?"
    aboutContent = "<p>Dillinger is an online cloud-enabled, HTML5, buzzword-filled Markdown editor.</p>" + "<p>Dillinger was designed and developed by <a href='http://twitter.com/joemccann'>@joemccann</a> because he needed a decent Markdown editor.</p>" + "<p>Dillinger is a 100% open source project so <a href='https://github.com/joemccann/dillinger'>fork the code</a> and contribute!</p>" + "<p>Follow Dillinger on Twitter at <a href='http://twitter.com/dillingerapp'>@dillingerapp</a></p>" + "<p>Follow Joe McCann on Twitter at <a href='http://twitter.com/joemccann'>@joemccann</a></p>"
    $(".modal-body").html aboutContent
    $("#modal-generic").modal
      keyboard: true
      backdrop: true
      show: true

    return

  showPreferences = ->
    $(".modal-header h3").text "Preferences"
    prefContent = "<div>" + "<ul>" + "<li><a href=\"#\" id=\"paper\">Toggle Paper</a></li>" + "<li><a href=\"#\" id=\"reset\">Reset Profile</a></li>" + "</ul>" + "</div>"
    $(".modal-body").html prefContent
    $("#modal-generic").modal
      keyboard: true
      backdrop: true
      show: true

    return

  togglePaper = ->
    $preview.css "backgroundImage", (if not profile.showPaper then "url(\"" + paperImgPath + "\")" else "url(\"\")")
    updateUserProfile showPaper: not profile.showPaper
    Notifier.showMessage Notifier.messages.profileUpdated
    return

  toggleAutoSave = ->
    $autosave.html (if profile.autosave.enabled then "<i class=\"icon-remove\"></i>&nbsp;Disable Autosave" else "<i class=\"icon-ok\"></i>&nbsp;Enable Autosave")
    updateUserProfile autosave:
      enabled: not profile.autosave.enabled

    autoSave()
    return

  initWordCount = ->
    if profile.wordcount
      $wordcounter.removeClass "hidden"
      $filename.addClass "show-word-count-filename-adjust"
    else
      $wordcounter.addClass "hidden"
      $filename.removeClass "show-word-count-filename-adjust"
    return

  toggleWordCount = ->
    $wordcount.html (if profile.wordcount then "<i class=\"icon-remove\"></i>&nbsp;Disabled Word Count" else "<i class=\"icon-ok\"></i>&nbsp;Enabled Word Count")
    updateUserProfile wordcount: not profile.wordcount
    initWordCount()
    return

  bindFilenameField = ->
    $("#filename > span[contenteditable=\"true\"]").bind "keyup", updateFilename
    return

  bindWordCountEvents = ->
    $preview.bind "mouseup", checkForSelection
    return

  checkForSelection = ->
    if profile.wordcount
      selection = window.getSelection().toString()
      if selection isnt ""
        refreshWordCount countWords(selection)
      else
        refreshWordCount()
    return

  bindPreview = ->
    $("#editor").bind "keyup", previewMd
    return

  bindNav = ->
    $theme.find("li > a").bind "click", (e) ->
      changeTheme e
      false

    $("#clear").on "click", ->
      clearSelection()
      false

    $(".modal-body").delegate "#paper", "click", ->
      togglePaper()
      false

    $("#autosave").on "click", ->
      toggleAutoSave()
      false

    $("#wordcount").on "click", ->
      toggleWordCount()
      false

    $("#reset").on "click", ->
      resetProfile()
      false

    $import_github.on "click", ->
      Github.fetchRepos()
      false

    $("#export_md").on "click", ->
      fetchMarkdownFile()
      $(".dropdown").removeClass "open"
      false

    $("#export_html").on "click", ->
      fetchHtmlFile()
      $(".dropdown").removeClass "open"
      false

    $("#export_pdf").on "click", ->
      fetchPdfFile()
      $(".dropdown").removeClass "open"
      false

    $("#show_html").on "click", ->
      showHtml()
      $(".dropdown").removeClass "open"
      false

    $("#preferences").on "click", ->
      showPreferences()
      false

    $("#about").on "click", ->
      showAboutInfo()
      false

    $("#cheat").on "click", ->
      window.open "https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet", "_blank"
      false

    $("#new_local_file").on "click", ->
      $(".dropdown").removeClass "open"
      LocalFiles.newFile()
      false

    $("#import_local_file").on "click", ->
      $(".dropdown").removeClass "open"
      LocalFiles.search()
      false

    $("#save_local_file").on "click", ->
      $(".dropdown").removeClass "open"
      LocalFiles.saveFile()
      false

    return

  bindKeyboard = ->
    key "command+s, ctrl+s", (e) ->
      saveFile true
      e.preventDefault()
      return

    saveCommand =
      name: "save"
      bindKey:
        mac: "Command-S"
        win: "Ctrl-S"

      exec: ->
        saveFile true
        return

    fileForUrlNamer =
      name: "filenamer"
      bindKey:
        mac: "Command-Shift-M"
        win: "Ctrl-Shift-M"

      exec: ->
        profile = JSON.parse(localStorage.profile)
        alert profile.current_filename.replace(/\s/g, "-").toLowerCase()
        return

    editor.commands.addCommand saveCommand
    editor.commands.addCommand fileForUrlNamer
    return

  bindDelegation = ->
    $(document).on("click", ".repo", ->
      repoName = $(this).parent("li").attr("data-repo-name")
      Github.isRepoPrivate = (if $(this).parent("li").attr("data-repo-private") is "true" then true else false)
      Github.fetchBranches repoName
      false
    ).on("click", ".branch", ->
      repo = $(this).parent("li").attr("data-repo-name")
      sha = $(this).parent("li").attr("data-commit-sha")
      Github.currentBranch = $(this).text()
      Github.fetchTreeFiles repo, sha
      false
    ).on("click", ".tree_file", ->
      file = $(this).parent("li").attr("data-tree-file")
      Github.fetchMarkdownFile file
      false
    ).on("click", ".local_file", ->
      fileName = $(this).parent("li").attr("data-file-name")
      profile.current_filename = $(this).html()
      LocalFiles.loadFile fileName
      false
    ).on "click", ".delete_local_file", ->
      $parentLi = $(this).parent("li")
      fileName = $parentLi.attr("data-file-name")
      LocalFiles.deleteFile fileName
      $parentLi.remove()
      false

    if "draggable" of document.createElement("span")
      $("#editor").on("dragover", (e) ->
        e.preventDefault()
        e.stopPropagation()
        return
      ).on "drop", (e) ->
        e.preventDefault()
        e.stopPropagation()
        originalEvent = e.originalEvent
        files = originalEvent.target.files or originalEvent.dataTransfer.files
        reader = new FileReader()
        i = 0
        file = undefined
        name = undefined
        loop
          file = files[i++]
          break unless file and file.type.substr(0, 4) isnt "text" and file.name.substr(file.name.length - 3) isnt ".md"
        unless file
          return reader.onload = (lE) ->
            editor.getSession().setValue lE.target.result
            previewMd()
            return
        reader.readAsText file
        return

    return
  editor = undefined
  converter = undefined
  autoInterval = undefined
  githubUser = undefined
  paperImgPath = "/img/notebook_paper_200x200.gif"
  profile =
    theme: "ace/theme/idle_fingers"
    showPaper: false
    currentMd: ""
    autosave:
      enabled: true
      interval: 3000

    wordcount: true
    current_filename: "Untitled Document"
    dropbox:
      filepath: "/Dillinger/"

    local_files:
      "Untitiled Document": ""

  dillinger = "dillinger"
  dillingerElem = document.createElement(dillinger)
  dillingerStyle = dillingerElem.style
  domPrefixes = "Webkit Moz O ms Khtml".split(" ")
  $theme = $("#theme-list")
  $preview = $("#preview")
  $autosave = $("#autosave")
  $wordcount = $("#wordcount")
  $import_github = $("#import_github")
  $wordcounter = $("#wordcounter")
  $filename = $("#filename")
  bgColors =
    chrome: "#bbbbbb"
    clouds: "#7AC9E3"
    clouds_midnight: "#5F9EA0"
    cobalt: "#4d586b"
    crimson_editor: "#ffffff"
    dawn: "#DADCAD"
    eclipse: "#6C7B8A"
    idle_fingers: "#DEB887"
    kr_theme: "#434343"
    merbivore: "#3E353E"
    merbivore_soft: "#565156"
    mono_industrial: "#C0C0C0"
    monokai: "#F5DEB3"
    pastel_on_dark: "#676565"
    "solarized-dark": "#0E4B5A"
    solarized_light: "#dfcb96"
    textmate: "#fff"
    tomorrow: "#0e9211"
    tomorrow_night: "#333536"
    tomorrow_night_blue: "#3a4150"
    tomorrow_night_bright: "#3A3A3A"
    tomorrow_night_eighties: "#474646"
    twilight: "#534746"
    vibrant_ink: "#363636"

  Notifier = (->
    _el = $("#notify")
    messages:
      profileUpdated: "Profile updated"
      profileCleared: "Profile cleared"
      docSavedLocal: "Document saved locally"
      docDeletedLocal: "Document deleted from local storage"
      docSavedServer: "Document saved on our server"
      dropboxImportNeeded: "Please import a file from dropbox first."

    showMessage: (msg, delay) ->
      _el.text("").stop().text(msg).slideDown 250, ->
        _el.delay(delay or 1000).slideUp 250
        return

      return
  )()

  Github = (->
    _alphaNumSort = (m, n) ->
      a = m.url.toLowerCase()
      b = n.url.toLowerCase()
      return 0  if a is b
      if isNaN(m) or isNaN(n)
        (if a > b then 1 else -1)
      else
        m - n
    _isMdFile = (file) ->
      (/(\.md)|(\.markdown)/i).test file
    _extractMdFiles = (repoName, treefiles) ->
      sorted = []
      raw = "https://raw.github.com"
      slash = "/"
      treefiles.forEach (el) ->
        if _isMdFile(el.path)
          fullpath = undefined
          if Github.isRepoPrivate
            fullpath = el.url
          else
            fullpath = raw + slash + githubUser + slash + repoName + slash + Github.currentBranch + slash + el.path
          item =
            link: fullpath
            path: el.path
            sha: el.sha

          sorted.push item
        return

      sorted
    _listRepos = (repos) ->
      list = "<ul>"
      repos.sort _alphaNumSort
      repos.forEach (item) ->
        list += "<li data-repo-name=\"" + item.name + "\" data-repo-private=\"" + item.private + "\"><a class=\"repo\" href=\"#\">" + item.name + "</a></li>"
        return

      list += "</ul>"
      $(".modal-header h3").text "Your Github Repos"
      $(".modal-body").html list
      $("#modal-generic").modal
        keyboard: true
        backdrop: true
        show: true

      false
    _listBranches = (repoName, branches) ->
      list = ""
      branches.forEach (item) ->
        name = item.name
        commit = item.commit.sha
        list += "<li data-repo-name=\"" + repoName + "\" data-commit-sha=\"" + commit + "\"><a class=\"branch\" href=\"#\">" + name + "</a></li>"
        return

      $(".modal-header h3").text repoName
      $(".modal-body").find("ul").find("li").remove().end().append list
      return
    _listTreeFiles = (repoName, treefiles) ->
      mdFiles = _extractMdFiles(repoName, treefiles)
      list = ""
      mdFiles.forEach (item) ->
        list += (if Github.isRepoPrivate then "<li data-tree-file-sha=\"" + item.sha + "\" data-tree-file=\"" + item.link + "\" class=\"private_repo\"><a class=\"tree_file\" href=\"#\">" + item.path + "</a></li>" else "<li data-tree-file=\"" + item.link + "\"><a class=\"tree_file\" href=\"#\">" + item.path + "</a></li>")
        return

      $(".modal-header h3").text repoName
      $(".modal-body").find("ul").find("li").remove().end().append list
      return
    currentBranch: ""
    isRepoPrivate: false
    fetchRepos: ->
      _beforeSendHandler = ->
        Notifier.showMessage "Fetching Repos..."
        return
      _doneHandler = (a, b, response) ->
        a = b = null
        response = JSON.parse(response.responseText)
        unless response.length
          Notifier.showMessage "No repos available!"
        else
          _listRepos response
        return
      _failHandler = (resp, err) ->
        alert resp.responseText or "Roh-roh. Something went wrong. :("
        return
      config =
        type: "POST"
        dataType: "text"
        url: "/import/github/repos"
        beforeSend: _beforeSendHandler
        error: _failHandler
        success: _doneHandler

      $.ajax config
      return

    fetchBranches: (repoName) ->
      _beforeSendHandler = ->
        Notifier.showMessage "Fetching Branches for Repo " + repoName
        return
      _doneHandler = (a, b, response) ->
        a = b = null
        response = JSON.parse(response.responseText)
        unless response.length
          Notifier.showMessage "No branches available!"
          $("#modal-generic").modal "hide"
        else
          _listBranches repoName, response
        return
      _failHandler = ->
        alert "Roh-roh. Something went wrong. :("
        return
      config =
        type: "POST"
        dataType: "json"
        data: "repo=" + repoName
        url: "/import/github/branches"
        beforeSend: _beforeSendHandler
        error: _failHandler
        success: _doneHandler

      $.ajax config
      return

    fetchTreeFiles: (repoName, sha) ->
      _beforeSendHandler = ->
        Notifier.showMessage "Fetching Tree for Repo " + repoName
        return
      _doneHandler = (a, b, response) ->
        a = b = null
        response = JSON.parse(response.responseText)
        unless response.tree.length
          Notifier.showMessage "No tree files available!"
          $("#modal-generic").modal "hide"
        else
          _listTreeFiles repoName, response.tree
        return
      _failHandler = ->
        alert "Roh-roh. Something went wrong. :("
        return
      config =
        type: "POST"
        dataType: "json"
        data: "repo=" + repoName + "&sha=" + sha
        url: "/import/github/tree_files"
        beforeSend: _beforeSendHandler
        error: _failHandler
        success: _doneHandler

      $.ajax config
      return

    fetchMarkdownFile: (filename) ->
      _doneHandler = (a, b, response) ->
        a = b = null
        response = JSON.parse(response.responseText)
        if response.error
          Notifier.showMessage "No markdown for you!"
          $("#modal-generic").modal "hide"
        else
          $("#modal-generic").modal "hide"
          editor.getSession().setValue response.data
          name = filename.split("/").pop()
          updateFilename name
          setCurrentFilenameField name
          previewMd()
        return
      _failHandler = ->
        alert "Roh-roh. Something went wrong. :("
        return
      _alwaysHandler = ->
        $(".dropdown").removeClass "open"
        return
      config =
        type: "POST"
        dataType: "json"
        data: "mdFile=" + filename
        url: "/import/github/file"
        error: _failHandler
        success: _doneHandler
        complete: _alwaysHandler

      $.ajax config
      return
  )()

  LocalFiles = (->
    _alphaNumSort = (m, n) ->
      a = m.toLowerCase()
      b = n.toLowerCase()
      return 0  if a is b
      if isNaN(m) or isNaN(n)
        (if a > b then 1 else -1)
      else
        m - n
    _listMdFiles = (files) ->
      list = "<ul>"
      files.sort _alphaNumSort
      files.forEach (item) ->
        list += "<li data-file-name=\"" + item + "\"><a class=\"delete_local_file\"><i class=\"icon-remove\"></i></a><a class=\"local_file\" href=\"#\">" + item + "</a></li>"
        return

      list += "</ul>"
      $(".modal-header h3").text "Your Local Files"
      $(".modal-body").html list
      $("#modal-generic").modal
        keyboard: true
        backdrop: true
        show: true

      false
    newFile: ->
      updateFilename ""
      setCurrentFilenameField()
      editor.getSession().setValue ""
      return

    search: ->
      fileList = Object.keys(profile.local_files)
      if fileList.length < 1
        Notifier.showMessage "No files saved locally"
      else
        _listMdFiles fileList
      return

    loadFile: (fileName) ->
      $("#modal-generic").modal "hide"
      updateFilename fileName
      setCurrentFilenameField()
      editor.getSession().setValue profile.local_files[fileName]
      previewMd()
      return

    saveFile: ->
      fileName = getCurrentFilenameFromField()
      md = editor.getSession().getValue()
      saveObj = local_files: {}
      saveObj.local_files[fileName] = md
      updateUserProfile saveObj
      Notifier.showMessage Notifier.messages.docSavedLocal
      return

    deleteFile: (fileName) ->
      files = profile.local_files
      delete profile.local_files[fileName]

      updateUserProfile()
      Notifier.showMessage Notifier.messages.docDeletedLocal
      return
  )()
  window.foo = LocalFiles.saveFile
  init()
  return

window.onload = ->
  $loading = $("#loading")
  if $.support.transition
    $loading.bind($.support.transitionEnd, ->
      $("#main").removeClass "bye"
      $loading.remove()
      return
    ).addClass "fade_slow"
  else
    $("#main").removeClass "bye"
    $loading.remove()
  
  window.ace.edit("editor").session.on "changeScrollTop", syncPreview
  window.ace.edit("editor").session.selection.on "changeCursor", syncPreview
  return