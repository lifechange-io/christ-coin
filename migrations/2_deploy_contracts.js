var ChristCoin = artifacts.require("./ChristCoin.sol");
var Controller = artifacts.require("./Controller.sol");
var Ledger = artifacts.require("./Ledger.sol");
var Crowdsale = artifacts.require("./Crowdsale.sol");

module.exports = function(deployer) {
  var crowdsale;

  deployer
    .deploy([
      Ledger,
      ChristCoin,
      Crowdsale
    ])
    .then(() =>
      deployer.deploy(Controller, ChristCoin.address, Ledger.address, Crowdsale.address)
    )
    .then(() => Promise.all([
      Ledger.deployed().then(l => l.setController(Controller.address)),
      ChristCoin.deployed().then(t => t.setController(Controller.address)),
      Crowdsale.deployed().then(cs => { 
        crowdsale = cs;
        return cs.setController(Controller.address) 
      })
    ]))
    .then(() => Controller.deployed().then(c => c.init()));
};