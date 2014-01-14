/**
 * Module dependencies.
 */

var exec = require('child_process').exec;

/**
 * Execute `cmd`.
 */

module.exports = function (cmd, opts) {
    return function (done) {
        exec(cmd, opts, function (err, stdout, stderr) {
            console.log("stderr: " + stderr);
            done(err, stdout);
        });
    }
};