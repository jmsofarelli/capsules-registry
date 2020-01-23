/**
 *  @authors: [@jmsofarelli]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity ^0.5.0;

/**
 *  @title CapsulesRegistry
 *  This contract is used to register a Capsule in the Ethereum blockchain
 */
contract CapsulesRegistry {

    /*
     * This struct represents a Capsule stored in IPFS
     * An IPFS address is a multihash, calculated using the hash function, hash size and digest
     */
    struct Capsule {
        bytes32 ipfsDigest;
        uint8 hashFunction;
        uint8 hashSize;
        address owner;
    }

    // Maps a content hash (calculated using keccak256 algorithm) to a Capsule stored in IPFS
    mapping (bytes32 => Capsule) public capsules;

    /*
     * When there is a new version of the content, a new content hash is generated
     * This mapping is used to link the hash of the old version to the hash of the new version
     */
    mapping (bytes32 => bytes32) public versions;

    /**
     * @dev Event emitted when a new Capsule is registered
     * @param _contentHash The hash of the content, calculated using keccak256 algorithm
     * @param _owner The address that registered the Capsule
     */
    event CapsuleRegistered(bytes32 _contentHash, address _owner);

    /**
     * @dev Event emitted when a new version of a content is registered
     * @param _oldContentHash The hash of the old version
     * @param _newContentHash The hash of the new version 
     * @param _owner The address that registered the new version
     */
    event VersionUpdated(bytes32 _oldContentHash, bytes32 _newContentHash, address _owner);

    /**
      * @dev Registers a Capsule
      * @param _contentHash The hash of the content, calculated using keccak256 algorithm
      * @param _ipfsDigest The IPFS hash of Capsule stored in IPFS
      * @param _hashFunction The hash function used by IPFS
      * @param _hashSize The hash size
      */
    function registerCapsule(bytes32 _contentHash, bytes32 _ipfsDigest, uint8 _hashFunction, uint8 _hashSize)
        public
    {
        require(capsules[_contentHash].owner == address(0), 'The Capsule is already registered!');
        capsules[_contentHash] = Capsule({
            ipfsDigest: _ipfsDigest,
            hashFunction: _hashFunction,
            hashSize: _hashSize,
            owner: msg.sender
        });
        emit CapsuleRegistered(_contentHash, msg.sender);
    }

    /**  
     * @dev Registers a new version of a content
     * NOTE: This function only links the old version of the content to the new version, using their hashes
     * NOTE: This function DOES NOT register the content Capsule. For this purpose, the function registerCapsule should be used
     * @param _oldContentHash The hash of the old version 
     * @param _newContentHash The hash of the new version
     */ 
    function updateVersion (bytes32 _oldContentHash, bytes32 _newContentHash)
        public
    {
        require(capsules[_oldContentHash].owner != address(0), 'The content should have a registered Capsule associated with it!');
        require(capsules[_oldContentHash].owner == msg.sender, 'Only the owner of the content can register a new version of it!');
        require(versions[_oldContentHash] == "", 'There is already a new version of the content registered');
        versions[_oldContentHash] = _newContentHash;
        emit VersionUpdated(_oldContentHash, _newContentHash, msg.sender);
    }

}