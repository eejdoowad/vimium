
Vimium is a chrome extension, which is split into background scripts (that run in the background) and content scripts that are loaded into every web page. In addition, there are scripts in the 'lib' folder that either expose external library features or aren't strictly classified as background or content scripts.



Each time a page is loaded,  vimium_frontend.coffee executes

It does the following:
* Extend window with scroll command functions
* Extend window with navigation, focus, and mode change commands
* Declare lots of find mode functions
* initializePreDomReady
  * Installs listeners
    * for type in ["keydown", "keypress", "keyup", "click", "focus", "blur", "mousedown", "scroll"]
    * action is to bubble all events to handler stack
  * Initiaize the Frame ( a page is a frame and contain subframes)
  * Check if vimium is enabled on that URL
  * Add a listener that that executes one of the following when a chrome extension message is received:
    * FocusFrame, getScrollPosition, setScrollPosition, checkEnabledAfterURLFrame, runInTopFrame, linkHintsMessage
      - special note: because this is added to every page, every page gets the message, but the extension is built such that 
    * These commands will be executed




When you press a button in NormalMode:
1. The installed listener bubbles it to the handlerStack for processing
2. The handlerStack calls the topmost handler, which executes the handler function for the specific event type (keydown, keypress, keyup)
  * The return value of the handler function determines whether the event is propogated to the next handler
3. The OnKeyPress handler function specifically:
  1. Checks to see if the key is
    1. Mapped to command: calls the handleKeyChar function
    2. Mapped to a digit: resets key handling but stores sequence of digits entered thus far
    3. neither: resets keyhandling and returns @continueBubbling
  2. Checks if its a digit key, saves it somewhere, then suppresses propogation (2 r would move 2 tabs right )
  3. Otherwise passes it on to the next handler
4. The handleKeyChar function
  * Advances the keystate based on the input key
  * Checks if the current keystate corresponds to a complete command sequence:
    * True: calls the commandHandler function passing the command and the count (2 r would move 2 tabs right, no count defaults to 1), also resets command sequence
    * False: suppresses event propogation (but keystate remains advanced)
5. The commandHandler function checks the command options:
  1. If command.topFrame is true, a message is sent to the top frame (indirectly via the background script) with the command details so that it can execute it (think vomnibar and help dialogue)
  2. If command.background is true, a message is sent to the background page so that it can execute it
  3. Otherwise the command is directly executed through Utils.invokeCommandString (which calls the function of the window object matching the command string, recall the window is extended with the actual command functions)
6. In the case of a backgroundCommand, the the background page's generic command handler sees a "runBackgroundCommand" handler, then calls the runBackgroundCommandHandler
  * the runBackgroundCommandHandler looks up and executes the appropriate handler function for the given command


OLD COMMAND PATHS
* command.topFrame: page -> background page -> top frame -> execute (with simple check if top frame)
* command.background: page -> background page -> execute
* else: page -> execute
NEW COMMAND PATHS
* listen page -> background page -> top frame -> execute
* listen page -> background page -> execute
* 

Messaging
* chrome.runtime.sendMessage does NOT connect to listeners in content_scirpts
* chrome.tabs.sendMessage sender.tab.id, request.message 


class KeyHandlerMode extends Mode has a keyState, which is a list of keyMappings (which is a nested mapping of corresponding to key sequences that end in a command)

The default keyMapping must be specified on creation of a keyHandlerMode object

On initialization and reset, the keystate has a single entry containing only the default nested command mapping. When a user presses a key, a the mapping for the pressed key is pushed onto the keystate (by looking it up in the previous level mapping) entry is pushed to the front corresponding to the 

Why is keyState a list of keymappings as opposed to a single key mapping, very confused


A listen

Commands.coffee maintains
* availableCommands: a dictionary of commands to options and descritptions, populated on init with default commandDescriptions, but structure changes slightly, seems pointless
* keyToCommandRegister: a dictionary of keys to commands and their options, first defaults mappings, then custom mappings, finally uses this to generate nested keymapping and stores it in local storage for access by content_scripts 


Implementation Detail:
Vimium adds an onMessage Listener to the background page (main.coffee) that uses the sender callback argument to get attributes for further command processing. The result is that certain command (e.g. nextTab, will switch to the tab next to the listener page). This has to be changed so that the tab info is pulled from the active tab, not the sending tab


I think a UI-component frame is a frame made by vimium (e.g. vomnibar or help dialogue or HUD)


main.coffee background script seems to handle a lot of book keeping
* updating existing tab content scripts when vimium updates
* keeping track of the frameIds for a given tab, the ports for each tab (I think each frame gets its own port), and the urls for each tab
* maintains tabLoadedHandlers (which execute functions on certain tabIds when they're loaded, e.g. scroll to mark)
* maintains vimium secret, which is a random number
* handle vomnibar completions
* handle background command executions with sendRequestHandlers[request.handler](request, sender)
* generate Help Page dynamically
* cache CSS in local storage for UI components
* declare open (new) tab operations
* declare mute tabs
* select and move tabs
* Background commands
* inseret link hints css into updated tabs (on URL change)
* handle vimium icons (grayed out for disabled)
* handle Frames
* 


Note a mark is like a bookmark, but it lets you mark a page and location so you can return easily


Mode is the root parent for the various Modes
* the constructor pushes the keydown, keypress, and keyup handles passed from child class
* e.g. KeyHandlerMode passes its definition of those handlers, NormalMode extends KeyHandlerMode but only defines the commandHandler function

*** Not all Modes inherit from Mode because they don't respond to key handlers

Mode Hierarchy

Mode
  KeyHandlerMode
    NormalMode
  GrabBackFocus - pushes modes:
      - "grab-back-focus-mousedown"
      - "grab-back-focus-focus"
  FocusSelector
  Typing Protector
      - suppresses keyboard events until user stops typing for a while (then removes itself from handler stack)
  WaitForEnter
    - suppresses keyboard events until enter pressed
  SuppressPrintable
    - suppresses printable characters from being passed to page
  FindMode
  InsertMode - 
  PassNextKeyMode - passes key events to page
  SuppressAllKeyboardEvents
  FocusSelector
    


Anonymous modes:

_name: "GrabBackFocus-pushState-monitor"
* 
_name: 'scroller/track-key-status'
* events: keydown, keyup, blur
* tracks keystate
* always continues bubbling
_name: 'scroller/active-element'
* events: DOMActivate
* sets the activatedElement for scrolling
* always continues bubbling
_name: "grab-back-focus-mousedown"
* events: mousedown
* additional handler pushed by GrabBackFocus mode
_name: "grab-back-focus-focus"
events: focus
* additional handler pushed by GrabBackFocus mode
_name: "GrabBackFocus-pushState-monitor"
* events: click
* grabs back focus after a link is pressed (javascript navigation as opposed to href)
_name: "dom_utils/suppressKeyupAfterEscape"





Handler Stack Return Values:

# A handler should return this value to immediately discontinue bubbling and pass the event on to the
# underlying page.
@passEventToPage = new Object()

# A handler should return this value to indicate that the event has been consumed, and no further
# processing should take place.  The event does not propagate to the underlying page.
@suppressPropagation = new Object()

# A handler should return this value to indicate that bubbling should be restarted.  Typically, this is
# used when, while bubbling an event, a new mode is pushed onto the stack.
@restartBubbling = new Object()

# A handler should return this value to continue bubbling the event.
@continueBubbling = true

# A handler should return this value to suppress an event.
@suppressEvent = false


Scroller.coffee keeps activatedElement, which is different from document.activeElement, because the latter only tracks inputs, while the former tracks the active div for scrolling