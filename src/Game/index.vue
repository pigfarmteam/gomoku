<template>
  <div class="game">
    <div class="game-top">
      <div class="game-top-container">
        <NavBar :game="game" @quit="quit" @chat="toggleChat" />
        <Status :game="game" :address="address" :statusAnimated="statusAnimated" :showCountDown="showCountDown" />
      </div>
    </div>
    <div class="game-board">
      <Board :game="game" :size="gameSize" @move="move"/>
    </div>
    <Waiting v-if="isWaiting" :waitingAnimate="waitingAnimate" :showAlert="isInGame">
      <button v-if="!isInGame && !full && notFinish(game)" @click="joinGame" class="btn joingame-btn animated fadeIn">
        Join Game
      </button>
    </Waiting>
    <button v-if="isInGame && full && !notFinish(game)" @click="playAgain" class="btn playagain-btn animated fadeIn">
      Play again
    </button>

    <button v-if="isInGame && full && notFinish(game)" @click="requestDrawGame" class="btn-i" style="margin-top: 10px; margin-bottom: 15px;">
      <span style="font-size: 20px">🤝</span>&nbsp;&nbsp;{{
        is0x0(game.requestDraw) ? 'Request Draw' :
        isMe(game.requestDraw) ? 'Requested' : 'Accept Draw'}}
    </button>
    <div v-if="isInGame && full && notFinish(game) && !is0x0(game.requestDraw) && isMe(game.requestDraw)"
      style="color: rgba(255, 255, 255, 0.6); font-size: 13px; font-family: monospace; margin-top: -10px; margin-bottom: 15px;">
      {{game.requestDraw == game.playerO ? 'Continue play until Player O accept draw' : 'Continue play until Player Y accept draw'}}
    </div>
    <div v-if="isInGame && full && notFinish(game) && !is0x0(game.requestDraw) && !isMe(game.requestDraw)"
      style="color: rgba(255, 255, 255, 0.6); font-size: 13px; font-family: monospace; margin-top: -10px; margin-bottom: 15px;">
      {{game.requestDraw == game.playerO ? 'Player O request Draw' : 'Player Y request Draw'}}
    </div>

    <div v-if="showChat" v-show="showChat % 2" class="chatbox animated fadeInUp faster">
      <div class="title">
        <div>{{full ? `ChatBox` : 'ChatBox | Global' }}</div>
        <button @click="toggleChat" class="chatbox-close-btn"><img src="./imgs/close.svg" width="15px" /></button>
      </div>
      <div style="height: 300px;">
        <iframe v-if="full" :src="`https://anonymous-chat-group.herokuapp.com/gomoku-pigfarm-${[game.playerX, game.playerO].sort().join('')}#${address}|${address.slice(0, 5)}`" frameborder="0"></iframe>
        <iframe v-else :src="`https://anonymous-chat-group.herokuapp.com/gomoku-pigfarm#${address}|${address.slice(0, 5)}`" frameborder="0"></iframe>
      </div>
    </div>

    <Modal v-if="errMsg" title="Error" @close="errMsg = ''" :isError="true">
      <div>
        {{errMsg}}
      </div>
    </Modal>

    <Modal v-if="showConfirmModal" title="Confirm Quit" @close="showConfirmModal = false">
      <div>
        Do you want quit this game? You will be lost this game!
        <button class="modal-btn" @click="agreeQuit">OK, I Agree</button>
        <button class="modal-btn-secondary" @click="showConfirmModal = false">Cancel</button>
      </div>
    </Modal>
  </div>
</template>

<script>

import Contract from '../contract';
import BigNumber from 'bignumber.js';
import Board from './Board';
import Waiting from './Waiting';
import NavBar from './NavBar';
import Status from './Status';
import Modal from '../Modal';
function address0(add) {
  return add == '0x0000000000000000000000000000000000000000'
};

const SIZE = 15;
export default {
  name: 'Game',
  components: {
    Board,
    Waiting,
    NavBar,
    Status,
    Modal
  },
  data() {
    return {
      gameSize: SIZE,
      isMoving: false,
      isWaiting: false,
      isDoingTransaction: false,
      address: '',
      showCountDown: false,
      statusAnimated: '',
      waitingAnimate: '',
      isClaimingFinishGame: false,
      errMsg: '',
      showConfirmModal: false,
      showChat: 0,
      game: {
        board: this.emptyBoard(),
        playerX: '0x0000000000000000000000000000000000000000',
        playerO: '0x0000000000000000000000000000000000000000',
        moveOf: '0x0000000000000000000000000000000000000000',
        result: 0,
        movedAtBlock: 0,
        lastMove: 0,
        countDown: 30,
        amount: 0,
        index: 0,
        requestDraw: '0x0000000000000000000000000000000000000000'
      }
    }
  },
  created() {
    if (this.gameId > 0) {
      this.init();
    }
    if (Contract.accountInfo().address) {
      this.address = Contract.accountInfo().address
      this.init();
      return;
    }
    if (window.web3 && window.web3.currentProvider) {
      if (window.web3.currentProvider.isTomoWallet) {
        Contract.login({
          tomowallet: true
        }, (err, address) => {
          this.address = address;
          this.init();
        });
      }
      else if (window.web3.currentProvider.isMetaMask) {
        Contract.login({
          metamask: true
        }, (err, address) => {
          this.address = address;
          this.init();
        });
      }
    }
    else {
      var privateKey = location.search.replace('?', '');
      privateKey = privateKey || sessionStorage.privateKey;
      if (privateKey && privateKey.trim()) {
        if (privateKey.indexOf(' ') > 0) {
          Contract.login({
            privateKey,
            hdpath: "m/44'/889'/0'/0"
          }, (err, address) => {
            this.address = address;
            this.init();
          });
        }
        else {
          Contract.login({
            privateKey
          }, (err, address) => {
            this.address = address;
            this.init();
          });
        }
      }
    }
  },
  destroyed() {
    this.stopUpdateGame();
  },
  computed: {
    gameId() {
      var v = this.$route.params.id || 0;
      return parseInt(v) || 0;
    },
    full() {
      return !address0(this.game.playerX) && !address0(this.game.playerO)
    },
    isInGame() {
      return this.address == this.game.playerX || this.address == this.game.playerO;
    },
  },
  watch: {
    '$route.params.id': {
      handler(newId, oldId) {
        if (newId != oldId) {
          this.reset();
          this.getGame();
        }
      }
    }
  },
  methods: {
    moveBoardCenter() {
      setTimeout(() => {
        window.scrollTo((450 - window.innerWidth) / 2, 0);
      }, 100);
    },
    toggleChat() {
      this.showChat += 1;
    },
    emptyBoard() {
      var result = [];
      for (var i = 0; i < SIZE * SIZE; i++) {
        result.push(0);
      }
      return result;
    },
    init() {
      this.getGame();
      this.startUpdateGame();
      this.moveBoardCenter();
    },
    isMe(add) {
      return add == this.address
    },
    is0x0(add) {
      return address0(add);
    },
    notFinish(game) {
      return game.result == 0
    },
    async agreeQuit() {
      try {
        if (this.isDoingTransaction) return;
        this.$Progress.start();
        this.isDoingTransaction = true;
        this.showConfirmModal = false;
        var hash = await Contract.quitGame();
        await Contract.get.checkTx(hash);
        this.isDoingTransaction = false;
        this.$Progress.finish();
        setTimeout(() => this.$router.back(), 100);
      }
      catch (ex) {
        console.error(ex);
        this.isDoingTransaction = false;
        var msg = ex.toString();
        this.$Progress.finish();

        if (msg.indexOf('timeout') >= 0) {
          window.location.reload();
          return;
        }

        if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
          this.errMsg = 'Error, Cannot quit this game. Refresh to try again. Error details: ' + msg;
        }
      }
    },
    async quit() {
      try {
        if (this.isDoingTransaction) return;
        else if (!this.isInGame) {
          this.isDoingTransaction = false;
          console.log(this.$router);
          this.$router.replace('/');
        }
        else if (this.game.result > 0 || (address0(this.game.playerX) && address0(this.game.playerO))) {
          this.isDoingTransaction = false;
          this.$router.replace('/');
        }
        else if (address0(this.game.playerX) || address0(this.game.playerO)) {
          this.$Progress.start();
          this.isDoingTransaction = true;
          var hash = await Contract.quitGame();
          await Contract.get.checkTx(hash);
          this.isDoingTransaction = false;
          this.$Progress.finish();
          setTimeout(() => this.$router.back(), 100);
        }
        else if (this.game.result == 0) {
          this.showConfirmModal = true;
        }
        else {
          this.isDoingTransaction = false;
          this.$router.replace('/');
        }
      }
      catch (ex) {
        console.error(ex);
        this.isDoingTransaction = false;
        var msg = ex.toString();
        this.$Progress.finish();

        if (msg.indexOf('timeout') >= 0) {
          window.location.reload();
          return;
        }

        if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
          this.errMsg = 'Error, Cannot quit this game. Refresh to try again. Error details: ' + msg;
        }
      }
    },
    reset() {
      this.isMoving = false;
      this.isWaiting = false;
      this.showCountDown = false;
      this.statusAnimated = '';
      this.waitingAnimate = '';
      this.isClaimingFinishGame = false;
      this.game = {
        board: this.emptyBoard(),
        playerX: '0x0000000000000000000000000000000000000000',
        playerO: '0x0000000000000000000000000000000000000000',
        moveOf: '0x0000000000000000000000000000000000000000',
        result: 0,
        movedAtBlock: 0,
        lastMove: 0,
        countDown: 30,
        amount: 0,
        index: 0,
        requestDraw: '0x0000000000000000000000000000000000000000'
      }
    },
    async joinGame() {
      if (this.isDoingTransaction) return;
      this.$Progress.start();
      var hash = await Contract.joinGame(
        this.game.playerX || this.game.playerO
      , 0, this.game.amount);
      await Contract.get.checkTx(hash);
      this.getGame();
      this.isDoingTransaction = false;
      this.$Progress.finish();
      this.moveBoardCenter();
    },
    async playAgain() {
      if (this.isDoingTransaction) return;
      this.$Progress.start();
      try {
        this.isDoingTransaction = true;
        var hash = await Contract.joinGame(
          // this.game.playerX == this.address ? this.game.playerO : this.game.playerX
          '0x0000000000000000000000000000000000000000' // TODO: uncomment after event
        , 0, this.game.amount);
        await Contract.get.checkTx(hash);
        this.reset();
        this.getGame();
        this.isDoingTransaction = false;
        this.$Progress.finish();
        this.moveBoardCenter();
      }
      catch (ex) {
        this.isDoingTransaction = false;
        console.error(ex);
        var msg = ex.toString();
        this.$Progress.finish();

        if (msg.indexOf('timeout') >= 0) {
          window.location.reload();
          return;
        }

        if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
          this.errMsg = 'Error, Cannot play again. Refresh to try again. Error details: ' + msg;
        }
      }
    },
    async move(i) {
      if (
        this.isInGame &&
        this.full &&
        this.game.result == 0 &&
        this.game.moveOf == this.address &&
        this.game.board[i] == 0 &&
        this.isMoving == false
      ) {
        var backupBoard = [].concat(this.game.board);
        try {
          this.isMoving = true;
          this.$Progress.start();
          this.game.board[i] = this.address == this.game.playerX ? 1 : 2;
          this.game.board = [].concat(this.game.board);
          var line = this.checkWin(this.game.board, i, this.game.board[i]);
          var hash;
          if (line) {
            hash = await Contract.move(i, line.winLine, line.start);
          }
          else {
            hash = await Contract.move(i, 0, 0);
          }
          await Contract.get.checkTx(hash);
          this.$Progress.finish();
          this.isMoving = false;
        }
        catch(ex) {
          console.error(ex);
          this.isMoving = false;
          this.$Progress.finish();
          this.game.board = backupBoard;
          var msg = ex.toString();
          if (msg.indexOf('timeout') >= 0) {
            window.location.reload();
            return;
          }

          if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
            this.errMsg = 'Error, Cannot move. Refresh to try again. Error details: ' + msg;
          }
        };
      }
    },
    checkWin(board, indexOfMove, v) {
      var XY = function (_x, _y) {
        return _y * SIZE + _x;
      }
      const B = [];
      for (var i = 0; i < SIZE; i++) {
        B.push(board.slice(i * SIZE, i * SIZE + SIZE));
      }

      var x = indexOfMove % SIZE;
      var y = Math.floor(indexOfMove / SIZE);


      var count = 1;
      var line = { winLine: 1, start: indexOfMove, end: indexOfMove };
      //Check by Row
      for (var i = 1; i <= 4 && x - i >= 0; i++)
        if (B[y][x - i] == v) { count++; line.start = XY(x - i, y); }
      for (var i = 1; i <= 4 && x + i < SIZE; i++)
        if (B[y][x + i] == v) { count++; line.end = XY(x + i, y); }

      if (count >= 5) return line;

      count = 1;
      line = { winLine: 2, start: indexOfMove, end: indexOfMove };
      //Check by Collum
      for (var i = 1; i <= 4 && y - i >= 0; i++)
        if (B[y - i][x] == v) { count++; line.start = XY(x, y - i); }
      for (var i = 1; i <= 4 && y + i < SIZE; i++)
        if (B[y + i][x] == v) { count++; line.end = XY(x, y + i); }

      if (count >= 5) return line;

      count = 1;
      line = { winLine: 3, start: indexOfMove, end: indexOfMove };
      //Check by Diagonal Left to Right
      for (var i = 1; i <= 4 && x - i >= 0 && y - i >= 0; i++)
        if (B[y - i][x - i] == v) { count++; line.start = XY(x - i, y - i); }
      for (var i = 1; i <= 4 && x + i < SIZE && y + i < SIZE; i++)
        if (B[y + i][x + i] == v) { count++; line.end = XY(x + i, y + i) }

      if (count >= 5) return line;

      count = 1;
      line = { winLine: 4, start: indexOfMove, end: indexOfMove };
      //Check by Diagonal Right to Left
      for (var i = 1; i <= 4 && x + i < SIZE && y - i >= 0; i++)
        if (B[y - i][x + i] == v) { count++; line.start = XY(x + i, y - i); }
      for (var i = 1; i <= 4 && x - i >= 0 && y + i < SIZE; i++)
        if (B[y + i][x - i] == v) { count++; line.end = XY(x - i, y + i); }

      if (count >= 5) return line;

      return null;
    },
    async getGame() {
      if (this.address || this.gameId > 0) {
        var game = null;
        if (this.gameId) {
          game = await Contract.get.game(this.gameId)
        }
        else {
          game = await Contract.get.gameOf(this.address)
        }
        // if (this.gameId > 0 && game.playerX != this.address && game.playerO != this.address) {
        //   return;
        // }
        this.claimFinishGame(game);
        var boardX = BigNumber(game.boardX).toString(2);
        var boardO = BigNumber(game.boardO).toString(2);
        game.board = [].concat(this.game.board);
        for (var i = 1; i <= SIZE * SIZE; i++) {
          if (boardX.length - i >= 0 && boardX[boardX.length - i] == '1') {
            game.board[i - 1] = 1;
          }
          if (boardO.length - i >= 0 && boardO[boardO.length - i] == '1') {
            game.board[i - 1] = 2;
          }
        }

        if (this.game.index != game.index ||
          this.game.playerX != game.playerX ||
          this.game.playerO != game.playerO) {
          this.resetStep();
          this.setUpNewGame(game);
        }
        else if (this.game.moveOf != game.moveOf) {
          this.resetStep();
          this.setUpNewMove();
        }

        this.game.result = game.result;
        this.game.moveOf = game.moveOf;
        this.game.requestDraw = game.requestDraw;
        this.game.board = game.board;
        this.game.movedAtBlock = game.movedAtBlock;
        this.game.lastMove = game.lastMove;
        this.game.index = game.index;
        this.game.playerX = game.playerX;
        this.game.playerO = game.playerO;
        this.game.amount = BigNumber(game.amount).dividedBy(10 ** 18).toNumber();

        var lastBlock = await Contract.get.lastBlock(true);
        this.game.countDown = ((this.game.movedAtBlock + 15) - lastBlock.number) * 2;

        if (this.game.countDown < 0) {
          this.game.countDown = 0;
          clearInterval(this.intervalCountDown);
          this.intervalCountDown = 0;
        }
        else {
          if (!this.intervalCountDown) {
            this.startCountDown();
          }
        }
      }
    },
    stopUpdateGame() {
      Contract.get.offListenEvent('NEW_BLOCK', 'ONNEWBLOCK');
      clearInterval(this.intervalCountDown);
      this.intervalCountDown = 0;
      clearInterval(this.timoutStatus);
      clearInterval(this.timeoutShowCountDown);
    },
    startCountDown() {
      this.intervalCountDown = setInterval(() => {
        this.game.countDown -= 1;
        if (this.game.countDown < 0) {
          this.game.countDown = 0;
          clearInterval(this.intervalCountDown);
          this.intervalCountDown = 0;
        }
      }, 1000);
    },
    startUpdateGame() {
      Contract.get.onListenEvent('NEW_BLOCK', () => {
        this.getGame();
      }, 'ONNEWBLOCK');
    },
    resetStep() {
      clearTimeout(this.timoutStatus);
      clearTimeout(this.timeoutShowCountDown);
      clearTimeout(this.timeoutWaiting);
      clearInterval(this.intervalCountDown);
      this.intervalCountDown = 0;
      this.statusAnimated = 'bounceIn';
      this.showCountDown = false;
    },
    setUpNewMove() {
      this.timoutStatus = setTimeout(() => {
        this.statusAnimated = 'zoomOut';
        this.timeoutShowCountDown = setTimeout(() => {
          this.showCountDown = true;
        }, 500);
      }, 3000);
    },
    setUpNewGame(game) {
      // if (game.result == 3 && (address0(game.playerX) || address0(game.playerO))) {
      //   this.$router.replace('/');
      //   return;
      // }
      if (!this.isWaiting) {
        this.isWaiting = game.result == 0 && (address0(game.playerX) || address0(game.playerO));
      }
      if (!address0(game.playerX) && !address0(game.playerO)) {
        if (this.isWaiting) {
          this.waitingAnimate = 'bounceOutUp';
          this.timeoutWaiting = setTimeout(() => {
            this.isWaiting = false;
            this.setUpNewMove();
          }, 1000);
        }
        else {
          this.setUpNewMove();
        }
      }
    },
    async claimFinishGame(game) {
      if (!this.isInGame) return;

      try {
        if (!game) return;
        if (!this.address) return;
        if (this.isClaimingFinishGame) return;
        if (address0(game.playerX) || address0(game.playerO)) return;
        if (game.result > 0) return;
        if (game.playerX != this.address && game.playerO != this.address) return;
        var lastBlock = await Contract.get.lastBlock(true);
        if (game.movedAtBlock > 0 && lastBlock.number - game.movedAtBlock > 20) {
          this.isClaimingFinishGame = true;
          var hash = await Contract.claimFinishGame();
          await Contract.get.checkTx(hash);
          this.getGame();
        }
      }
      catch (ex) {
        console.error(ex);
        var msg = ex.toString();

        if (msg.indexOf('timeout') >= 0) {
          window.location.reload();
          return;
        }

        if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
          this.errMsg = 'Error, Cannot claim finish this game. Refresh to try again. Error details: ' + msg;
        }
      }
    },
    async requestDrawGame() {
      try {
        if (!this.isInGame) return;
        if (this.isDoingTransaction) return;
        this.$Progress.start();
        this.isDoingTransaction = true;
        var hash = await Contract.requestDrawGame();
        await Contract.get.checkTx(hash);
        this.$Progress.finish();
        this.isDoingTransaction = false;
      }
      catch (ex) {
        console.error(ex);
        this.isDoingTransaction = false;
        var msg = ex.toString();
        this.$Progress.finish();

        if (msg.indexOf('timeout') >= 0) {
          window.location.reload();
          return;
        }

        if (msg.indexOf('cancelled') == -1 && msg.indexOf('User denied transaction signature.') == -1) {
          this.errMsg = 'Error, Cannot request draw. Refresh to try again. Error details: ' + msg;
        }
      }
    }
  }
}
</script>

<style scoped>
.game {
  width: 450px;
  margin: auto;
}

@media(max-width: 767px) {
  .game-top {
    position: fixed;
    z-index: 9999;
    left: 0;
    right: 0;
    display: flex;
    justify-content: center;
  }

  .game-top-container {
    background: #223358;
    box-shadow: 0 1px 5px rgba(0, 0, 0, 0.48);
    /* width: 450px; */
    width: 100vw;
  }

  .game-board {
    padding-top: 134px;
  }

  .chatbox {
    width: 100vw;
    background: #ffffff;
    /* position: absolute !important; */
    /* bottom: -300px !important; */
  }
  /* .game-top-container {
  } */
}

.chatbox {
  margin-top: 50px;
  position: fixed;
  bottom: 0;
  right: 0;
}


.btn {
  background: white;
  padding: 10px 40px;
  font-family: var(--font-serif);
  border-radius: 50px;
  font-size: 30px;
  color: #03A9F4;
  border: none;
  box-shadow: 1px 1px 30px rgba(0, 0, 0, 0.48);
  cursor: pointer;
  outline: none;
}

.btn:hover {
  box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.48);
}
.btn-i {
  background: transparent;
  padding: 5px 20px;
  font-family: var(--font-serif);
  border-radius: 50px;
  font-size: 16px;
  color: #ffffff;
  border: none;
  box-shadow: 1px 1px 30px rgba(0, 0, 0, 0.48);
  cursor: pointer;
  outline: none;
  margin: 2px;
}

.btn-i:hover {
  box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.48);
}

.playagain-btn {
  margin-top: 15px;
  font-size: 20px;
  z-index: 9999;
  position: fixed;
  bottom: 15px;
  left: 50%;
  transform: translateX(-50%);
}
.joingame-btn {
  margin-top: 15px;
  font-size: 20px;
  bottom: 15px;
}
</style>
