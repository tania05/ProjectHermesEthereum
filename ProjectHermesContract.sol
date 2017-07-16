pragma solidity ^0.4.8;

contract ProjectHermes {

	uint minPrice; //TODO: Pick a good amount. Amount is measured in wei
	uint globalPool;

	struct MessageInfo {
		bytes32 publicHash;
		bytes32 privateHash;
		address[] messageCarrierWallets; //Something like a set instead of array would be more ideal, but we can work with this.
	}

	//Map message ID to MessageInfo
	mapping(string => MessageInfo) messages;

	//TODO: I can get rid of these if I want. They are there to help with debugging
	event MessageUpdated(string _msgId, uint _numWallets, bytes32 _hash);
	event PoolUpdated(uint _amount);
	event HashInfo(string _msgId, string _publicNonce);
	event MoneyTransfer(bool _success);

	function ProjectHermes() {
		minPrice = 1;
		globalPool = 0;
	}


	function newMessage(string _msgId, bytes32 _hashFromPubNonce, bytes32 _hasFromPrivNonce) payable {
		if(msg.value < minPrice) {
			throw;
		}

		messages[_msgId] = MessageInfo(_hashFromPubNonce, _hasFromPrivNonce, new address[](0));
		MessageUpdated(_msgId, messages[_msgId].messageCarrierWallets.length, _hashFromPubNonce);
		globalPool += msg.value;
		PoolUpdated(globalPool);
	}

	//This is meant to be called when an intermediate devices receives a message
	//so that the owner of that device has the potential to be awarded money for
	//helping to deliver that message to the intended recipient
	function addHop(string _msgId, string _publicNonce) {
		bytes32 hash = sha256(_msgId, _publicNonce);
		HashInfo(_msgId, _publicNonce);

		//The message does not exist
		//TODO: Is there a more correct way of checkng if message exists?
		if(messages[_msgId].publicHash == 0) {
			throw;
		}

		if(messages[_msgId].publicHash == hash) {
			address[] wallets = messages[_msgId].messageCarrierWallets;
			bool arrayContainsSender = false;
			for(uint i = 0; i < wallets.length; i++) {
				if(wallets[i] == msg.sender) {
					arrayContainsSender = true;
					break;
				}
			}

			if(!arrayContainsSender) {
				messages[_msgId].messageCarrierWallets.push(msg.sender);
			}
		}

		MessageUpdated(_msgId, messages[_msgId].messageCarrierWallets.length, hash);
	}

	function receiveMessage(string _msgId, string _privateNonce) {
		bytes32 hash = sha256(_msgId, _privateNonce);

		//TODO: Check if message exists
		if(messages[_msgId].publicHash == 0) {
			throw;
		}

		if(messages[_msgId].privateHash == hash) {
			address[] wallets = messages[_msgId].messageCarrierWallets;

			//Pick a random number between 0 (inclusive) and wallets.length (exclusive)
			//Not sure if basing it off the hash is completely secure, but it's the
			//easiest thing I can get working for a demo
			uint randomIndex = uint(hash) % wallets.length;

			//Does this actually work? Seems to fail if I try to send more than what is in global pool, which is good
			bool success = wallets[randomIndex].send(globalPool);	
			if(success) {
				globalPool = 0;
				delete messages[_msgId];
				PoolUpdated(globalPool);
			}

			MoneyTransfer(success);
		}
	}

	//TODO: This can be removed. It is there to help with debugging
	function testNumberOfWallets(string _msgId) constant returns (uint) {
		return messages[_msgId].messageCarrierWallets.length;
	}
	
}