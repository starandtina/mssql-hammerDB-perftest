var fs = require('fs');
var path = require('path');
var nconf = require('nconf');
var spawn = require('child_process').spawn;
var logger = require('./logger');
var yaml = require('js-yaml');
var _ = require('underscore');

nconf
    .argv()
    .env()
    .file(path.resolve(__dirname, '../config/config.json'));

var doc = yaml.safeLoad(fs.readFileSync(path.resolve(__dirname, '../config/test_spec.yml'), 'utf-8'));
var specs = doc.plan.specs;
var specDir = nconf.get('spec_dir');
var testRuns = [];

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

    var firstRun = testRuns[0];
    if (firstRun) {
        run(firstRun)
    }
});

function run(s) {
    var runProcess = spawn('benchmark_driver.cmd', ['autohammer.tcl', s.path]);

    runProcess.stdout.on('data', function (data) {
        logger.info(s.name + ': ' + data);
    });

    runProcess.stderr.on('data', function (data) {
        logger.error(s.name + ': ' + data);
    });

    runProcess.on('close', function (code) {
        s.isCompleted = true;

        var nextRun = _.find(testRuns, function (o) {
            return !o.isCompleted;
        });

        if (nextRun) {
            run(nextRun);
        }
    });
}