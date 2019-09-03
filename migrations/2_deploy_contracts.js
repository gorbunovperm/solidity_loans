const Loans = artifacts.require("Loans");

module.exports = function(deployer) {
  deployer.deploy(Loans);
};
