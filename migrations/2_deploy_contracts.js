const CapsulesRegistry = artifacts.require("CapsulesRegistry");
const ImageLicensing = artifacts.require("ImageLicensing");

module.exports = function(deployer) {
    deployer.deploy(CapsulesRegistry).then(function () {
        return deployer.deploy(ImageLicensing, CapsulesRegistry.address);
    });
}