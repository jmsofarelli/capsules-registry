const CapsulesRegistry = artifacts.require('CapsulesRegistry');
const ImageLicensing = artifacts.require('ImageLicensing');
const testData = require('./data');
const catchRevert = require("./exceptionsHelpers.js").catchRevert;

contract('ImageLicensing', async (accounts) => {

    const deployAccount = accounts[0];
    const accountA = accounts[1];
    const accountB = accounts[2];
    const accountC = accounts[3];

    const { capsule1, capsule2, capsule3, capsule4, capsule5 } = testData;

    // Deploy the CapsulesRegistry smart contract and register some capsules
    let registry = await CapsulesRegistry.new();
    await registry.registerCapsule(capsule1.contentHash, capsule1.ipfsDigest, capsule1.hashFunction, capsule1.hashSize, {from: accountA});
    await registry.registerCapsule(capsule2.contentHash, capsule2.ipfsDigest, capsule2.hashFunction, capsule2.hashSize, {from: accountA});
    await registry.registerCapsule(capsule3.contentHash, capsule3.ipfsDigest, capsule3.hashFunction, capsule3.hashSize, {from: accountA});
    await registry.registerCapsule(capsule4.contentHash, capsule4.ipfsDigest, capsule4.hashFunction, capsule4.hashSize, {from: accountB});
    await registry.registerCapsule(capsule5.contentHash, capsule5.ipfsDigest, capsule5.hashFunction, capsule5.hashSize, {from: accountB});
    
    let imageLicensing;

    beforeEach(async () => {
        imageLicensing = await ImageLicensing.new(registry.address);
    });

    describe("Setup", async() => {
        // Ensure that the communication between the contracts will work
        describe("constructor", async() => {
            it ("should set the proper address of the CapsulesRegistry contract", async() => {
                const registryAddr = await imageLicensing.registryAddr();
                assert.equal(registryAddr, registry.address, "the address of the registry should match");
            });
        });
    });

    describe("Functions", async() => {
        // This test was written to ensure that Stop in Emergency design pattern is working
        describe("stopContract", async() => {
            it("should be executed only by the contract owner", async() => {
                await catchRevert(imageLicensing.stopContract({ from: accountA }));
            });
        });

        // This test was written to ensure that Stop in Emergency design pattern is working
        describe("resumeContract", async() => {
            it("should be executed only by the contract owner", async() => {
                await catchRevert(imageLicensing.resumeContract({ from: accountA }));
            });
        });

        // The user should not see it's own images to license
        describe("getLicensableImages", async() => {
            // Account C should be able to see all the images because it did not register any capsule
            it("should return the right number of images (account C)", async() => {
                const result = await imageLicensing.getLicensableImages({ from: accountC });
                assert.equal(result.count, 5, "number of returned images should be 5");
            });
            // Account A should be able to see only the 2 images registered by account B
            it ("should return the proper image data (account A)", async() => {
                const result = await imageLicensing.getLicensableImages({ from: accountA })
                const { images } = result;
                assert.equal(result.count, 2, "number of returned images should be 2");
                assert.equal(images[0].ipfsDigest, capsule4.ipfsDigest);
                assert.equal(images[0].hashFunction, capsule4.hashFunction);
                assert.equal(images[0].hashSize, capsule4.hashSize);
                assert.equal(images[1].ipfsDigest, capsule5.ipfsDigest);
                assert.equal(images[1].hashFunction, capsule5.hashFunction);
                assert.equal(images[1].hashSize, capsule5.hashSize);
            });
        });

        describe("requestLicense", async() => {
            // This test was written to check if Stop in Emergency design pattern is working
            it("should not execute if contract is in emergency", async () => {
                await imageLicensing.stopContract({ from: deployAccount });
                await catchRevert(imageLicensing.requestLicense(capsule1.contentHash, { from: accountC, value: 100 }));
            });

            // The LicenseRequested event is the evidence that the license was created
            it("should create a new license and emit an event", async () => {
                const tx = await imageLicensing.requestLicense(capsule1.contentHash, { from: accountC, value: 100 });
                const evt = tx.logs[0]
                assert.equal(evt.event, 'LicenseRequested');
                assert.equal(evt.args.contentHash, capsule1.contentHash, "the content hash should match");
                assert.equal(evt.args.owner, accountA, "the owner should match");
                assert.equal(evt.args.licensee, accountC, "the licensee should be the requester");
            });
        });

        describe("approveLicenseRequest", async() => {
            // The LicenseApproved event is the evidence that the license was approved
            it ("should emit an event on approval", async () => {
                await imageLicensing.requestLicense(capsule1.contentHash, { from: accountC, value: 100 });
                const tx = await imageLicensing.approveLicenseRequest(capsule1.contentHash, accountC, { from: accountA });
                const evt = tx.logs[0];
                assert.equal(evt.event, 'LicenseApproved');
                assert.equal(evt.args.contentHash, capsule1.contentHash, "the content hash should match");
                assert.equal(evt.args.owner, accountA, "the owner should be the sender the sender of the transaction");
                assert.equal(evt.args.licensee, accountC, "the licensee should match");
            });
        });

        describe("refuseLicenseRequest", async() => {
            // The LicenseRefused event is the evidence that the license was refused
            it ("should emit an event on refusal", async () => {
                await imageLicensing.requestLicense(capsule1.contentHash, { from: accountC, value: 100 });
                const tx = await imageLicensing.refuseLicenseRequest(capsule1.contentHash, accountC, { from: accountA });
                const evt = tx.logs[0];
                assert.equal(evt.event, 'LicenseRefused');
                assert.equal(evt.args.contentHash, capsule1.contentHash, "the content hash should match");
                assert.equal(evt.args.owner, accountA, "the owner should be the sender of the transaction");
                assert.equal(evt.args.licensee, accountC, "the licensee should match");
            });
        });

        describe("cancelLicenseRequest", async() => {
            // The LicenseCancelled event is the evidence that the license was cancelled
            it ("should emit an event on cancellation", async () => {
                await imageLicensing.requestLicense(capsule1.contentHash, { from: accountC, value: 100 });
                const tx = await imageLicensing.cancelLicenseRequest(capsule1.contentHash, { from: accountC });
                const evt = tx.logs[0];
                assert.equal(evt.event, 'LicenseCancelled');
                assert.equal(evt.args.contentHash, capsule1.contentHash, "the content hash should match");
                assert.equal(evt.args.licensee, accountC, "the licensee should match");
            });
        });
    });
});