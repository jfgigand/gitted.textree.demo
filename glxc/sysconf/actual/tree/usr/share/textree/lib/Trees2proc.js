
var stream = require('stream');
var util = require("util");
var events = require("events");
var HamlNode = require("./HamlNode");
var Q = require("kew");
var vm = require("vm");


function Trees2proc(options) {
  if (!options) { options = {}; }
  options.objectMode = true;
  stream.Transform.call(this, options);

  this.level = -1;
  // list of templates
  this.templates = [];
  this.templatesMatches = {};

  // queue of events to process (starting with [0])
  this.eventQueue = [];

  // execution stack (current is [index - 1])
  this.contextStack = [this.executeDefault];

  // input-level (start/stop) state stack (current is [0])
  // initialized with root level
  this.levelState = [{selectors: {}}];

  // NodeJS VM context of JS expr evaluations
  this.vmContext = vm.createContext({});

  // // Stack of variable values that shall get restored.
  // // [0] is supposed to be in the environment
  // this.vmMaskStack = [];

  // [0] is the negative address if the latest continuation break (":on")
  // For example, 42 means the continuation is at eventQueue[eventQueue.index - 42].
  // Unshifted and shifted by ":on", shifted also by ":through"
  this.continuationPositions = [];

}

util.inherits(Trees2proc, stream.Transform);
module.exports = Trees2proc;


////////////////////////////////////////////////////////////////////////////////
// COMMAND FUNCTIONS

Trees2proc.prototype.executeDefault = function (event) {
  var selectors = [];

  // console.log("executeDefault", event);
  switch (event.type) {

   case "start":
    this.unshiftLevel(event);
    if (event.name[0] == ":") {
      var fname = "command_"+event.name.slice(1);
      if (event.name == "::") {
        fname = "command_on";
      }
      if (this[fname]) {
        return this[fname].call(this, event);
      } else {
        console.error("command not found:", event.name);
      }
    } else if ( /=$/.test(event.name)) {
      return this.op_affect(event);
    }

    // if (selectors[event.name] && selectors[event.name].length > 0) {
    //   return selectors[event.name][0].call(this, event);
    // }
    selectors.push(event.name, "*");
    this.lastStart = event;
    break;

   case "end":
    if (this.shiftLevel(event) === false) {
      return null;
    }
    selectors.push("END");
    break;

   case "text":
    // if (event.text[0] === "=") {
    //   return this.op_set(event);
    // }
    selectors.push("TEXT");
    break;

   case "attr":
    selectors.push("ATTR");
    break;
  }

  // check selectors
  var handler, registered = this.levelState[0].selectors;
  for (var idx = 0; idx < selectors.length; idx++) {
    if ((handler = registered[selectors[idx]])) {
      return handler.call(this, event);
    }
  }

  this.push(event);
  return null;
};

/**
 * DISABLED as it is difficult to handle
 * (the START event has been processed already)
 *
 * @param {object} textEvent
 */
// Trees2proc.prototype.op_set = function (textEvent) {
//   this.evalExpression(this.lastStart.name+textEvent.text);
//   this.captureSubLevelEvents(true).done();
// };

/**
 * element= expression // expression is inserted as first child/children
 * Can be fed with a javascript or
 */
Trees2proc.prototype.op_affect = function (event) {
  this.captureTextAndEval().then(function(value) {
    if (value instanceof Error) {
      value = "[JS expression error: "+value+"]";
    }
    var pure = event.name == "=";
    if (!pure) {
      this.push({ type: event.type, name: event.name.replace(/=$/, "") });
    }
    this.push({ type: "text", text: ""+value });
    if (pure) {
      return this.captureSubLevelEvents(true);
    }
    return null;
  }.bind(this)).done();
};

/**
 * Example:
 *   :eval variable = expression
 */
Trees2proc.prototype.command_eval = function (event) {
  this.captureFirstText()
    .then(this.evalExpression.bind(this))
    .then(this.captureSubLevelEvents.bind(this, true))
    .done();
};

Trees2proc.prototype.command_if = function (event) {
  // this.levelState
  this.captureTextAndEval().then(function(value) {
    // console.log("if:value:", value, !!value);
    if (value instanceof Error) {
      this.push(event);
      this.push({ type: "text", text: "[JS expression error: "+value+"]" });
      return null;
    }
    if (!!value) {
      this.levelState[0].onEnd = function(event) { return false; };
      return null;
    } else {
      return this.captureSubLevelEvents(true);
    }
  }.bind(this)).done();
};

Trees2proc.prototype.command_each = function (event) {

  var bindName;
  var bindKey;
  var arrayExpr;
  // var arrayLength;

  // TODO: eval expression once only

  var array;

  this.captureFirstText()

    .then(function(text) {

      var parts = text.split(" in ");
      if (parts.length < 2) {
        console.log(":each bad syntax argument:", text);
        this.push(event);
        this.push({ type: "text", text: text });
        return null;
      }

      var bindParts = parts[0].trim().split(",", 2);
      bindName = bindParts[0].trim();
      if (bindParts[1]) {
        bindKey = bindParts[1].trim();
      }

      arrayExpr = parts[1].trim();
      array = this.evalExpression(arrayExpr);

      if (!(array instanceof Array)) {
        console.error(":each: not an array");
      }

      return this.captureSubLevelEvents();

    }.bind(this))

    .then(function(buffer) {
      if (buffer) {
        // console.log("BUFFER", buffer);
        var idx = 0;

        var _iterate = function () {
          var obj = {};
          obj[bindName] = array[idx];

          if (bindKey) {
            obj[bindKey] = idx;
          }
          var releaseContext = _maskProperties(obj, this.vmContext);

          return this.playBuffer(buffer).then(function() {
            // after "play" completes...

            releaseContext();
            idx++;
            if (idx < array.length) {
              return _iterate();
            } else {
              // the task is finished
              return null;
            }
          });
        }.bind(this);

        if (array.length > 0) {
          return _iterate();
        }
      }
      return Q.resolve(null);

    }.bind(this)).done();
};

/**
 * Alternative syntax: "::" instead of ":on"
 */
Trees2proc.prototype.command_on = function (event) {
  var bindName = "_";
  var selector;
  var prevUnderscore;

  this.captureFirstText()

    .then(function(text) {

      var parts = text.split("=");
      if (parts[1]) {
        bindName = parts.shift();
      }
      selector = parts[0].trim();
      // bindName = (parts[1] || "_").trim();

      console.log("selector", selector, "bind", bindName);
      return this.captureSubLevelEvents();
    }.bind(this))

    .then(function(buffer /* of events to apply when selector is met */) {

      // declare the function to be called when selector is matched
      this.addMatch(selector, function(event) {

        this.continuationPositions.unshift(this.eventQueue.length);

        var underscore = event;
        if (event.type == "text") {
          underscore = event.text;
        }
        var vars = { _: underscore };
        vars[bindName] = underscore;
        this.vmContext[bindName] = underscore;
        console.log("mask", vars);
        var release = _maskProperties(vars, this.vmContext);
        this.playBuffer(buffer)
          .then(function() {
            console.log("ON: DONE playing", bindName, "=", selector);
            release();

            var uncontinued = this.continuationPositions[0] != null;
            this.continuationPositions.shift();
            if (uncontinued && event.type == "start") {
              // this.debugInfo("throwing away what didn't get through");
              return this.captureSubLevelEvents(true);
            } else {
              // this.debugInfo("did go through");
            }
            return null;
          }.bind(this)).done();

      });
    }.bind(this)).done();

};
Trees2proc.prototype.command_debug = function (event) {
  this.debugInfo(":DEBUG");
  this.captureSubLevelEvents().done();
};

Trees2proc.prototype.command_through = function (event) {
  this.captureSubLevelEvents(true)
    .then(function() {
      if (!this.continuationPositions.length) {
        console.log("WARN: command :through called outside of ':on' context");
      } else if (this.continuationPositions[0] === null) {
        console.log("WARN: command :through called twice for the same ':on' context");
      } else {
        var idx = this.eventQueue.length - this.continuationPositions[0];
        var buffer = this.eventQueue.splice(0, idx);
        this.continuationPositions[0] = null;
        this.levelState[0].onEnd = function() {
          // this.debugInfo("this.eventQueue END1");
          this.eventQueue.unshift.apply(this.eventQueue, buffer);
        }.bind(this);
      }
    }.bind(this))
    .done();
};


////////////////////////////////////////////////////////////////////////////////
// CAPTURE functions - return a promise about what has been captured
//   (used by COMMAND functions)

/**
 * Capture first-child-text
 *
 * @return {promise} will be resolved with the concatenated text
 */
Trees2proc.prototype.captureFirstText = function () {
  var def = Q.defer();
  var text = "";

  this.contextStack.push(function(event) {
    switch (event.type) {
     case "text":
      text += event.text;
      return;
     case "start": // a child
     case "end": // with or without text
      this.contextStack.pop(); // means a return
      this.eventQueue.unshift(event); // will be processed normally
      def.resolve(text);
      // this.process(event);
      break;
    default:
    }

  });

  return def.promise;
};

/**
 * Capture first-child-text and evaluate it as a JS expression
 *
 * @return {promise} will be resolved with the value of the evaluation
 */
Trees2proc.prototype.captureTextAndEval = function () {
  return this.captureFirstText().then(this.evalExpression.bind(this));
};

/**
 * Capture all next events until end of level (next stop event for current level)
 *
 * @return {promise} will be resolved with an array of the events
 */
Trees2proc.prototype.captureSubLevelEvents = function (dontBuffer) {
  var buffer = [];
  var def = Q.defer();
  var depth = 0;

  this.contextStack.push(function(event) {
    switch (event.type) {
     case "start": depth++; break;
     case "end": depth--; break;
    }
    if (depth >= 0) {
      if (dontBuffer) {
        console.log("throwing event", event);
      } else {
        buffer.push(event);
      }
    } else {
      this.shiftLevel();
      this.contextStack.pop();
      def.resolve(buffer);
      return;
    }
  }.bind(this));

  return def.promise;
};


////////////////////////////////////////////////////////////////////////////////
// INTERNAL FUNCTIONALITY

Trees2proc.prototype._transform = function (event, encoding, done) {

  this.eventQueue.push(event);
  while (this.eventQueue[0]) {
    this.processEvent(this.eventQueue.shift());
  }

  done();
};

Trees2proc.prototype._flush = function (done) {
  if (done) {
    done();
  }
};

Trees2proc.prototype.processEvent = function (event) {
  switch (event.type) {

   case "_callback":
    // this.debugInfo("CALLBACK");
    event.callback.call(this);
    return;

   case "start":
    break;

   case  "end":
    break;
  }
  var func = this.contextStack[this.contextStack.length - 1];
  func.call(this, event);
};

Trees2proc.prototype.unshiftLevel = function (event) {
  function _F() {}
  _F.prototype = this.levelState[0].selectors;
  this.levelState.unshift({ tag: event.name, selectors: new _F() });
};

Trees2proc.prototype.shiftLevel = function () {
  var level = this.levelState.shift();
  if (!this.levelState[0]) {
    throw new Error("unmatched END event!");
  }
  if (level && level.onEnd) {
    if (!level.onEnd.call(this)) {
      return false; // hook can return false to get the event ignored
    }
  }
  return true;
};

Trees2proc.prototype.evalExpression = function (expr) {
  try {
    var value = vm.runInContext(expr, this.vmContext);
  }
  catch (e) {
    console.error(":eval expression failed: <<", expr, ">> error is:", e);
    value = e;
  }
  return value;
};

Trees2proc.prototype.playBuffer = function (buffer) {
  var def = Q.defer();

  this.eventQueue = buffer.concat(
    [{type:"_callback", callback: def.resolve.bind(def)}],
    this.eventQueue);

  return def.promise;
};

/**
 * Attach a handler for a selector, will be applied on matched 'start' events
 *
 * The handler will be called with the 'this' scope.
 */
Trees2proc.prototype.addMatch = function (selector, handler, parentLevel) {
  var selectors = this.levelState[parentLevel || 0].selectors;
  selectors[selector] = handler;
};

Trees2proc.prototype.debugInfo = function () {
  console.log("DEBUG ", arguments[0]);
  console.log("*** queue #", this.eventQueue.length, this.eventQueue);
  console.log("*** levelState #", this.levelState.length,
              this.levelState.map(function(level) {return level.tag;}).join(" < "));
  console.log("*** contextStack #", this.contextStack.length);
};
Trees2proc.prototype.debugQueue = function () {
  console.log("DEBUG ", arguments, "queue#", this.eventQueue.length,
              this.eventQueue);
};


////////////////////////////////////////////////////////////////////////////////
// UTIL FUNCTIONS

/**
 * Copy properties of newObj into maskedObj but keep a backup to restore later
 *
 * @return {Function} Release function: the caller should call il to restore the backed-up value
 */
function _maskProperties(newObj, maskedObj) {
  var values = {};
  var present = {};

  // console.log("MASK", newObj);
  for (var key in newObj) {
    if ((present[key] = maskedObj.hasOwnProperty(key))) {
      values[key] = maskedObj[key];
    }
    maskedObj[key] = newObj[key];
  }

  return function() {
    // console.log("FREE", newObj, present);
    for (var key in present) {
      if (present[key]) {
        maskedObj[key] = values[key];
      } else {
        delete maskedObj[key];
      }
    }
  };
}
