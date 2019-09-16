var abi = require('./abi');

module.exports = {
  ABI: abi,

  RPC: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://rpc.tomochain.com',

  RPC_READ: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://rpc.tomochain.com',

  RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
    'wss://ws.tomochain.com' :
    'wss://ws.tomochain.com',

  NETWORK_ID: process.env.NODE_ENV === 'production' ? '88' : '88',
  ADDRESS: process.env.NODE_ENV === 'production' ?
    '0x6a7f02167c5fd316f631931c977b28388e53bdf9' :
    '0x6a7f02167c5fd316f631931c977b28388e53bdf9'
}