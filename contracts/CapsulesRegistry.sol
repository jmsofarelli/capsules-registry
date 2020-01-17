pragma solidity ^0.5.0;

contract CapsulesRegistry {

    struct Capsule {
        bytes32 ipfsHash;
        uint8 hashFunction;
        uint8 size;
        address owner;
    }

    mapping (bytes32 => Capsule) public capsules;
    mapping (bytes32 => bytes32) public versions;

    function registerCapsule(bytes32 _contentHash, bytes32 _ipfsHash, uint8 _hashFunction, uint8 _size)
        public
    {
        require(capsules[_contentHash].owner == address(0), 'The Capsule is already registered!');
        capsules[_contentHash] = Capsule({
            ipfsHash: _ipfsHash,
            hashFunction: _hashFunction,
            size: _size,
            owner: msg.sender
        });
    }

    function updateVersion (bytes32 oldContentHash, bytes32 newContentHash)
        public
    {
        require(capsules[oldContentHash].owner != address(0), 'The Capsule is not registered yet!');
        require(capsules[oldContentHash].owner == msg.sender, 'Only the owner of the Capsule can update it!');
        require(versions[oldContentHash] == "", 'There is already a new version of the content registered');
        versions[oldContentHash] = newContentHash;
    }

}