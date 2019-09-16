var fs = require('fs');
var admins = {
  '0xae1f68b38f97dcabc8700daa1d0ea6caf3c663cf': 'Monkaye',
  '0x0237047e9ebb9753939278485ca5ea31a336fc41': 'PigBOSS',
  '0xbb6a9d599824e664eeba9a3ec17296c152eeac12': 'Leo | Mod',
  '0x8c3e84ba3180f6aed7a8ae16ee265eee78392bef': 'Nobita | Mod',
  '0xe43b6d2bc66e84bfa8b693c1bb27e420d696d440': 'Chaiko | Mod',
  '0xb0fe0e7f8583821172555f12b77c07975239da0c': 'Alex @ TOMO',
  '0xc914dcff3b059bfcc1abf344ac6fdc8e8d8117ff': 'Nolan | Mod',
}

var rejectAddresses = {
  // '0xa23cebfe11b4b81476b3a1d1516e6da6608585aa': 'Long @ TOMO',
  // '0xad124feb060a7afd77a05215485ef7f28ce2b1ea': 'Tung @ TOMO'
}

var rejectId = {
  // '40': 1,
  // '44': 1
}

var games = JSON.parse(fs.readFileSync('./games.json', 'utf8'));

games = games
  .filter(e => e.result == 1 || e.result == 2)
  // .filter(e => admins[e.playerO] || admins[e.playerX])
  // .filter(e => !(admins[e.playerX] && admins[e.playerO]))
  // .filter(e => !((rejectAddresses[e.playerX] || rejectAddresses[e.playerO]) && (admins[e.playerX] || admins[e.playerO])))
  // .filter(e => admins[e.playerX] && e.result == 2 || admins[e.playerO] && e.result == 1)
  // .filter(e => !rejectId[e.index])

console.log(games.length);
console.log(games
  .map(e => `${e.index}: ${admins[e.playerX] ? e.playerO : e.playerX}, admin: ${admins[e.playerX] || admins[e.playerO]}, ${e.amount}`)
  .join('\n'));