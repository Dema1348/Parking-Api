var debug = function (message) {
      console.log('[DEBUG]:' , message);
};

var error = function (message) {
      console.error('[ERROR]:' ,message);
};

var info = function (message) {
      console.info('[INFO]:' ,message);
};

var warn = function (message) {
      console.warn('[WARN]:' ,message);
};

var dir = function (message) {
      console.dir('[OBJECT]:' ,message);
};


module.exports.debug = debug;
module.exports.error = error;
module.exports.info = info;
module.exports.warn = warn;
module.exports.dir  = dir;