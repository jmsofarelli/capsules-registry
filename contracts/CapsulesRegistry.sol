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
     * An IPFS address is a multihash, calculated using the hash function, hash size and IPFS digest
     */
    struct Capsule {
        bytes32 ipfsDigest;
        uint8 hashFunction;
        uint8 hashSize;
        address owner;
    }

    // Number of capsules
    uint public numCapsules;

    // Capsules objects indexed by ID (uint). NOTE: the first valid ID is 1
    mapping (uint => Capsule) public capsules;

    // Maps the content hash (calculated using keccak256 algorithm) to the Capsule ID
    mapping (bytes32 => uint) public capsuleIDsByHash;

    /**
     * @dev Event emitted when a new Capsule is registered
     * @param _contentHash The hash of the content, calculated using keccak256 algorithm
     * @param _owner The address that registered the Capsule
     */
    event CapsuleRegistered(bytes32 _contentHash, address _owner);

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
        // Check if a Capsule already exists for the content hash
        require(capsuleIDsByHash[_contentHash] == 0, 'The Capsule is already registered!');
        
        // Generate an ID for the new Capsule
        numCapsules++;
        uint capsuleID = numCapsules;
        
        // Adds the new Capsule
        capsules[capsuleID] = Capsule({
            ipfsDigest: _ipfsDigest,
            hashFunction: _hashFunction,
            hashSize: _hashSize,
            owner: msg.sender
        });

        // Update mapping between content hash and Capsule ID
        capsuleIDsByHash[_contentHash] = capsuleID;

        // Log registered Capsule
        emit CapsuleRegistered(_contentHash, msg.sender);
    }

    /**
     * @dev Get the owner of the Capsule
     * @param _contentHash The hash of the content
     * @return The address of the owner of the Capsule
     */
    function getOwner(bytes32 _contentHash)
        public
        view
        returns (address)
    {
        return capsules[capsuleIDsByHash[_contentHash]].owner;
    }
    
    /** 
     * @dev Get the Capsule associated with the content hash
     * @param _contentHash The hash of the content
     * @return ipfsDigest The IPFS digest
     * @return hashFunction The IPFS hash function 
     * @return hashSize The IPFS hash size
     * @return owner The address of the owner
     */
    function getCapsule(bytes32 _contentHash)
        public
        view
        returns (bytes32 ipfsDigest, uint8 hashFunction, uint8 hashSize, address owner)
    {
        Capsule storage capsule = capsules[capsuleIDsByHash[_contentHash]];
        return (capsule.ipfsDigest, capsule.hashFunction, capsule.hashSize, capsule.owner);
    }
    
}