pragma solidity 0.5.0;


contract Gomoku {
  struct Game {
    uint boardX;
    uint boardO;
    address payable playerX; // X
    address payable playerO; // O
    uint result; // 0: isPlaying, 1: X won, 2: O won, 3: Draw
    address moveOf;
    uint lastMove;
    uint movedAtBlock;
    address requestDraw;
    uint amount;
  }

  uint ALIAS_MIN_BALANCE = 0.0002 ether;
  uint ALIAS_FEE_BALANCE = 0.001 ether;

  uint SIZE = 15;
  uint BET_AMOUNT = 1 ether;
  uint FEE = 20;

  address owner;

  Game[] public games;
  mapping(uint => uint[]) public waitingGames;
  mapping(address => uint) public players;
  mapping(address => address payable) public aliasPlayer;

  event Move(address player, uint place, uint boardX, uint boardO, uint result);
  event Winner(uint gameId, address player);

  constructor(address _owner) public {
    owner = _owner;
    games.push(Game({
      boardX: 0,
      boardO: 0,
      playerX: address(0x0),
      playerO: address(0x0),
      result: 3,
      moveOf: address(0x0),
      lastMove: 0,
      movedAtBlock: 0,
      requestDraw: address(0x0),
      amount: 0
    }));
  }

  function gameOf(address player) external view
    returns(uint index, address playerX, address playerO, uint boardX,
      uint boardO, address moveOf, uint movedAtBlock, uint lastMove,
      uint result, address requestDraw, uint amount) {
    Game memory game = games[players[player]];
    index = players[player];
    result = game.result;
    playerX = game.playerX;
    playerO = game.playerO;
    moveOf = game.moveOf;
    boardX = game.boardX;
    boardO = game.boardO;
    movedAtBlock = game.movedAtBlock;
    lastMove = game.lastMove;
    requestDraw = game.requestDraw;
    amount = game.amount;
  }

  function getPlayerAndTryToSendFeeForAlias(address payable sender) private returns (address payable) {
    address payable player =  sender;
    if (aliasPlayer[sender] != address(0x00)) {
      player = aliasPlayer[sender];
      if (sender.balance < ALIAS_MIN_BALANCE) {
        sender.transfer(ALIAS_FEE_BALANCE);
      }
    }
    return player;
  }

  // winline: ROW = 1, COLUMN = 2, LEFT-RIGHT: 3, RIGHT-LEFT: 4
  function checkWin(uint board, uint winLine, uint start) private view returns(bool) {
    if (start >= SIZE * SIZE) return false;

    uint mark = 0;

    if (winLine == 1) {
      if (start % SIZE >= SIZE - 4) return false;
      for (uint i = start; i <= start + 4; i++) {
        mark |= 1 << i;
      }
    }
    else if (winLine == 2) {
      if (start / SIZE >=  SIZE - 4) return false;

      for (uint i = start; i <= start + SIZE * 4; i += SIZE) {
        mark |= 1 << i;
      }
    }
    else if (winLine == 3) {
      if (start % SIZE >= SIZE - 4 || start / SIZE >=  SIZE - 4) return false;

      for (uint i = start; i <= start + SIZE * 4 + 4; i += SIZE + 1) {
        mark |= 1 << i;
      }
    }
    else if (winLine == 4) {
      if (start % SIZE < 4 || start / SIZE >=  SIZE - 4) return false;

      for (uint i = start; i <= start + SIZE * 4 - 4; i += SIZE - 1) {
        mark |= 1 << i;
      }
    }

    return mark & board == mark;
  }

  function addNewGame(address payable player, uint amount, bool addToWaiting) private {
    games.push(Game({
      boardX: 0,
      boardO: 0,
      playerX: player,
      playerO: address(0x0),
      result: 0,
      moveOf: player,
      lastMove: 0,
      movedAtBlock: 0,
      requestDraw: address(0x0),
      amount: amount
    }));
    players[player] = games.length - 1;
    if (addToWaiting) {
      waitingGames[amount].push(games.length - 1);
    }
  }

  function removeFromWatingGame(uint index, uint amount) private {
    for (uint i = 0; i < waitingGames[amount].length; i++) {
      if (waitingGames[amount][i] == index) {
        waitingGames[amount][i] = waitingGames[amount][waitingGames[amount].length - 1];
        waitingGames[amount].pop();
        break;
      }
    }
  }

  function joinGame(address payable playerAlias, address withPlayer, uint roomIndex) external payable {
    address payable player = msg.sender;
    uint value = msg.value;

    require(value >= BET_AMOUNT);
    require(players[player] == 0 || games[players[player]].result >= 1);

    if (playerAlias != address(0x0)) {
      if (aliasPlayer[playerAlias] == address(0x0)) {
        aliasPlayer[playerAlias] = player;
      }
      if (playerAlias.balance < ALIAS_MIN_BALANCE) {
        playerAlias.transfer(ALIAS_FEE_BALANCE);
      }
    }

    uint gameIndex = withPlayer != address(0x0) ? players[withPlayer] : roomIndex;
    if (withPlayer == address(0x0) && roomIndex == 0) {
      gameIndex = waitingGames[value].length > 0 ? waitingGames[value][0] : 0;
    }
    else {
      gameIndex = withPlayer != address(0x0) ? players[withPlayer] : roomIndex;
      if (games.length <= roomIndex) {
        gameIndex = 0;
      }
    }

    Game storage game = games[gameIndex];
    if (game.result >= 1 ||
      (game.playerX != address(0x0) && game.playerO != address(0x0))) {
      addNewGame(player, value, withPlayer == address(0x0) && roomIndex == 0);
    }
    else {
      require(game.amount == value);
      if (game.playerX == address(0x0)) game.playerX = player;
      else game.playerO = player;

      game.movedAtBlock = block.number;
      game.moveOf = game.moveOf == address(0x0) ? player : game.moveOf;

      players[player] = gameIndex;

      removeFromWatingGame(gameIndex, value);
    }
  }

  function quitGame() external {
    address payable player = msg.sender;
    require(players[player] > 0);
    require(games[players[player]].result == 0);

    Game storage game = games[players[player]];
    if (game.playerX == address(0x0) || game.playerO == address(0x0)) {
      player.transfer(game.amount - ALIAS_FEE_BALANCE);
      game.result = 3;
      removeFromWatingGame(players[player], game.amount);
    }
    else if (game.boardX == 0 || game.boardO == 0) {
      game.result = 3;
      transferDraw(players[player]);
    }
    else if (game.playerX == player) {
      game.result = 2;
      transferO(players[player]);
    }
    else if (game.playerO == player) {
      game.result = 1;
      transferX(players[player]);
    }
  }

  function move(uint place, uint winLine, uint start) external {
    address payable player = getPlayerAndTryToSendFeeForAlias(msg.sender);

    Game storage game = games[players[player]];

    require(game.playerX != address(0x0) && game.playerO != address(0x0), "Error game");
    require(game.result == 0, "Game finished");
    require(game.moveOf == player, "Not your turn");
    require(place >= 0 && place < SIZE * SIZE, "Wrong place");
    require(game.boardX & game.boardO & (1 << place) == 0, "Cannot move to this place");
    uint board = 0;
    if (game.moveOf == game.playerX) {
      game.moveOf = game.playerO;
      game.boardX |= 1 << place;
      board = game.boardX;
    }
    else {
      game.moveOf = game.playerX;
      game.boardO |= 1 << place;
      board = game.boardO;
    }

    game.movedAtBlock = block.number;
    game.lastMove = place;
    emit Move(player, place, game.boardX, game.boardO, game.result);

    if (winLine > 0 && checkWin(board, winLine, start)) {
      if (game.playerX == player) {
        game.result = 1;
        transferX(players[player]);
        emit Winner(players[player], player);
      }
      else {
        game.result = 2;
        transferO(players[player]);
        emit Winner(players[player], player);
      }
    }
    else if (game.boardX | game.boardO >= (uint(-1) >> (256 - SIZE * SIZE))) {
      game.result = 3;
      transferDraw(players[player]);
    }
  }

  function claimFinishGame() external {
    address payable player = getPlayerAndTryToSendFeeForAlias(msg.sender);
    Game storage game = games[players[player]];
    if (game.result == 0 && game.movedAtBlock > 0 && block.number - game.movedAtBlock > 15) {
      if (game.boardX == 0 || game.boardO == 0) {
        game.result = 3;
        transferDraw(players[player]);
      }
      else if (game.moveOf == game.playerX) {
        game.result = 2;
        transferO(players[player]);
      }
      else if (game.moveOf == game.playerO) {
        game.result = 1;
        transferX(players[player]);
      }
    }
  }

  function requestDrawGame() external {
    address payable player = getPlayerAndTryToSendFeeForAlias(msg.sender);

    Game storage game = games[players[player]];

    if (game.result > 0) return;
    if (game.playerX != player && game.playerO != player) return;

    if (game.requestDraw == address(0x0)) {
      game.requestDraw = player;
    }
    else if (game.requestDraw != player) {
      game.result = 3;
      transferDraw(players[player]);
    }
  }

  function transferX(uint gameIndex) private {
    Game memory game = games[gameIndex];
    uint transferAmount = game.amount + game.amount / 100 * (100 - FEE);
    game.playerX.transfer(transferAmount);
  }

  function transferO(uint gameIndex) private {
    Game memory game = games[gameIndex];
    uint transferAmount = game.amount + game.amount / 100 * (100 - FEE);
    game.playerO.transfer(transferAmount);
  }

  function transferDraw(uint gameIndex) private {
    Game memory game = games[gameIndex];
    uint transferAmount = game.amount / 100 * (100 - FEE / 2);
    game.playerX.transfer(transferAmount);
    game.playerO.transfer(transferAmount);
  }

  function withdraw(uint amount) external {
    require(msg.sender == owner);
    msg.sender.transfer(amount);
  }

  function transferOwner(address newOwner) external {
    owner = newOwner;
  }

  function setting(uint size, uint betAmount, uint min, uint fee) external {
    require(msg.sender == owner);
    SIZE = size;
    ALIAS_MIN_BALANCE = min;
    ALIAS_FEE_BALANCE = fee;
    BET_AMOUNT = betAmount;

    SIZE = SIZE > 10 ? SIZE : 10;
    SIZE = SIZE <= 15 ? SIZE : 15;

    ALIAS_MIN_BALANCE = ALIAS_MIN_BALANCE > 0.0001 ether ? ALIAS_MIN_BALANCE : 0.0001 ether;
    ALIAS_MIN_BALANCE = ALIAS_MIN_BALANCE < 0.1 ether ? ALIAS_MIN_BALANCE : 0.1 ether;

    ALIAS_FEE_BALANCE = ALIAS_FEE_BALANCE > 0.001 ether ? ALIAS_FEE_BALANCE : 0.001 ether;
    ALIAS_FEE_BALANCE = ALIAS_FEE_BALANCE < 0.5 ether ? ALIAS_FEE_BALANCE : 0.5 ether;


    BET_AMOUNT = BET_AMOUNT > 1 ether ? BET_AMOUNT : 1 ether;
    BET_AMOUNT = BET_AMOUNT < 1000 ether ? BET_AMOUNT : 1000 ether;
  }

  function () external payable {
    require(msg.sender == owner);
  }
}