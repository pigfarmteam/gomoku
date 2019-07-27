var Contract = require('../contract');
var fs = require('fs');
var games = []
async function get(i, cb) {
  try {
    var g = await Contract.get.game(i);
    console.log('>> ', i)
    games.push({
      playerX: g.playerX,
      playerO: g.playerO,
      requestDraw: g.requestDraw,
      moveOf: g.moveOf,
      result: g.result,
      movedAtBlock: g.movedAtBlock,
      lastMove: g.lastMove,
      index: g.index,
      amount: parseInt(g.amount) / (10 ** 18)
    });
    get(i + 1, cb);
  }
  catch (ex) {
    console.log(ex);
    cb();
  }
}

get(0, () => {
  fs.writeFileSync('./games.json', JSON.stringify(games, null, 4));
});