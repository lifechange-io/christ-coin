pragma solidity ^0.4.11;

import "./Zeppelin/SafeMath.sol";
import "./ChristCoin.sol";
import "./Ledger.sol";
import "./Shared.sol";

contract Controller is Shared {
  using SafeMath for uint;

  bool public initialized;

  ChristCoin public token;
  Ledger public ledger;
  address public crowdsale;

  uint public vestingAmount;
  uint public vestingPaid;
  uint public vestingStart;
  uint public vestingDuration;

  function Controller(address _token, address _ledger, address _crowdsale) {
    token = ChristCoin(_token);
    ledger = Ledger(_ledger);
    crowdsale = _crowdsale;
  }

  function setToken(address _address) onlyOwner notFinalized {
    token = ChristCoin(_address);
  }

  function setLedger(address _address) onlyOwner notFinalized {
    ledger = Ledger(_address);
  }

  function setCrowdsale(address _address) onlyOwner notFinalized {
    crowdsale = _address;
  }

  modifier onlyToken() {
    require(msg.sender == address(token));
    _;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

  modifier onlyTokenOrCrowdsale() {
    require(msg.sender == address(token) || msg.sender == crowdsale);
    _;
  }

  modifier notVesting() {
    require(msg.sender != LIFE_CHANGE_VESTING_WALLET);
    _;
  }

  function init() onlyOwner {
    require(!initialized);
    mintWithEvent(REWARDS_WALLET, 9 * (10 ** (9 + DECIMALS))); // 9 billion
    mintWithEvent(CROWDSALE_WALLET, 900 * (10 ** (6 + DECIMALS))); // 375 million
    mintWithEvent(LIFE_CHANGE_WALLET, 100 * (10 ** (6 + DECIMALS))); // 100 million
    initialized = true;
  }

  function totalSupply() onlyToken constant returns (uint) {
    return ledger.totalSupply();
  }

  function balanceOf(address _owner) onlyTokenOrCrowdsale constant returns (uint) {
    return ledger.balanceOf(_owner);
  }

  function allowance(address _owner, address _spender) onlyToken constant returns (uint) {
    return ledger.allowance(_owner, _spender);
  }

  function transfer(address _from, address _to, uint _value) onlyToken notVesting returns (bool success) {
    return ledger.transfer(_from, _to, _value);
  }

  function transferWithEvent(address _from, address _to, uint _value) onlyCrowdsale returns (bool success) {
    success = ledger.transfer(_from, _to, _value);
    if (success) {
      token.controllerTransfer(msg.sender, _to, _value);
    }
  }

  function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken notVesting returns (bool success) {
    return ledger.transferFrom(_spender, _from, _to, _value);
  }

  function approve(address _owner, address _spender, uint _value) onlyToken notVesting returns (bool success) {
    return ledger.approve(_owner, _spender, _value);
  }

  function burn(address _owner, uint _amount) onlyToken returns (bool success) {
    return ledger.burn(_owner, _amount);
  }

  function mintWithEvent(address _to, uint _amount) internal returns (bool success) {
    success = ledger.mint(_to, _amount);
    if (success) {
      token.controllerTransfer(0x0, _to, _amount);
    }
  }

  function startVesting(uint _amount, uint _duration) onlyCrowdsale {
    require(vestingAmount == 0);
    vestingAmount = _amount;
    vestingPaid = 0;
    vestingStart = now;
    vestingDuration = _duration;
  }

  function withdrawVested(address _withdrawTo) returns (uint amountWithdrawn) {
    require(msg.sender == LIFE_CHANGE_VESTING_WALLET);
    require(vestingAmount > 0);
    
    uint _elapsed = now.sub(vestingStart);
    uint _rate = vestingAmount.div(vestingDuration);
    uint _unlocked = _rate.mul(_elapsed);
    amountWithdrawn = _unlocked.sub(vestingPaid);
    vestingPaid = vestingPaid.add(amountWithdrawn);

    ledger.transfer(LIFE_CHANGE_VESTING_WALLET, _withdrawTo, amountWithdrawn);
    token.controllerTransfer(LIFE_CHANGE_VESTING_WALLET, _withdrawTo, amountWithdrawn);
  }
}