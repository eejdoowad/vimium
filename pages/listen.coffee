message = document.createElement "div"
message.setAttribute "id", "message"
message.innerText = 'Hello World';

tmp = ->
  for x in [1..3]
    unless true
      false
    else
      false

promptMessage = (msg, phrases) ->
  console.log(msg)
  message.innerHTML = "#{msg} or: #{phrases}"
  document.body.appendChild message
  setTimeout (-> message.remove()), 3000


validCommand = (msg) ->
  return msg of voiceToCommandMap || msg.split(" ")[0] in commandVoiceTriggers.type || msg.split(" ")[0] in (commandVoiceTriggers.activateLinkHint.concat commandVoiceTriggers.tryLink)

sendCommand = (msg, tab) ->
  return unless validCommand msg

  command =
    if msg of voiceToCommandMap
      voiceToCommandMap[msg]
    else
      word1 = msg.split(" ")[0]
      if word1 in commandVoiceTriggers.type
        "type"
      else if word1 in commandVoiceTriggers.activateLinkHint
        "activateLinkHint"
      else if word1 in commandVoiceTriggers.tryLink
        "tryLink"
      else
        "noop" 

  
  background = commandDescriptions[command][1]?.background?
  topFrame = commandDescriptions[command][1]?.topFrame?
  noRepeat = commandDescriptions[command][1]?.noRepeat?
  repeatLimit = commandDescriptions[command][1]?.repeatLimit
  console.log(background, topFrame, noRepeat, repeatLimit)

  registryEntry =
    command: command
    description: "N/A"
    options: {}

  registryEntry.background = true if background
  registryEntry.topframe = true if topFrame
  registryEntry.noRepeat = true if noRepeat
  registryEntry.repeatLimit = repeatLimit if repeatLimit
  
  request = null
  if topFrame
    request = 
      voiceCommand: true
      handler: "sendMessageToFrames"
      message:
        name: "runInTopFrame"
        sourceFrameId: 0 # TODO
        registryEntry: registryEntry
      # following fields previously populated from MessageSender
      tab: tab
      tabId: tab.id # needed only by duplicateTab for some reason
      # frameID: ?
    chrome.runtime.sendMessage request
  else if background
    request =
      voiceCommand: true
      handler: "runBackgroundCommand"
      count: 1
      registryEntry: registryEntry
      # following fields previously populated from MessageSender
      tab: tab
      tabId: tab.id # needed only by duplicateTab for some reason
      # frameID: ?
    chrome.runtime.sendMessage request
  else
    request =
      voiceCommand: true
      count: 1
      registryEntry: registryEntry
      # frameID: ?
    if command == "type"
      request["letters"] = msg.substr ((msg.indexOf " ") + 1)
    else if command == "activateLinkHint" || command == "tryLink"
      request["matchString"] = msg.substr ((msg.indexOf " ") + 1)
    
    # MONKEY PATCHING for trylink
    if  command == "tryLink"
      # first activate link hints
      registryEntry.command = "LinkHints.activateMode"
      chrome.tabs.sendMessage tab.id, request
      registryEntry.command = "tryLink"
      # then activate link, but not immediately (allow link hints to activate first)
      f = () -> chrome.tabs.sendMessage tab.id, request
      setTimeout(f, 0)

    # default behavior for everything else
    else
      chrome.tabs.sendMessage tab.id, request

if annyang
  annyang.addCommands {"*msg": ->}
  annyang.addCallback "resultMatch", (userSaid, commandText, phrases)->
    userSaid = userSaid.toLowerCase()
    # log the message
    BgUtils.log userSaid
    promptMessage userSaid, phrases
    # send it to the active tab
    chrome.tabs.query { active: true, currentWindow: true },
      (tabs) ->
        # send prompt message to top frame (frameId=0) of  active page
        chrome.tabs.sendMessage tabs[0].id,
          { msg: userSaid, phrases: phrases}, {frameId: 0}

        sendCommand(userSaid, tabs[0])

  annyang.start();

commandVoiceTriggers = 
  tryLink: ["try", "tri", "trike", "tribe"]
  search: ["search"]
  noop: ["nothing", "noop"]
  runEscape: ["escape", "oops", "oopsie"]
  type: ["type", "hey", "hi"]
  activateLinkHint: ["activate"]

  showHelp: ["info", "commands", "help", "i'm confused", "how does this work", "health"]
  scrollDown: ["scroll down"]
  scrollUp: ["scroll up"]
  scrollLeft: ["scroll left", "go left"]
  scrollRight: ["scroll right", "go right"]

  scrollToTop: ["top", "thai", "girl talk", "scroll top", "girl top", "scroll to the top of the page", "top of the page", "go to the top of the page", "go to top of the page", "scroll to top"]
  scrollToBottom: ["bottom", "girl bottom", "scroll bottom", "scroll to bottom", "scroll to the bottom of the page", "bottom of the page", "go to the bottom of the page", "go to bottom of the page", "scroll to bottom"]
  scrollToLeft: ["scroll all the way to the left", "scroll extreme left", "scroll left extreme"]
  scrollToRight: ["scroll all the way to the right", "scroll extreme right", "scroll right extreme"]

  scrollPageDown: ["scroll a half page down", "scroll half page down", "half page down", "go half page down", "scroll page down", "down"]
  scrollPageUp: ["scroll a half page up", "scroll half page up", "half page up", "scroll page up", "scroll page app", "scroll half page app", "up", "app"]
  scrollFullPageDown: ["scroll a full page down", "scroll full page down", "full page down", "go full page down", "page down"]
  scrollFullPageUp: ["goa", "full page app", "scroll a full page up", "scroll full page up", "full page up", "go full page up", "page app", "page up"]

  reload: ["reload the page", "reload", "reload page", "refresh", "refresh page"]
  toggleViewSource: ["view page source", "page source", "see page source", "toggle view source"]

  copyCurrentUrl: ["copy the current url to the clipboard", "copy url", "copy the url", "copy current url"]
  openCopiedUrlInCurrentTab: ["open the clipboard's url in the current tab", "open copied url in current tab", "open the copied url in current tab", "open copied url in the current tab", "open the copied url in the current tab" ]
  openCopiedUrlInNewTab: ["open the clipboard's url in a new tab", "open copied url in new tab", "open the copied url in new tab", "open copied url in a new tab", "open the copied url in a new tab"]

  enterInsertMode: ["enter insert mode", "insert mode"]
  passNextKey: ["pass the next key to chrome", "pass next key"]
  enterVisualMode: ["enter visual mode", "visual mode"]
  enterVisualLineMode: ["enter visual line mode", "visual line mode"]

  focusInput: ["focus the first text input on the page", "focus text input on the page", "focus input"]

  "LinkHints.activateMode": ["black", "select", "link", "lynch", "lyndt", "wink", "open a link in the current tab", "open link in current tab", "open link in the current tab"]
  "LinkHints.activateModeToOpenInNewTab": ["black background", "select back", "link back", "lynch back", "lyndt back ", "wink back", "open a link in a new tab", "open link in new tab", "open the link in the new tab"]
  "LinkHints.activateModeToOpenInNewForegroundTab": ["link new", "link follow", "select new", "select follow", "black new", "select new", "link new", "lynch new", "lyndtnew ", "wink new", "open a link in a new tab & switch to it"]
  "LinkHints.activateModeWithQueue": ["open multiple links in a new tab"]
  "LinkHints.activateModeToOpenIncognito": ["open a link in incognito window", "open a link in incognito", "open link in incognito"]
  "LinkHints.activateModeToDownloadLink": ["download link url", "download link" ]
  "LinkHints.activateModeToCopyLinkUrl": ["copy a link url to the clipboard", "copy link"]

  enterFindMode: ["enter find mode", "find mode", "find"]
  performFind: ["cycle forward to the next find match", "next find match", "next find", "perform find"]
  performBackwardsFind: ["cycle backward to the previous find match", "previous find match", "previous find", "perform backward find"]

  goPrevious: ["follow the link labeled previous or <", "go previous"]
  goNext: ["follow the link labeled next or >", "go next"]

  # Navigating your history
  goBack: ["go back in history", "go back", "back"]
  goForward: ["go forward in history", "go forward", "forward"]

  # Navigating the URL hierarchy
  goUp: ["go up", "go up the URL hierarchy"]
  goToRoot: ["go to root", "go root", "go to root of current url hierarchy"]

  # Manipulating tabs
  nextTab: ["go one tab right", "right tab", "next tab", "next", "max", "text", "right"] # note it often hears next as max
  previousTab: ["go one tab left", "left tab", "previous tab", "previous", "cvs", "prettiest", "left", "laughed", "laugh", "loft"]
  visitPreviousTab: ["go to previously visited tab", "previously visited tab", "recent tab", "recent"]
  firstTab: ["go to the first tab", "go to first tab", "first tab", "first"]
  lastTab: ["go to the last tab", "go to last tab", "last tab", "last"]

  createTab: ["create new tab", "new tab", "create tab", "create", "new"]
  duplicateTab: ["duplicate current tab", "duplicate tab", "duplicate"]
  removeTab: ["close current tab", "close tab", "remove tab", "remove", "close", "clovis"]
  restoreTab: ["restore closed tab", "restore tab", "restore", "reopen", "ryokan"]

  moveTabToNewWindow: ["move tab to new window"]
  togglePinTab: ["pin or unpin current tab", "toggle current tab", "toggle pin tab"]
  toggleMuteTab: ["mute or unmute current tab", "toggle mute current tab", "toggle mute tab"]

  closeTabsOnLeft: ["close tabs on the left", "close left tabs", "close tabs on left", "close left"]
  closeTabsOnRight: ["close tabs on the right", "close right tabs", "close tabs on right", "close right"]
  closeOtherTabs: ["close all other tabs", "close other tabs", "close other"]

  moveTabLeft: ["move tab to the left", "move tab left", "move left"]
  moveTabRight: ["move tab to the right", "move tab right", "move right"]

  "Vomnibar.activate": ["open url, bookmark or history entry", "omni"]
  "Vomnibar.activateInNewTab": ["Open url, bookmark or history entry in a new tab"]
  "Vomnibar.activateTabSelection": ["search through your open tabs", "search through the open tabs"]
  "Vomnibar.activateBookmarks": ["open a bookmark", "open bookmark"]
  "Vomnibar.activateBookmarksInNewTab": ["open a bookmark in a new tab"]
  "Vomnibar.activateEditUrl": ["edit the current url", "edit url"]
  "Vomnibar.activateEditUrlInNewTab": ["edit the current url and open in a new tab", "edit url and open in new tab"]

  nextFrame: ["select the next frame on the page", "select next frame", "next frame"]
  mainFrame: ["select the page's main/top frame", "select main frame", "select top frame", "main frame", "top frame"]

# dictionary of voice commands to vimium commands
voiceToCommandMap = {}
for command, triggers of commandVoiceTriggers
  for trigger in triggers
    if trigger of voiceToCommandMap
      # log the message
      BgUtils.log "trigger \"#{trigger}\" is already mapped to command \"#{commandVoiceTriggers[trigger]}.\" Cannot remap it to command \"#{command}\""
      console.log "trigger \"#{trigger}\" is already mapped to command \"#{commandVoiceTriggers[trigger]}.\" Cannot remap it to command \"#{command}\""
    else
      voiceToCommandMap[trigger] = command


commandDescriptions =
  tryLink: ["Activates link hints and tries one"]
  search: ["Opens the search page", { background: true }]
  noop: ["Does nothing"]
  runEscape: ["Simulates Escape key press"]
  type: ["Types what the user says to"]
  activateLinkHint: ["Activates the given link hint"]

  # Navigating the current page
  showHelp: ["Show help", { topFrame: true, noRepeat: true }]
  scrollDown: ["Scroll down"]
  scrollUp: ["Scroll up"]
  scrollLeft: ["Scroll left"]
  scrollRight: ["Scroll right"]

  scrollToTop: ["Scroll to the top of the page"]
  scrollToBottom: ["Scroll to the bottom of the page", { noRepeat: true }]
  scrollToLeft: ["Scroll all the way to the left", { noRepeat: true }]
  scrollToRight: ["Scroll all the way to the right", { noRepeat: true }]

  scrollPageDown: ["Scroll a half page down"]
  scrollPageUp: ["Scroll a half page up"]
  scrollFullPageDown: ["Scroll a full page down"]
  scrollFullPageUp: ["Scroll a full page up"]

  reload: ["Reload the page", { noRepeat: true }]
  toggleViewSource: ["View page source", { noRepeat: true }]

  copyCurrentUrl: ["Copy the current URL to the clipboard", { noRepeat: true }]
  openCopiedUrlInCurrentTab: ["Open the clipboard's URL in the current tab", { background: true, noRepeat: true }]
  openCopiedUrlInNewTab: ["Open the clipboard's URL in a new tab", { background: true, repeatLimit: 20 }]

  enterInsertMode: ["Enter insert mode", { noRepeat: true }]
  passNextKey: ["Pass the next key to Chrome"]
  enterVisualMode: ["Enter visual mode", { noRepeat: true }]
  enterVisualLineMode: ["Enter visual line mode", { noRepeat: true }]

  focusInput: ["Focus the first text input on the page"]

  "LinkHints.activateMode": ["Open a link in the current tab"]
  "LinkHints.activateModeToOpenInNewTab": ["Open a link in a new tab"]
  "LinkHints.activateModeToOpenInNewForegroundTab": ["Open a link in a new tab & switch to it"]
  "LinkHints.activateModeWithQueue": ["Open multiple links in a new tab", { noRepeat: true }]
  "LinkHints.activateModeToOpenIncognito": ["Open a link in incognito window"]
  "LinkHints.activateModeToDownloadLink": ["Download link url"]
  "LinkHints.activateModeToCopyLinkUrl": ["Copy a link URL to the clipboard"]

  enterFindMode: ["Enter find mode", { noRepeat: true }]
  performFind: ["Cycle forward to the next find match"]
  performBackwardsFind: ["Cycle backward to the previous find match"]

  goPrevious: ["Follow the link labeled previous or <", { noRepeat: true }]
  goNext: ["Follow the link labeled next or >", { noRepeat: true }]

  # Navigating your history
  goBack: ["Go back in history"]
  goForward: ["Go forward in history"]

  # Navigating the URL hierarchy
  goUp: ["Go up the URL hierarchy"]
  goToRoot: ["Go to root of current URL hierarchy"]

  # Manipulating tabs
  nextTab: ["Go one tab right", { background: true }]
  previousTab: ["Go one tab left", { background: true }]
  visitPreviousTab: ["Go to previously-visited tab", { background: true }]
  firstTab: ["Go to the first tab", { background: true }]
  lastTab: ["Go to the last tab", { background: true }]

  createTab: ["Create new tab", { background: true, repeatLimit: 20 }]
  duplicateTab: ["Duplicate current tab", { background: true, repeatLimit: 20 }]
  removeTab: ["Close current tab", { background: true, repeatLimit: chrome.session?.MAX_SESSION_RESULTS ? 25 }]
  restoreTab: ["Restore closed tab", { background: true, repeatLimit: 20 }]

  moveTabToNewWindow: ["Move tab to new window", { background: true }]
  togglePinTab: ["Pin or unpin current tab", { background: true, noRepeat: true }]
  toggleMuteTab: ["Mute or unmute current tab", { background: true, noRepeat: true }]

  closeTabsOnLeft: ["Close tabs on the left", {background: true, noRepeat: true}]
  closeTabsOnRight: ["Close tabs on the right", {background: true, noRepeat: true}]
  closeOtherTabs: ["Close all other tabs", {background: true, noRepeat: true}]

  moveTabLeft: ["Move tab to the left", { background: true }]
  moveTabRight: ["Move tab to the right", { background: true }]

  "Vomnibar.activate": ["Open URL, bookmark or history entry", { topFrame: true }]
  "Vomnibar.activateInNewTab": ["Open URL, bookmark or history entry in a new tab", { topFrame: true }]
  "Vomnibar.activateTabSelection": ["Search through your open tabs", { topFrame: true }]
  "Vomnibar.activateBookmarks": ["Open a bookmark", { topFrame: true }]
  "Vomnibar.activateBookmarksInNewTab": ["Open a bookmark in a new tab", { topFrame: true }]
  "Vomnibar.activateEditUrl": ["Edit the current URL", { topFrame: true }]
  "Vomnibar.activateEditUrlInNewTab": ["Edit the current URL and open in a new tab", { topFrame: true }]

  nextFrame: ["Select the next frame on the page", { background: true }]
  mainFrame: ["Select the page's main/top frame", { topFrame: true, noRepeat: true }]

  "Marks.activateCreateMode": ["Create a new mark", { noRepeat: true }]
  "Marks.activateGotoMode": ["Go to a mark", { noRepeat: true }]


OPEN_IN_CURRENT_TAB =
  name: "curr-tab"
  indicator: "Open link in current tab"
OPEN_IN_NEW_BG_TAB =
  name: "bg-tab"
  indicator: "Open link in new tab"
  clickModifiers: metaKey: isMac, ctrlKey: not isMac
OPEN_IN_NEW_FG_TAB =
  name: "fg-tab"
  indicator: "Open link in new tab and switch to it"
  clickModifiers: shiftKey: true, metaKey: isMac, ctrlKey: not isMac
OPEN_WITH_QUEUE =
  name: "queue"
  indicator: "Open multiple links in new tabs"
  clickModifiers: metaKey: isMac, ctrlKey: not isMac
COPY_LINK_URL =
  name: "link"
  indicator: "Copy link URL to Clipboard"
  linkActivator: (link) ->
    if link.href?
      chrome.runtime.sendMessage handler: "copyToClipboard", data: link.href
      url = link.href
      url = url[0..25] + "...." if 28 < url.length
      HUD.showForDuration "Yanked #{url}", 2000
    else
      HUD.showForDuration "No link to yank.", 2000
OPEN_INCOGNITO =
  name: "incognito"
  indicator: "Open link in incognito window"
  linkActivator: (link) -> chrome.runtime.sendMessage handler: 'openUrlInIncognito', url: link.href
DOWNLOAD_LINK_URL =
  name: "download"
  indicator: "Download link URL"
  clickModifiers: altKey: true, ctrlKey: false, metaKey: false

availableModes = [OPEN_IN_CURRENT_TAB, OPEN_IN_NEW_BG_TAB, OPEN_IN_NEW_FG_TAB, OPEN_WITH_QUEUE, COPY_LINK_URL,
  OPEN_INCOGNITO, DOWNLOAD_LINK_URL]