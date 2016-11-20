Per-client state machine to determine how commands are interpreted, but where to keep state? on client or on background?


If on client then:
  would need to check client before executing any command (even switching tabs) which isn't always possible. Would have to check for this corner case, but is it really a big deal?

  Option 1: forward all commands to client and expect it to send info back to background

  Option 2: forward all commands to background then client and possibly back to background


If on background then:
  How do you keep state consistent with pages
  E.g. if user clicks a textbox, must it send the background page an update? Will this get out of hand?


Consider adding camera eye tracking scrolling


Possible States

* Page Loading
* Viewing
* Link Selection
* Text Input
* Omnibar
* Help

Different phrases trigger different actions based on the state of the active page. E.g. saying 1 should switch to tab 1, except if the mode is link selection mode in which case saying 1 should select link 1 or in text input mode should type 1, or in omnibar activate suggestion 1.


Does it make sense to figure out what is a valid command on the listen page? Perhaps just forward the details to the background/content page that will make the decision.

Customizable

Won't use regex for command triggers - instead use a simplified language:
  * Surround with ()? to make optional
  * | for OR, operates either globally or within scope of ()
  * # matches both string representation of numbers and number representations and possibly words like 'to', 'too', 'for'
  * after () and ? if it's there, specify captur variable name if desired with {}


* Provide a DEFAULT_MODE_ACTION boolean option that
    TRUE) always does current mode's command first, then if no match perform global mode
    FALSE) always do global mode action first, then if no match perform local mode action

* Include a global prefix escape to bypass local behaviour and invoke global behaviour or vice-versa depending on DEFAULT_MODE_ACTION (should be customizable)

* Always save the last N texts of textboxes so users can restore them if they accidentally issue a close

Types of actions:
* built-in
* javascript
  * need to specify whether in background page or content script and what parameters are available

Need to provide documentation on what commands are available and what arguments they require

On save, should do error checking of commands including
  * exactly one trigger for each command
  * possibly every built-in command must be mapped to something

Expose both the raw text and eventually a pretty GUI

* Also consider compound actions, which would require extending {} syntax to specify handler to pass args to and args format to specify the handler arg is passed to

Commands = [
  {
    name: "Scroll Up",
    action: "SCROLL_UP",
    triggers: {
      global: ["(scroll|girl)? (up|app) (#)?{count}"]
      // count will either be null or a number
      // if null, default value 3 will be used
    },
    // args are passed to handler
    // specifying them here is optional
    // Default behaviour when specified is to use value specified here only if it is null in trigger string
    args: {
      count: 3
    }
  },
  {
    name: "Open Facebook",
    action: "OPEN_PAGE",
    triggers: {
      global: ["open (facebook|face book) (new|in new tab)?{new}"]
      // new will either be null or the value of the text, that's okay approximate boolean
    },
    args: {
      url: "facebook.com"
    }
  },
  {
    name: "Activate Link",
    action: "ACTIVATE_LINK",
    triggers: {
      // only works in select mode
      select: ["(activate|select|link)? (#){id}"]
    }
    // Note that args isn't mandatory
  },
  {
    name: "Switch To Tab By Number",
    action: "CHANGE_TAB",
    triggers: {
      [loading, viewing, helping]: ["((switch|change)) (to)?)? (tab)? (#){number}"]
      global: ["((switch|change) (to)?)? tab (#){number}"]
      // subtle difference: user MUST say tab if not in loading, viewing, or helping mode
    }
  }
]


make 


2d array with row for each mode and column for each possible 


// Default Handlers configuration should NOT be included in source code, but rather downloaded from repository

Handlers = {
  GLOBAL: {
    // only checked if no mode-specific handler

  }
  LOADING: {

  }
  VIEWING: {

  }
  ...
  SELECTING: {

  }
}


Question: does a library exist for abstracting away network communication? Nodes can dynamically declare their presence and connections, and also the data they have, (programmer specifies how they obtain the data)

start with point-to-point, async/await