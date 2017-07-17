## Contract Address

You will need to know the address where the of the smart contract before you can interact with it. The contract is stored on the Rinkeby network at the following address `0xAc7d48eb7Ca5bcd18a03c3C517EA1238D80D1cf4`

**IMPORTANT:** If the contract is changed and redeployed, the above address will still point to the old version of the contract. We need to remember to update the contract address if we redeploy it.

## Application Binary Interface (ABI)

You will be required to specify the ABI before you can interact with the smart contract. The ABI is stored in JSON format below:

```
[ { "constant": false, "inputs": [ { "name": "_msgId", "type": "string" }, { "name": "_hashFromPubNonce", "type": "bytes32" }, { "name": "_hasFromPrivNonce", "type": "bytes32" } ], "name": "newMessage", "outputs": [], "payable": true, "type": "function" }, { "constant": false, "inputs": [ { "name": "_msgId", "type": "string" }, { "name": "_publicNonce", "type": "string" } ], "name": "addHop", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "_msgId", "type": "string" }, { "name": "_privateNonce", "type": "string" } ], "name": "receiveMessage", "outputs": [], "payable": false, "type": "function" }, { "inputs": [], "payable": false, "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "_valueSent", "type": "uint256" }, { "indexed": false, "name": "_minValue", "type": "uint256" } ], "name": "NotEnoughMessageValue", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "_msgId", "type": "string" }, { "indexed": false, "name": "_publicHash", "type": "bytes32" }, { "indexed": false, "name": "_privateHash", "type": "bytes32" }, { "indexed": false, "name": "_msgCarrierWallets", "type": "address[]" } ], "name": "MessageUpdated", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "_amount", "type": "uint256" } ], "name": "GlobalPoolUpdated", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": false, "name": "_actualHash", "type": "bytes32" }, { "indexed": false, "name": "_expectedHash", "type": "bytes32" } ], "name": "HashGenerated", "type": "event" } ]
```

**IMPORTANT:** If the contract is changed and redeployed, the above ABI *may* become outdated (unless the interface has not changed). We need to remember to check if the ABI needs to be updated if the contract is redeployed.

## Contract Usage

There are 3 functions that are available for use.

### newMessage(string _msgId, bytes32 _hashFromPubNonce, bytes32 _hasFromPrivNonce)

This will be called by the sender of a new message.

The `_msgId` should be a UUID formatted as a string. `_hashFromPubNonce` and `_hashFromPrivNonce` are two 32-byte values that result from computing SHA-256 of `_msgId` concatenated a public and private nonce strings of your choosing.

If a message with the given `_msgId` already exists, this function will fail. This is to prevent malicious use from people other than the message creator whereby they may attempt to overwrite a message. Since it is recommended that UUIDs be used as message IDs, practically speaking this will never result in any user from accidentally creating a new message with the same ID as an existing message.

When calling `newMessage`, you must also send some amount of Ether that is greater than or equal to the minimum amount of Ether set in the smart contract. At the time of writing, this value is equal to `10^16` Ether, but that is subject to change.

### addHop(string _msgId, string _publicNonce)

This will be called by a user that helps carry a message but is not the recipient of the message.

The `_msgId` and `_publicNonce` should be provided in cleartext as part of the message when the sender originally sent it.

The smart contract will compute the SHA-256 hash of the `_msgID` concatenated with the `_publicNonce` and compare with the public hash that it has stored for that message. If they match, then the smart contract will store the user's wallet address to indicate that the user helped carry the message. Upon successful delivery of the message, this user has a chance to receive money.

### receiveMessage(string _msgId, string _privateNonce)

This will be called by a the intended recipient of a message.

The `_msgId` should be provided in cleartext as part of the message when the sender originally sent it. The `_privateNonce` should be encrypted such that only the recipient can decrypt it.

The smart contract will compute the SHA-256 hash of the `_msgID` concatenated with the `_privateNonce` and compare with the private hash that it has stored for that message. If they match, then the smart contract will store the user's wallet to indicate that the user helped carry the message. This is to provide incentive for the recipient to call `receiveMessage`. Additionally, a random user from the list of users who helped carry the message will be selected, and money that is stored in the contract will be sent to that user. The message will be deleted from the smart contract.

## Known Issues

* What happens if the message sender includes a bogus message ID, public nonce, or private nonce when transmitting the message to his/her peers?
    * In this case, users will be unable to call `addHop` and `receiveMessage`.
    * We think this isn't an issue because we can just have the hop devices only redistribute a message if they are successfully able to call addHop
* Since the message ID and public nonce are stored in clear text, what happens if other users tamper with those values before retransmitting the message?
    * We think this isn't an issue because a hopping device doesn't gain any benefit from tampering with the message. If the message ID is tampered with, then the receiver will never be able to call receiveMessage, preventing money from being distributed. If the public nonce is tampered with, then other devices will just stop distributing the message.
* Currently the smart contract sends the entire global pool to a user when `receiveMessage` is called. This should probably be changed to just some percentage of the global pool
