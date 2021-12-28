/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { USDC, USDCInterface } from "../USDC";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [],
    name: "DOMAIN_SEPARATOR",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "PERMIT_TYPEHASH",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "allowance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "nonces",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "deadline",
        type: "uint256",
      },
      {
        internalType: "uint8",
        name: "v",
        type: "uint8",
      },
      {
        internalType: "bytes32",
        name: "r",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "s",
        type: "bytes32",
      },
    ],
    name: "permit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x60e06040523480156200001157600080fd5b506040518060400160405280600481526020017f55534443000000000000000000000000000000000000000000000000000000008152506040518060400160405280600481526020017f5553444300000000000000000000000000000000000000000000000000000000815250600682600090805190602001906200009892919062000194565b508160019080519060200190620000b192919062000194565b508060ff1660808160ff16815250504660a08181525050620000d8620000e860201b60201c565b60c0818152505050505062000445565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f60006040516200011c919062000354565b60405180910390206040518060400160405280600181526020017f310000000000000000000000000000000000000000000000000000000000000081525080519060200120463060405160200162000179959493929190620003e8565b60405160208183030381529060405280519060200120905090565b828054620001a29062000273565b90600052602060002090601f016020900481019282620001c6576000855562000212565b82601f10620001e157805160ff191683800117855562000212565b8280016001018555821562000212579182015b8281111562000211578251825591602001919060010190620001f4565b5b50905062000221919062000225565b5090565b5b808211156200024057600081600090555060010162000226565b5090565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b600060028204905060018216806200028c57607f821691505b60208210811415620002a357620002a262000244565b5b50919050565b600081905092915050565b60008190508160005260206000209050919050565b60008154620002d88162000273565b620002e48186620002a9565b9450600182166000811462000302576001811462000314576200034b565b60ff198316865281860193506200034b565b6200031f85620002b4565b60005b83811015620003435781548189015260018201915060208101905062000322565b838801955050505b50505092915050565b6000620003628284620002c9565b915081905092915050565b6000819050919050565b62000382816200036d565b82525050565b6000819050919050565b6200039d8162000388565b82525050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000620003d082620003a3565b9050919050565b620003e281620003c3565b82525050565b600060a082019050620003ff600083018862000377565b6200040e602083018762000377565b6200041d604083018662000377565b6200042c606083018562000392565b6200043b6080830184620003d7565b9695505050505050565b60805160a05160c0516117a1620004756000396000610774015260006107400152600061071a01526117a16000f3fe608060405234801561001057600080fd5b50600436106100f55760003560e01c806340c10f19116100975780639dc29fac116100665780639dc29fac1461028a578063a9059cbb146102a6578063d505accf146102d6578063dd62ed3e146102f2576100f5565b806340c10f19146101f057806370a082311461020c5780637ecebe001461023c57806395d89b411461026c576100f5565b806323b872dd116100d357806323b872dd1461016657806330adf81f14610196578063313ce567146101b45780633644e515146101d2576100f5565b806306fdde03146100fa578063095ea7b31461011857806318160ddd14610148575b600080fd5b610102610322565b60405161010f9190610f8c565b60405180910390f35b610132600480360381019061012d9190611047565b6103b0565b60405161013f91906110a2565b60405180910390f35b6101506104a2565b60405161015d91906110cc565b60405180910390f35b610180600480360381019061017b91906110e7565b6104a8565b60405161018d91906110a2565b60405180910390f35b61019e6106f4565b6040516101ab9190611153565b60405180910390f35b6101bc610718565b6040516101c9919061118a565b60405180910390f35b6101da61073c565b6040516101e79190611153565b60405180910390f35b61020a60048036038101906102059190611047565b610799565b005b610226600480360381019061022191906111a5565b6107a7565b60405161023391906110cc565b60405180910390f35b610256600480360381019061025191906111a5565b6107bf565b60405161026391906110cc565b60405180910390f35b6102746107d7565b6040516102819190610f8c565b60405180910390f35b6102a4600480360381019061029f9190611047565b610865565b005b6102c060048036038101906102bb9190611047565b610873565b6040516102cd91906110a2565b60405180910390f35b6102f060048036038101906102eb919061122a565b610987565b005b61030c600480360381019061030791906112cc565b610c86565b60405161031991906110cc565b60405180910390f35b6000805461032f9061133b565b80601f016020809104026020016040519081016040528092919081815260200182805461035b9061133b565b80156103a85780601f1061037d576101008083540402835291602001916103a8565b820191906000526020600020905b81548152906001019060200180831161038b57829003601f168201915b505050505081565b600081600460003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161049091906110cc565b60405180910390a36001905092915050565b60025481565b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff600460008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054146105e15781600460008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546105d9919061139c565b925050819055505b81600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610630919061139c565b9250508190555081600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040516106e191906110cc565b60405180910390a3600190509392505050565b7f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c981565b7f000000000000000000000000000000000000000000000000000000000000000081565b60007f000000000000000000000000000000000000000000000000000000000000000046146107725761076d610cab565b610794565b7f00000000000000000000000000000000000000000000000000000000000000005b905090565b6107a38282610d53565b5050565b60036020528060005260406000206000915090505481565b60056020528060005260406000206000915090505481565b600180546107e49061133b565b80601f01602080910402602001604051908101604052809291908181526020018280546108109061133b565b801561085d5780601f106108325761010080835404028352916020019161085d565b820191906000526020600020905b81548152906001019060200180831161084057829003601f168201915b505050505081565b61086f8282610e23565b5050565b600081600360003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546108c4919061139c565b9250508190555081600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8460405161097591906110cc565b60405180910390a36001905092915050565b428410156109ca576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109c19061141c565b60405180910390fd5b60006109d461073c565b7f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9898989600560008e73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000815480929190600101919050558a604051602001610a5c9695949392919061144b565b60405160208183030381529060405280519060200120604051602001610a83929190611524565b604051602081830303815290604052805190602001209050600060018286868660405160008152602001604052604051610ac0949392919061155b565b6020604051602081039080840390855afa158015610ae2573d6000803e3d6000fd5b505050602060405103519050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1614158015610b5657508873ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16145b610b95576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b8c906115ec565b60405180910390fd5b86600460008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555050508573ffffffffffffffffffffffffffffffffffffffff168773ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92587604051610c7591906110cc565b60405180910390a350505050505050565b6004602052816000526040600020602052806000526040600020600091509150505481565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f6000604051610cdd91906116ab565b60405180910390206040518060400160405280600181526020017f3100000000000000000000000000000000000000000000000000000000000000815250805190602001204630604051602001610d389594939291906116c2565b60405160208183030381529060405280519060200120905090565b8060026000828254610d659190611715565b9250508190555080600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508173ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610e1791906110cc565b60405180910390a35050565b80600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610e72919061139c565b9250508190555080600260008282540392505081905550600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610ee791906110cc565b60405180910390a35050565b600081519050919050565b600082825260208201905092915050565b60005b83811015610f2d578082015181840152602081019050610f12565b83811115610f3c576000848401525b50505050565b6000601f19601f8301169050919050565b6000610f5e82610ef3565b610f688185610efe565b9350610f78818560208601610f0f565b610f8181610f42565b840191505092915050565b60006020820190508181036000830152610fa68184610f53565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610fde82610fb3565b9050919050565b610fee81610fd3565b8114610ff957600080fd5b50565b60008135905061100b81610fe5565b92915050565b6000819050919050565b61102481611011565b811461102f57600080fd5b50565b6000813590506110418161101b565b92915050565b6000806040838503121561105e5761105d610fae565b5b600061106c85828601610ffc565b925050602061107d85828601611032565b9150509250929050565b60008115159050919050565b61109c81611087565b82525050565b60006020820190506110b76000830184611093565b92915050565b6110c681611011565b82525050565b60006020820190506110e160008301846110bd565b92915050565b600080600060608486031215611100576110ff610fae565b5b600061110e86828701610ffc565b935050602061111f86828701610ffc565b925050604061113086828701611032565b9150509250925092565b6000819050919050565b61114d8161113a565b82525050565b60006020820190506111686000830184611144565b92915050565b600060ff82169050919050565b6111848161116e565b82525050565b600060208201905061119f600083018461117b565b92915050565b6000602082840312156111bb576111ba610fae565b5b60006111c984828501610ffc565b91505092915050565b6111db8161116e565b81146111e657600080fd5b50565b6000813590506111f8816111d2565b92915050565b6112078161113a565b811461121257600080fd5b50565b600081359050611224816111fe565b92915050565b600080600080600080600060e0888a03121561124957611248610fae565b5b60006112578a828b01610ffc565b97505060206112688a828b01610ffc565b96505060406112798a828b01611032565b955050606061128a8a828b01611032565b945050608061129b8a828b016111e9565b93505060a06112ac8a828b01611215565b92505060c06112bd8a828b01611215565b91505092959891949750929550565b600080604083850312156112e3576112e2610fae565b5b60006112f185828601610ffc565b925050602061130285828601610ffc565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061135357607f821691505b602082108114156113675761136661130c565b5b50919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006113a782611011565b91506113b283611011565b9250828210156113c5576113c461136d565b5b828203905092915050565b7f5045524d49545f444541444c494e455f45585049524544000000000000000000600082015250565b6000611406601783610efe565b9150611411826113d0565b602082019050919050565b60006020820190508181036000830152611435816113f9565b9050919050565b61144581610fd3565b82525050565b600060c0820190506114606000830189611144565b61146d602083018861143c565b61147a604083018761143c565b61148760608301866110bd565b61149460808301856110bd565b6114a160a08301846110bd565b979650505050505050565b600081905092915050565b7f1901000000000000000000000000000000000000000000000000000000000000600082015250565b60006114ed6002836114ac565b91506114f8826114b7565b600282019050919050565b6000819050919050565b61151e6115198261113a565b611503565b82525050565b600061152f826114e0565b915061153b828561150d565b60208201915061154b828461150d565b6020820191508190509392505050565b60006080820190506115706000830187611144565b61157d602083018661117b565b61158a6040830185611144565b6115976060830184611144565b95945050505050565b7f494e56414c49445f5045524d49545f5349474e41545552450000000000000000600082015250565b60006115d6601883610efe565b91506115e1826115a0565b602082019050919050565b60006020820190508181036000830152611605816115c9565b9050919050565b600081905092915050565b60008190508160005260206000209050919050565b600081546116398161133b565b611643818661160c565b9450600182166000811461165e576001811461166f576116a2565b60ff198316865281860193506116a2565b61167885611617565b60005b8381101561169a5781548189015260018201915060208101905061167b565b838801955050505b50505092915050565b60006116b7828461162c565b915081905092915050565b600060a0820190506116d76000830188611144565b6116e46020830187611144565b6116f16040830186611144565b6116fe60608301856110bd565b61170b608083018461143c565b9695505050505050565b600061172082611011565b915061172b83611011565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156117605761175f61136d565b5b82820190509291505056fea26469706673582212200279da3906854fc46f35218949715893df13b4c6b5a93a4f7d8549e9eba5faac64736f6c634300080a0033";

export class USDC__factory extends ContractFactory {
  constructor(
    ...args: [signer: Signer] | ConstructorParameters<typeof ContractFactory>
  ) {
    if (args.length === 1) {
      super(_abi, _bytecode, args[0]);
    } else {
      super(...args);
    }
  }

  deploy(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<USDC> {
    return super.deploy(overrides || {}) as Promise<USDC>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): USDC {
    return super.attach(address) as USDC;
  }
  connect(signer: Signer): USDC__factory {
    return super.connect(signer) as USDC__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): USDCInterface {
    return new utils.Interface(_abi) as USDCInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): USDC {
    return new Contract(address, _abi, signerOrProvider) as USDC;
  }
}
