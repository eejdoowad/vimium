messages = document.createElement "div"
messages.setAttribute "id", "voice_messages"

window.addEventListener "DOMContentLoaded", ->
  document.body.appendChild messages

vwn_prompt = (msg, phrases) ->
  console.log msg
  phrases = (phrase for phrase in phrases when phrase isnt msg).join ", "
  message = document.createElement "div"
  message.setAttribute "class", "voice_message"
  alts = if phrases then  " or: #{phrases}" else ""
  message.innerHTML = "#{msg}#{alts}"
  messages.appendChild message

  setTimeout (-> message.remove()), 8000

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  if request.msg? 
    vwn_prompt request.msg, request.phrases
  if request?.voiceCommand
    if request.registryEntry.command == "type"
      type_letters(request.letters)
    else if request.registryEntry.command == "activateLinkHint"
      activateLinkHint(request.matchString)
    else if request.registryEntry.command == "tryLink"
      tryLink(request.matchString)
    else
      Utils.invokeCommandString request.registryEntry.command, request.count

type_letters = (str) ->
  document.activeElement?.value += str
  # THIS DOES NOT WORK. MANUAL EVENTS DO NOT GENERATE DEFAULT ACTIONS
  # for c in str
  #   keyDownEvent = new KeyboardEvent "keypress", {key: c, char: c}
  #   document.activeElement.dispatchEvent keyDownEvent

window.runEscape = ->
  # NOTE: I had to modify KeyboardUtils.isEscape to check for key because synthetic key events can't write the keyCode property (writing 27 below fails)
  escapeKeyDownEvent = new KeyboardEvent "keydown", {key: "Escape", char: "Escape", keyCode: 27}
  document.body.dispatchEvent escapeKeyDownEvent

# does nothing
window.noop = ->

window.tryLink = (matchString) ->
  matchString = matchString.trim().toLowerCase()
  hintMarkers = HintCoordinator.linkHintsMode.hintMarkers
  for marker in hintMarkers
    if marker.linkText? && marker.linkText.toLowerCase().indexOf(matchString) != -1
      HintCoordinator.linkHintsMode.activateLink marker, false
      return

window.activateLinkHint = (matchString) ->
  hintMarkers = HintCoordinator.linkHintsMode.hintMarkers

  linksMatched = hintMarkers.filter (linkMarker) -> linkMarker.hintString == matchString
  if linksMatched.length != 1
    console.log("invalid match string \''" + matchString + "\' for the following hintMarkers")
    console.log(hintMarkers)
  else
    HintCoordinator.linkHintsMode.activateLink linksMatched[0], false