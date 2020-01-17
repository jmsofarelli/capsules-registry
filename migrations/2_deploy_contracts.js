const CapsulesRegistry = artifacts.require("CapsulesRegistry");

module.exports = function(deployer) {
    deployer.deploy(CapsulesRegistry);
}