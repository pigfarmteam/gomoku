<template>
  <div class="move-of">
    <div style="width: 100px;" :style="{ opacity: game.moveOf == game.playerX ? 1 : 0.4 }">
      <img src="./imgs/x.svg" width="30px"/>
      <div style="font-size: 13px;">{{playerXName || '&nbsp;'}}</div>
    </div>
    <div>
      <div v-if="game.result == 0">
        <div v-if="showCountDown" class="animated flipInX">
          <div>{{status}}</div>
          <div class="count-down">{{game.countDown > 30 ? 30 : game.countDown}}s</div>
        </div>
        <div v-else class="animated status" :class="statusAnimated">{{status}}</div>
      </div>
      <div v-else class="animated bounceIn">
        <div style="font-size: 30px; line-height: 30px;">{{ game.result == 3 ? '😅' : (isWon ? '🏆' : '😭')}}</div>
        <div style="color: #00b500; font-size: 30px; line-height: 35px;">{{gameResult}}</div>
      </div>
    </div>
    <div style="width: 100px;" :style="{ opacity: game.moveOf == game.playerO ? 1 : 0.4 }">
      <img src="./imgs/o.svg" width="30px"/>
      <div>{{playerOName || '&nbsp;'}}</div>
    </div>
    <div v-if="full" class="hightlight-player" :class="game.moveOf == game.playerX ? 'left' : 'right'" />
  </div>
</template>

<script>
function address0(add) {
  return add == '0x0000000000000000000000000000000000000000'
};
var admins = {
  '0xae1f68b38f97dcabc8700daa1d0ea6caf3c663cf': 'Monkaye',
  '0x0237047e9ebb9753939278485ca5ea31a336fc41': 'PigBOSS',
  '0xbb6a9d599824e664eeba9a3ec17296c152eeac12': 'Leo | Mod',
  '0x8c3e84ba3180f6aed7a8ae16ee265eee78392bef': 'Nobita | Mod',
  '0xe43b6d2bc66e84bfa8b693c1bb27e420d696d440': 'Chaiko | Mod',
  '0xb0fe0e7f8583821172555f12b77c07975239da0c': 'Alex @ TOMO',
  '0xc914dcff3b059bfcc1abf344ac6fdc8e8d8117ff': "Nolan | Mod"
}
export default {
  props: ["game", "statusAnimated", "showCountDown", 'address'],
  computed: {
    isInGame() {
      return this.address == this.game.playerX || this.address == this.game.playerO;
    },
    playerXName() {
      return this.game.playerX == this.address ? (admins[this.address] || 'You') :
        this.game.playerX == '0x0000000000000000000000000000000000000000' ? '' :
          (admins[this.game.playerX] || this.game.playerX.slice(0, 7))
    },
    playerOName() {
      return this.game.playerO == this.address ? (admins[this.address] || 'You') :
        this.game.playerO == '0x0000000000000000000000000000000000000000' ? '' :
          (admins[this.game.playerO] || this.game.playerO.slice(0, 7))
    },
    gameResult() {
      if (this.isInGame) {
        if (!address0(this.game.playerX) && !address0(this.game.playerO)) {
          switch (this.game.result) {
            case 1: return this.address == this.game.playerX ? 'You Won' : 'You Lost';
            case 2: return this.address == this.game.playerO ? 'You Won' : 'You Lost';
            case 3: return 'DRAW';
            default: '';
          }
        }
      }
      else {
        switch (this.game.result) {
          case 1: return this.address == this.game.playerX ? 'X Won' : 'O Lost';
          case 2: return this.address == this.game.playerO ? 'O Won' : 'X Lost';
          case 3: return 'DRAW';
          default: '';
        }
      }
    },
    isWon() {
      if (this.game.result == 1) {
        if (this.game.playerX == this.address) {
          return true;
        }
        else {
          return false;
        }
      }
      else if (this.game.result == 2) {
        if (this.game.playerO == this.address) {
          return true;
        }
        else {
          return false;
        }
      }
    },
    status() {
      if (this.full) {
        if (this.game.moveOf == this.address) {
          return 'Your Turn';
        }
        else if (this.game.moveOf == this.game.playerX) {
          return "X's Turn";
        }
        else {
          return "O's Turn";
        }
      }
    },
    full() {
      return !address0(this.game.playerX) && !address0(this.game.playerO)
    }
  }
}
</script>

<style scoped>
  .move-of {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 20px 5px 20px;
    margin: 0px 5px 0px 5px;
    color: #333333;
    background: rgba(256, 256, 256, 0.8);
    border-radius: 5px 5px 0 0;
    position: relative;
  }

  @media(max-width: 767px) {
    .move-of {
      margin: 0px 0px 0px 0px;
    }
  }

  .count-down {
    font-size: 45px;
    line-height: 35px;
    color: #00b500;
  }

  .status {
    color: #ff9800;
    font-size: 30px;
  }

  .hightlight-player {
    position: absolute;
    height: 3px;
    width: 90px;
    bottom: 0;
    background: #2196F3;
    transition: 0.5s all;
  }

  .hightlight-player.left {
    left: 20px;
    background: #2196F3;
  }

  .hightlight-player.right {
    left: calc(100% - 110px);
    background: #F44336;
  }
</style>
