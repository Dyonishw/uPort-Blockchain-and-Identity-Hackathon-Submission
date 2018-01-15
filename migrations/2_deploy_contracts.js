var CadasterAndNotary = artifacts.require("./CadasterAndNotary.sol");

module.exports = function(deployer) {
  deployer.deploy(CadasterAndNotary);

};

