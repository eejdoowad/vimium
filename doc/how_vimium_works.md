
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
3. The OnKeyPress handler function specificly:
  1. Checks if the pressed key is a mapped to a command, and if so calls the handleKeyChar function
  2. Checks if its a digit key, saves it somewhere, then suppresses propogation (2 r would move 2 tabs right )
  3. Otherwise passes it on to the next handler
4. The handleKeyChar function finds the command for that key, then calls the commandHandler function passing the command and a count (2 r would move 2 tabs right )
5. The commandHandler function checks the command options:
  1. If command.topFrame is true, a message is sent to the top frame with the command details so that i can execute it (think vomnibar and help dialogue)
  2. If command.background is true, a message is sent to the background page so that it can execute it
  3. Otherwise the command is directly executed through Utils.invokeCommandString (which calls the function of the window object matching the command string, recall the window is extended with the actual command functions)
6. In the case of a backgroundCommand, the the background page's generic command handler sees a "runBackgroundCommand" handler, then calls the runBackgroundCommandHandler
  * the runBackgroundCommandHandler looks up and executes the appropriate handler function for the given command




A listen