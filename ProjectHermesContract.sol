pragma solidity ^0.4.8;

contract ProjectHermes {	

	uint minValue;
	uint globalPool;

	struct MessageInfo {
		bool exists;
		address sender;
		bytes32 publicHash;
		bytes32 privateHash;
		address[] messageCarrierWallets; //Something like a set instead of array would be more ideal, but we can work with this.
	}

	//Map message ID to MessageInfo
	mapping(string => MessageInfo) messages;

	//Event to help test when a a message is created but not enough money is sent
	event NotEnoughMessageValue(uint _valueSent, uint _minValue);

	//Event to help test when a message has been created/updated
	event MessageUpdated(string _msgId, bytes32 _publicHash, bytes32 _privateHash, address[] _msgCarrierWallets);

	//Event to help test when the global money pool has been updated
	event GlobalPoolUpdated(uint _amount);

	//Event to help test when a hash value has been generated
	event HashGenerated(bytes32 _actualHash, bytes32 _expectedHash);

	function ProjectHermes() {
		minValue = 10000000000000000; //equivalent to 0.01 ether
		globalPool = 0;
	}

	//This is meant to be called when someone creates a new message that they are sending.
	//The sender must provide a minimum amount of Ether, which will be stored by the contract
	//and distributed to a random user who helps carry the message to its destination.
	function newMessage(string _msgId, bytes32 _hashFromPubNonce, bytes32 _hasFromPrivNonce) payable {

		//We don't want malicious users trying to overwrite a message that already exists
		if(messages[_msgId].exists) {
			throw;
		}

		if(msg.value < minValue) {
			NotEnoughMessageValue(msg.value, minValue);
			throw;
		}

		messages[_msgId] = MessageInfo(true, msg.sender, _hashFromPubNonce, _hasFromPrivNonce, new address[](0));
		MessageInfo message = messages[_msgId];
		MessageUpdated(_msgId, message.publicHash, message.privateHash, message.messageCarrierWallets);

		globalPool += msg.value;
		GlobalPoolUpdated(globalPool);
	}

	//This is meant to be called when an intermediate devices receives a message
	//so that the owner of that device has the potential to be awarded money for
	//helping to deliver that message to the intended recipient
	function addHop(string _msgId, string _publicNonce) {

		MessageInfo message = messages[_msgId];

		//We don't want to try to add message carriers to a message that doesn't exist
		//and we don't want to allow message senders to add themselves as carriers
		if(!message.exists || message.sender == msg.sender) {
			throw;
		}

		if(verifyPublicHash(_msgId, _publicNonce)) {
			addMessageCarrier(_msgId);
		}
	}

	//This is meant to be called by the intended recipient of a message.
	//This will automatically add the receiver's wallet to the list of message
	//carrier wallets in order to provide incentive for the receiver to declare
	//that a message was received. The money from the global pool will automatically
	//be distributed to one of the devices that helped carry the message (which includes the recipient)
	function receiveMessage(string _msgId, string _privateNonce) {

		MessageInfo message = messages[_msgId];

		//We don't want to try to receive a message that doesn't exist
		//and we don't want to allow message senders to receive their own message
		if(!message.exists || message.sender == msg.sender) {
			throw;
		}

		bytes32 hash = sha256(_msgId, _privateNonce);
		HashGenerated(hash, message.privateHash);

		if(verifyPrivateHash(_msgId, _privateNonce)) {
			addMessageCarrier(_msgId);

			address[] wallets = message.messageCarrierWallets;

			//Not sure if basing it off the hash is completely secure, but it's the
			//easiest thing I can get working for a demo
			uint randomIndex = uint(hash) % wallets.length;

			//TODO: We probably don't want to send the entire pool of money to a single person but rather a percentage of that money
			bool success = wallets[randomIndex].send(globalPool);	
			if(success) {
				globalPool = 0;
				delete messages[_msgId];
			}
		}

		GlobalPoolUpdated(globalPool);
		MessageUpdated(_msgId, message.publicHash, message.privateHash, message.messageCarrierWallets);
	}

	//The hashed message ID concatenated with the public nonce should be the same as the 
	//public hash stored for the message with the given ID. The public nonce
	//is intended to be transmitted in clear text along with the message, so
	//anyone who helps carry a message would be able to compute the public hash.
	function verifyPublicHash(string _msgId, string _publicNonce) private returns (bool) {
		MessageInfo message = messages[_msgId];
		bytes32 hash = sha256(_msgId, _publicNonce);
		HashGenerated(hash, message.publicHash);
		return message.publicHash == hash;
	}
	//The hashed message ID concatenated with the private nonce should be the same as the
	//private hash stored for the message with the given ID. The private nonce
	//is intended to be transmitted under encryption along with the message,
	//so only the recipient of the message would be able to compute the private hash
	function verifyPrivateHash(string _msgId, string _privateNonce) private returns (bool) {
		MessageInfo message = messages[_msgId];
		bytes32 hash = sha256(_msgId, _privateNonce);
		HashGenerated(hash, message.privateHash);
		return message.privateHash == hash;
	}

	//Adds a user's wallet to the list of wallets corresponding to the
	//users who helped carry a message.
	function addMessageCarrier(string _msgId) private {
		MessageInfo message = messages[_msgId];
		address[] wallets = message.messageCarrierWallets;
		bool arrayContainsSender = false;
		for(uint i = 0; i < wallets.length; i++) {
			if(wallets[i] == msg.sender) {
				arrayContainsSender = true;
				break;
			}
		}

		if(!arrayContainsSender) {
			wallets.push(msg.sender);
		}

		MessageUpdated(_msgId, message.publicHash, message.privateHash, message.messageCarrierWallets);
	}
}