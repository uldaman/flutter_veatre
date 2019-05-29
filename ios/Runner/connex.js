"use strict";

class BadParameter extends Error {
  constructor(msg) {
    super(msg);
    this.name = BadParameter.name;
  }
}

function ensure(b, msg) {
  if (!b) {
    throw new BadParameter(msg);
  }
}

function isDecString(value) {
  return typeof value === 'string' && /^[0-9]+$/.test(value);
}
function isHexString(value) {
  return /^0x[0-9a-f]+$/i.test(value);
}
function isHexBytes(value) {
  return /^0x[0-9a-f]*$/i.test(value) && value.length % 2 === 0;
}
function isAddress(value) {
  return /^0x[0-9a-f]{40}$/i.test(value);
}
function isBytes32(value) {
  return /^0x[0-9a-f]{64}$/i.test(value);
}
function isUint32(value) {
  return value >= 0 && value < Math.pow(2, 32) && Number.isInteger(value);
}


thor = {};

thor.genesis = {
  "beneficiary": "0x0000000000000000000000000000000000000000",
  "gasLimit": 10000000,
  "gasUsed": 0,
  "id": "0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127",
  "number": 0,
  "parentID": "0xffffffff00000000000000000000000000000000000000000000000000000000",
  "receiptsRoot": "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
  "signer": "0x0000000000000000000000000000000000000000",
  "size": 170,
  "stateRoot": "0x4ec3af0acbad1ae467ad569337d2fe8576fe303928d35b8cdd91de47e9ac84bb",
  "timestamp": 1530014400,
  "totalScore": 0,
  "transactions": [],
  "txsRoot": "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0"
};

thor.status = window.connex_thor_status;

thor.ticker = () => {
  let current = thor.status.head.number;
  return new function () {
    this.next = () => {
      return new Promise((resolve) => {
        let fn = () => {
          if (current != thor.status.head.number) {
            current = thor.status.head.number;
            resolve();
          } else {
            setTimeout(fn, 500);
          }
        }
        fn();
      });
    }
  }
}

thor.account = (address) => {
  ensure(isAddress(address), `'addr' expected address type`);
  return new function () {
    this.get = () => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getAccount', address);
    }
    this.getCode = () => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getAccountCode', address);
    }
    this.getStorage = (key) => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getAccountStorage', address, key);
    }
    this.method = (abi) => {
      return new function () {
        let _value = 0;
        let opts = {};
        this.value = (value) => {
          if (typeof value === 'number') {
            ensure(Number.isSafeInteger(value) && value >= 0, `'value' expected non-neg safe integer`);
          }
          else {
            ensure(isHexString(value) || isDecString(value), `'value' expected integer in hex/dec string`);
          }
          _value = value;
          return this;
        }
        this.caller = (caller) => {
          ensure(isAddress(caller), `'caller' expected address type`);
          opts.caller = caller;
          return this;
        }
        this.gas = (gas) => {
          ensure(gas >= 0 && Number.isSafeInteger(gas), `'gas' expected non-neg safe integer`);
          opts.gas = gas;
          return this;
        }
        this.gasPrice = (gp) => {
          ensure(isDecString(gp) || isHexString(gp), `'gasPrice' expected integer in hex/dec string`);
          opts.gasPrice = gp;
          return this;
        }
        this.call = (...args) => {
          return window.flutter_inappbrowser.callHandler('vechain', 'callContract', asClause(...args));
        }
        this.asClause = (...args) => {
          const inputsLen = (coder.definition.inputs || []).length;
          ensure(inputsLen === args.length, `'args' count expected ${inputsLen}`);
          return {
            to: address,
            value: _value.toString(),
            args
          };
        }
      }
    }
    // this.event = () => { }
  }
}

thor.account = (revision) => {
  if (typeof revision === 'string') {
    ensure(isBytes32(revision), `'revision' expected bytes32 in hex string`);
  } else if (typeof revision === 'number') {
    ensure(isUint32(revision), `'revision' expected non-neg 32bit integer`);
  } else if (typeof revision === 'undefined') {
    revision = 'best';
  } else {
    ensure(false, `'revision' has invalid type`);
  }
  return new function () {
    this.get = () => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getBlock', revision);
    }
  }
}

thor.transaction = (id) => {
  ensure(isBytes32(id), `'id' expected bytes32 in hex string`);
  return new function () {
    this.get = () => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getTransaction', id);
    }
    this.getReceipt = () => {
      return window.flutter_inappbrowser.callHandler('vechain', 'getTransactionReceipt', id);
    }
  }
}

window.connex = {};
window.connex.thor = thor;
