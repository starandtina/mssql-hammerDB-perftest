var co = require('co');
var fs = require('co-fs');
var path = require('path');
var nconf = require('nconf');
var util = require('util');
var debug = require('debug')('mssql:gen_specs');

nconf
    .argv()
    .env();

co(function * () {

    var w = nconf.get('warehouse');
    var u = nconf.get('users');
    var range = nconf.get('range').split(',');

    var s = parseInt(range[0]);
    var e = parseInt(range[1]);

    for (; s <= e; s++) {
        var dirPath = path.resolve(__dirname, '..//specs//', util.format('TPCC_%s_%s_%s_RUN', w, s, u));
        debug(dirPath);

        yield fs.mkdir(dirPath);

        var content = yield fs.readFile(path.resolve(__dirname, '..//config//run_config.xml'));
        content = content.toString().replace(/<(database_name|run_threads|warehouses)[^>]*>([\s\S]*?)<\/\1>/g, function(match, sub1, sub2) {
            var v;
            switch (sub1) {
                case 'database_name':
                    v = util.format('tpcc%s_%s', w, s);
                    break;
                case 'run_threads':
                    v = u;
                    break;
                case 'warehouses':
                    v = w;
                    break;
                default:
                    break;
            }

            return util.format('<%s>%s</%s>', sub1, v, sub1);
        });

        yield fs.writeFile(dirPath + '//run_config.xml', content);
    }
})();