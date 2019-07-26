import abi from './abi';
// export default {
//   ABI: abi,

//   RPC: process.env.NODE_ENV === 'production' ?
//     'https://testnet.tomochain.com' :
//     'https://testnet.tomochain.com',

//   RPC_READ: process.env.NODE_ENV === 'production' ?
//     'https://testnet.tomochain.com' :
//     'https://testnet.tomochain.com',

//   RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
//     'wss://testnet.tomochain.com/ws' :
//     'wss://testnet.tomochain.com/ws',

//   NETWORK_ID: process.env.NODE_ENV === 'production' ? '89' : '89',
//   ADDRESS: process.env.NODE_ENV === 'production' ?
//     '0x6d88d78a7cb573b9f0ea23e67fee731194914c23' :
//     '0x6d88d78a7cb573b9f0ea23e67fee731194914c23'
// }

export default {
  ABI: abi,

  RPC: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://testnet.tomochain.com',

  RPC_READ: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://testnet.tomochain.com',

  RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
    'wss://ws.tomochain.com' :
    'wss://testnet.tomochain.com/ws',

  NETWORK_ID: process.env.NODE_ENV === 'production' ? '88' : '89',
  ADDRESS: process.env.NODE_ENV === 'production' ?
    '0xb07232de9fe6f486d604d5bad9d598b9d05139b4' :
    '0x1e3f62e2e1be8580e0b540b3c2bd9d5a91709ef2'
}

// export default {
//   ABI: abi,

//   RPC: process.env.NODE_ENV === 'production' ?
//     'https://rpc.tomochain.com' :
//     'https://rpc.tomochain.com',

//   RPC_READ: process.env.NODE_ENV === 'production' ?
//     'https://rpc.tomochain.com' :
//     'https://rpc.tomochain.com',

//   RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
//     'wss://ws.tomochain.com' :
//     'wss://ws.tomochain.com',

//   NETWORK_ID: process.env.NODE_ENV === 'production' ? '88' : '89',
//   ADDRESS: process.env.NODE_ENV === 'production' ?
//     '0xf044065341b3fcf3689dcd6a120c0c86e9479c98' :
//     '0xf044065341b3fcf3689dcd6a120c0c86e9479c98'
// }

// export default {
//   ABI: abi,

//   RPC: process.env.NODE_ENV === 'production' ?
//     'https://rpc.tomochain.com' :
//     'http://localhost:8545',

//   RPC_READ: process.env.NODE_ENV === 'production' ?
//     'https://rpc.tomochain.com' :
//     'http://localhost:8545',

//   RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
//     'wss://ws.tomochain.com' :
//     'wss://testnet.tomochain.com/ws',

//   NETWORK_ID: process.env.NODE_ENV === 'production' ? '88' : '89',
//   ADDRESS: process.env.NODE_ENV === 'production' ?
//     '0x305f55a3d55e01eed0b2b33fa1fd035ac5d086f7' :
//     '0x67b9345f730ca30e3202edd78d0b6e83581fbe54'
// }