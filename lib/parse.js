var fs = require('fs');
var path = require('path');
var util = require('util');
var xml2js = require('xml2js');
var glob = require('glob');
var co = require('co');
var thunk = require('thunkify');
var nconf = require('nconf');

nconf.file('../spec_result.json');

glob = thunk(glob);
var parser = new xml2js.Parser({
    explicitArray: false
});
var readFile = thunk(fs.readFile);
var parseString = thunk(parser.parseString);

co(function * () {
    var files = yield glob(path.resolve(__dirname, '../deps/autohammer/**/TPCC*.xml'));
    var len = files.length;

    while (len--) {
        var content = yield readFile(files[len]);
        var json = yield parseString(content);

        var configruation = json.autohammer.get_configuration;
        var result = json.autohammer.run_tpcc.tpcc_results;

        //console.log(util.inspect(result, false, null));

        var test = configruation.test;
        var warehouses = configruation.warehouses;
        var runThreads = configruation.run_threads;
        var dbName = configruation.database_name;

        //todo: need to delte the test result dir
        nconf.set(test + '_' + warehouses + '_' + runThreads, {
            tpm: parseFloat(result.server_tpm),
            tpmC: parseFloat(result.NOTPM),
            vUsers: parseInt(runThreads),
            dbName: dbName
        });

        nconf.save();
    }
})();