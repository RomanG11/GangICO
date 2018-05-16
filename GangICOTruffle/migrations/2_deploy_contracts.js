var Token = artifacts.require("./GangToken.sol");
var Crowdsale = artifacts.require("./GangTokenSale.sol");
var Multisig = artifacts.require("./GangMultisig.sol")

module.exports = function(deployer) {
  deployer.deploy(Token).then(function(){
  	deployer.deploy(Crowdsale, Token.address, web3.eth.accounts[0], 2).then(function(){
  		return deployer.deploy(Multisig, Token.address, Crowdsale.address, 2, [web3.eth.accounts[0], web3.eth.accounts[1]]);
  	})
  })
};
