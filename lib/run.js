var fs = require('fs');
var path = require('path');
var nconf = require('nconf');
var logger = require('./logger');
var yaml = require('js-yaml');
var _ = require('underscore');
var debug = require('debug')('mssql:run');
var spawn = require('child_process').spawn;
var util = require('util');

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

var specFileContent = fs.readFileSync(specFile, 'utf-8');
var specYmlDoc = yaml.safeLoad(specFileContent);
var concurrent = specYmlDoc.job.concurrent;
var specs = specYmlDoc.job.specs;

specs.forEach(function (spec) {
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
});

debug('running in %s mode', concurrent ? 'concurrent' : 'sequence');

if (!concurrent) {
    run(testRuns[0], concurrent);
} else {
    testRuns.forEach(function (s) {
        run(s, concurrent);
    });
}

function run(s, concurrent) {
    debug('[%s]: started', s.name);

    var p = spawn('tclsh86t', ['autohammer.tcl', s.path], {
        cwd: path.resolve(__dirname, '../deps/autohammer'),
        detached: true
    });

    p.stdout.on('data', function (data) {
        logger.info('[' + s.name + ']:' + data);
    });

    p.stderr.on('data', function (data) {
        logger.error('[' + s.name + ']:' + data);
    });

    p.on('exit', function(){
        console.log('exit: ' + util.inspect(arguments, false, null))
    })

    p.on('close', function (code) {
        console.log('close: ' + util.inspect(arguments, false, null))
        if (code !== 0) {
            logger.error('[' + s.name + ']:' + 'child process exited with code ' + code);
        } else {
            debug('[%s]: finished', s.name);
            s.isCompleted = true;

            if (!concurrent) {
                var nextRun = _.find(testRuns, function (o) {
                    return !o.isCompleted;
                });
                if (nextRun) {
                    run(nextRun);
                }
            }
        }
    });
}
