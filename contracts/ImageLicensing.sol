/**
 *  @author @jmsofarelli
 */
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./CapsulesRegistry.sol";

/**
 *  @title ImageLicensing
 *  This contract is used to license images registered as Capsules in Ethereum blockchain
 */
 contract ImageLicensing {

    address private contractOwner;
    bool private isStopped = false;
    address public registryAddr;
    uint public licensePrice = 100 wei;

    /**
     * @param _registryAddr The address of the Capsules Registry contract
     * The constructor also stores the address that deployed the contract as the contract's owner
     * The owner of the contract can stop the contract in case of emergency
     * Functions that involve payments will not work in emergency mode
     */
    constructor (address _registryAddr)
        public 
    {
        contractOwner = msg.sender;
        registryAddr = _registryAddr;
    }

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

    // Status of the license request
    enum LicenseStatus {
        Pending,    // The license was requested
        Approved,   // The license request was approved by the owner
        Refused,    // The license request was refused by the owner
        Cancelled   // Ths license request was canceled by the licensee
    }
    
    // License request
    struct License {
        bytes32 contentHash;
        address licensee;
        LicenseStatus status;
    }

    // The number of license requests
    uint numLicenses;

    // License requests
    mapping(uint => License) public licenses;
    
    // List of license requests (License IDs) by image owner
    mapping (address => uint[]) public ownerRequests;

    // List of license requests (License IDs) by licensee
    mapping (address => uint[]) public licenseeRequests;

    /**
     * @dev Event emitted when a new license request is created
     * @param contentHash The hash of the image
     * @param owner The owner of the image
     * @param licensee The licensee
     */
    event LicenseRequested(bytes32 contentHash, address owner, address licensee);

    /**
     * @dev Event emitted when a license request is approved
     * @param contentHash The hash of the image
     * @param owner The owner of the image
     * @param licensee The licensee
     */
    event LicenseApproved(bytes32 contentHash, address owner, address licensee);

    /**
     * @dev Event emitted when a license request is refused
     * @param contentHash The hash of the image
     * @param owner The owner of the image
     * @param licensee The licensee
     */
    event LicenseRefused(bytes32 contentHash, address owner, address licensee);

    /**
     * @dev Event emitted when a license request is cancelled
     * @param contentHash The hash of the image
     * @param licensee The licensee
     */
    event LicenseCancelled(bytes32 contentHash, address licensee);

    /**
     * @dev Checks if the caller of the function is the owner of this contract
     */
    modifier isContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    /**
     * @dev Emergency Stop design pattern. The function will not be executed if the contract is stopped
     */
    modifier notInEmergency() {
        require(!isStopped);
        _;
    }

    /**
     * @dev Checks if the caller of the function is the owner of the image
     * @param _contentHash The hash of the image
     */
    modifier isImageOwner(bytes32 _contentHash) {
        CapsulesRegistry registry = CapsulesRegistry(registryAddr);
        address owner = registry.getOwner(_contentHash);
        require(msg.sender == owner, "The user is not the owner of the image");
        _;
    }

    /**
     * @dev Checks if the caller of the function is not the owner of the image
     * @param _contentHash The hash of the image
     */
    modifier isNotImageOwner(bytes32 _contentHash) {
        CapsulesRegistry registry = CapsulesRegistry(registryAddr);
        address owner = registry.getOwner(_contentHash);
        require(msg.sender != owner, "The user is the owner of the image");
        _;
    }

    /**
     * @dev Require that license request already exists
     * @param _contentHash The hash of the image
     * @param _licensee The licensee
     */
    modifier requestExists(bytes32 _contentHash, address _licensee) {
        uint licenseID = getLicenseID(_contentHash, _licensee);
        require(licenseID != 0);
        _;
    }

    /** 
     * @dev Emergency Stop design pattern. Stop the contract in emergency
     */
    function stopContract() 
        public 
        isContractOwner 
    {
        isStopped = true;
    }

    /** 
     * @dev Emergency Stop design pattern. Reactive functions related to payments
     */
    function resumeContract()
        public
        isContractOwner 
    {
        isStopped = false;
    }

    /**
     * @dev Get list of licensable images
     * @return A list of Capsule objects representing licensable images
     * @return The count of returned images
     * TODO: implement pagination mechanism
     */
    function getLicensableImages()
        public
        view
        returns (Capsule[100] memory images, uint count)
    {
        count = 0;
        CapsulesRegistry registry = CapsulesRegistry(registryAddr);
        uint numImages = registry.numCapsules();
        for (uint capsuleID = 1; capsuleID <= numImages; capsuleID++) {
            (bytes32 ipfsDigest, uint8 hashFunction, uint8 hashSize, address owner) = registry.capsules(capsuleID);
            
            // Filter user's own images
            if (msg.sender != owner) {
                images[count] = Capsule(ipfsDigest, hashFunction, hashSize, owner);
                count++;
            }
        }
        return (images, count);
    }

    /**
      * @dev Requests license to use the image
      * The licensee should send the amount of wei equivalent to the license price
      * @param _contentHash The hash of the image
      */
    function requestLicense(bytes32 _contentHash)
        public
        payable
        notInEmergency
        isNotImageOwner(_contentHash)
    {
        uint licenseID = getLicenseID(_contentHash, msg.sender);
        bool isNew = licenseID == 0;
        require(isNew || licenses[licenseID].status == LicenseStatus.Cancelled, "There is already a license request for this image!");

        // Ensure that the licensee has sent license price
        require(msg.value == licensePrice);
        
        // Get image owner
        CapsulesRegistry registry = CapsulesRegistry(registryAddr);
        address owner = registry.getOwner(_contentHash);

        // It it's a new request, generate a new ID
        if (isNew){
            numLicenses++;
            licenseID = numLicenses;

            // Add the ID of the license request to the ownerRequests mapping
            ownerRequests[owner].push(licenseID);
        
            // Add the OD of the license request to the licenseeRequests mapping
            licenseeRequests[msg.sender].push(licenseID);
        }
        
        // Add the new license request
        licenses[licenseID] = License({
            contentHash: _contentHash,
            licensee: msg.sender,
            status: LicenseStatus.Pending
        });

        // Emit event
        emit LicenseRequested(_contentHash, owner, msg.sender);
    }

    /**  
     * @dev Approves a license request
     * @param _contentHash The hash of the image
     * @param _licensee The licensee
     */ 
    function approveLicenseRequest(bytes32 _contentHash, address _licensee)
        public
        payable
        notInEmergency
        isImageOwner(_contentHash)
        requestExists(_contentHash, _licensee)
    {
        uint licenseID = getLicenseID(_contentHash, _licensee);
        require(licenses[licenseID].status == LicenseStatus.Pending);
        licenses[licenseID].status = LicenseStatus.Approved;
        emit LicenseApproved(_contentHash, msg.sender, _licensee);
        (bool success,) = msg.sender.call.value(licensePrice)("");
        require (success, "The payment of the license to the image owner failed"); 
    }

    /**
     * @dev Refuses a license request and refund the licensee
     * @param _contentHash The hash of the image
     * @param _licensee The licensee
     */
    function refuseLicenseRequest(bytes32 _contentHash, address _licensee)
        public
        payable
        notInEmergency
        isImageOwner(_contentHash)
        requestExists(_contentHash, _licensee)
    {
        uint licenseID = getLicenseID(_contentHash, _licensee);
        require(licenses[licenseID].status == LicenseStatus.Pending);
        licenses[licenseID].status = LicenseStatus.Refused;
        emit LicenseRefused(_contentHash, msg.sender, _licensee);
        (bool success,) = _licensee.call.value(licensePrice)("");
        require (success, "The refund to the licensee failed!");
    }

    /**
     * @dev Cancels a license request and refund the licensee
     * @param _contentHash The hash of the image
     */
    function cancelLicenseRequest(bytes32 _contentHash)
        public
        payable
        notInEmergency
        requestExists(_contentHash, msg.sender)
    {
        uint licenseID = getLicenseID(_contentHash, msg.sender);
        require(licenses[licenseID].status == LicenseStatus.Pending);
        licenses[licenseID].status = LicenseStatus.Cancelled;
        emit LicenseCancelled(_contentHash, msg.sender);
        (bool success,) = msg.sender.call.value(licensePrice)("");
        require(success, "The refund of the licensee failed!");
    }

    /**
     * @dev Return the license requests done to the user
     * @return The list of license requests
     */
    function getIncomingRequests() 
        public
        view
        returns (License[10] memory incomingRequests, uint count)
    {
        uint[] memory licenseIDs = ownerRequests[msg.sender];
        count = licenseIDs.length;

        for (uint i = 0; i < count; i++) {
            uint licenseID = licenseIDs[i];
            incomingRequests[i] = licenses[licenseID];
        }
    }

    /**
     * @dev Return the license requests done by the user
     * @return The list of license requests 
     */
    function getOutGoingRequests() 
        public 
        view
        returns (License[10] memory outgoingRequests, uint count)
    {
        uint[] memory licenseIDs = licenseeRequests[msg.sender];
        count = licenseIDs.length;

        for (uint i = 0; i < count; i++) {
            uint licenseID = licenseIDs[i];
            outgoingRequests[i] = licenses[licenseID];
        }
    }

    /**
     * @dev Returns the ID of the license request if it exists or 0 if it does not exist
     * @param _contentHash The image hash
     * @param _licensee The licensee
     * @return The ID of the license request
     */
    function getLicenseID(bytes32 _contentHash, address _licensee) 
        internal
        view
        returns (uint)
    {
        uint[] memory licenseIDs = licenseeRequests[_licensee];
        for (uint i = 0; i < licenseIDs.length; i++) {
            uint licenseID = licenseIDs[i];
            License memory license = licenses[licenseID];
            if (license.contentHash == _contentHash)
                return licenseID;
        }
        return 0;
    }

}