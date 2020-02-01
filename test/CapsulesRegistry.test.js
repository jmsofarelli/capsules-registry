var CapsulesRegistry = artifacts.require('CapsulesRegistry');
let catchRevert = require("./exceptionsHelpers.js").catchRevert;
let capsule1 = require("./data").capsule1;

contract('CapsulesRegistry', (accounts) => {

    const emptyHash = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const emptyAddress = "0x0000000000000000000000000000000000000000";
    
    const firstAccount = accounts[0];
    
    let registry;
    
    beforeEach(async () => {
        registry = await CapsulesRegistry.new();
    })

    describe("Functions", () => {
        
        describe("registerCapsule()", async() => {
            it("registering a capsule should emit an event CapsuleRegistered", async() => {
                const tx = await registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: firstAccount});
                const eventData = tx.logs[0].args;
                assert.equal(eventData._contentHash, capsule1.contentHash, "the content hashes should match");
                assert.equal(eventData._owner, firstAccount, "the owners should match");
            })
            it("should not be possible to register two capsules for the same content hash", async() => {
                await registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: firstAccount});
                await catchRevert(registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: firstAccount}));
            })
        })

        describe("getOwner()", async() => {
            it("should return the owner of the capsule", async() => {
                await registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: firstAccount});
                const owner = await registry.getOwner(capsule1.contentHash);
                assert.equal(owner, firstAccount, "the owners should match");
            });
        })

        describe("getCapsule()", async() => {
            it("should return the right capsule data", async() => {
                await registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: firstAccount});
                const capsuleData = await registry.getCapsule(capsule1.contentHash);
                assert.equal(capsuleData['0'], capsule1.ipfsDigest, "the ipfs digest should match");
                assert.equal(capsuleData['1'], capsule1.hashFunction, "the hash function should match");
                assert.equal(capsuleData['2'], capsule1.hashSize, "the hash size should match");
                assert.equal(capsuleData['3'], firstAccount, "the owner should match");
            })
            it("should return an empty capsule if it does not exist", async() => {
                const capsuleData = await registry.getCapsule(capsule1.contentHash);
                assert.equal(capsuleData['0'], emptyHash, "the ipfs digest should match");
                assert.equal(capsuleData['1'], 0, "the hash function should match");
                assert.equal(capsuleData['2'], 0, "the hash size should match");
                assert.equal(capsuleData['3'], emptyAddress, "the owner should match");
            })
        });
    })

});