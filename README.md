I'll include the address of the smart contract once its final version has been deployed. I'll also include the application binary interface (ABI) as well. Both of these will be necessary in order for the mobile devices to interact with the smart contract. Since the smart contract is still under development, these are still subject to change regularly, so I'm not including them for now.

## Contract Address

You will need to know the address where the of the smart contract before you can interact with it. The contract is stored on the Rinkeby network at the following address `TODO`

## Application Binary Interface (ABI)

You will be required to specify the ABI before you can interact with the smart contract. The ABI is stored in JSON format below:

```
TODO
```

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
