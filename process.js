const fs = require('fs');
const os = require('os');
const path = require('path');

const RTLOAD = /^graph loading time = (.+?) \(ms\)/m;
const RTPAGE = /^GPU Elapsed Time : (.+?) \(ms\)/m;
const GRAPHS = [
  'indochina-2004',
  'uk-2002',
  'arabic-2005',
  'uk-2005',
  'webbase-2001',
  'it-2004',
  'sk-2005',
  'com-LiveJournal',
  'com-Orkut',
  'asia_osm',
  'europe_osm',
  'kmer_A2a',
  'kmer_V1r',
];




// *-FILE
// ------

function readFile(pth) {
  var d = fs.readFileSync(pth, 'utf8');
  return d.replace(/\r?\n/g, '\n');
}

function writeFile(pth, d) {
  d = d.replace(/\r?\n/g, os.EOL);
  fs.writeFileSync(pth, d);
}




// *-CSV
// -----

function writeCsv(pth, rows) {
  var cols = Object.keys(rows[0]);
  var a = cols.join()+'\n';
  for (var r of rows)
    a += [...Object.values(r)].map(v => `"${v}"`).join()+'\n';
  writeFile(pth, a);
}




// *-LOG
// -----

function readLogLine(ln, data, state) {
  if (RTLOAD.test(ln)) {
    if (!state) state = {};
    if (!state.graph) state.graph = GRAPHS[0];
    else state.graph = GRAPHS[(GRAPHS.indexOf(state.graph) + 1) % GRAPHS.length];
    var [, load_time] = RTLOAD.exec(ln);
    state.load_time = parseFloat(load_time);
  }
  else if (RTPAGE.test(ln)) {
    var [, pr_gpu_time] = RTPAGE.exec(ln);
    if (!data.has(state.graph)) data.set(state.graph, []);
    data.get(state.graph).push(Object.assign({}, state, {
      pr_gpu_time: parseFloat(pr_gpu_time),
    }));
  }
  return state;
}

function readLog(pth) {
  var text  = readFile(pth);
  var lines = text.split('\n');
  var data  = new Map();
  var state = null;
  for (var ln of lines)
    state = readLogLine(ln, data, state);
  return data;
}




// PROCESS-*
// ---------

function processCsv(data) {
  var a = [];
  for (var rows of data.values())
    a.push(...rows);
  return a;
}




// MAIN
// ----

function main(cmd, log, out) {
  var data = readLog(log);
  if (path.extname(out)==='') cmd += '-dir';
  switch (cmd) {
    case 'csv':
      var rows = processCsv(data);
      writeCsv(out, rows);
      break;
    case 'csv-dir':
      for (var [graph, rows] of data)
        writeCsv(path.join(out, graph+'.csv'), rows);
      break;
    default:
      console.error(`error: "${cmd}"?`);
      break;
  }
}
main(...process.argv.slice(2));
