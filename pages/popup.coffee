createTab = ->
	chrome.tabs.create
		url: chrome.extension.getURL "pages/listen.html"
		active: false
		index: 999999
	, (newTab) ->
		BgUtils.log "Listener launched on #{newTab.id}"

document.addEventListener "DOMContentLoaded", ->
  (document.getElementById "launchVoiceButton") .addEventListener "click", (event) ->
    createTab()

# function createTab() {
# 	chrome.tabs.create({
# 		url: chrome.extension.getURL("listen.html"),
# 		active: false,
# 		index: 999999 // Big number to force the tab to the end of the row
# 	}, function(newTab) {
# 		speechRecTabId = newTab.id;
# 		// chrome.tabs.sendMessage(newTab.id, {type: "start"});
# 	});
# }