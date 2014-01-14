var path = require('path');
var util = require('util');
var nconf = require('nconf');
var logger = require('./logger');
var yaml = require('js-yaml');
var _ = require('underscore');
var co = require('co');
var fs = require('co-fs');
var exec = require('./co_exec');
var debug = require('debug')('mssql:run');

nconf
    .argv()
    .env();

var config = nconf.get('config') || nconf.get('CONFIG');
var specFile = nconf.get('spec') || nconf.get('SPEC');

if (!config) {
    logger.error('No configuration file found, specify via --config or set CONFIG');
    process.exit(1);
}

if (!specFile) {
    logger.error('No spec yaml file found, specify via --spec or set SPEC');
    process.exit(1);
}

nconf.file(config);

var specDir = nconf.get('spec_dir');
var testRuns = [];

co(function * () {
    var specFileContent = yield fs.readFile(specFile, 'utf-8');
    var specYmlDoc = yaml.safeLoad(specFileContent);
    var isConcurrent = specYmlDoc.job.concurrent;
    var specs = specYmlDoc.job.specs;
    var len = specs.length;

    while (len--) {
        var spec = specs[len]

        if (!Array.isArray(spec)) {
            spec = [spec];
        }

        spec.forEach(function (item) {
            testRuns.push({
                name: item,
                path: path.resolve(specDir, item),
                isCompleted: false
            });
        });
    }

    debug('running in %s mode', isConcurrent ? 'concurrent' : 'sequence');

    if (!isConcurrent) {
        return yield run(testRuns[0]);
    } else {
        var concurrentTests = [];
        var len = testRuns.length;
        while (len--) {
            debug('running: %s', testRuns[len].name);
            concurrentTests.push(exec(getRunCmd(testRuns[len].path), {
                cwd: path.resolve(__dirname, '../deps/autohammer')
            }));
        }
        return yield concurrentTests;
    }
})();

function * run(s) {
    debug('start running: %s', s.name);
    var stdout = yield exec(getRunCmd(s.path), {
        cwd: path.resolve(__dirname, '../deps/autohammer')
    });
    debug('finish running: %s', s.name);
    debug('stdout: %s', stdout);

    s.isCompleted = true;
    var nextRun = _.find(testRuns, function (o) {
        return !o.isCompleted;
    });
    if (nextRun) {
        yield run(nextRun);
    }
}

function getRunCmd(specPath) {
    var cmd = util.format('\"%s\" \"%s\" \"%s\"', nconf.get('tclsh86t'), path.resolve(__dirname, '../deps/autohammer/autohammer.tcl'), specPath);

    debug('cmd: %s', cmd);

    return cmd;
}