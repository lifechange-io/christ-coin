pragma solidity ^0.4.11;

import "./Zeppelin/SafeMath.sol";
import "./Controller.sol";
import "./Shared.sol";

contract Crowdsale is Shared {
  using SafeMath for uint;

  uint public constant START = 1475391600;                          // October 2, 2016 7:00:00 AM GMT
  uint public constant END = 1511766000;                            // November 27, 2017 7:00:00 AM GMT
  uint public constant CAP = 450 * (10 ** (6 + DECIMALS));          // 450 million tokens
  
  uint public weiRaised;
  uint public tokensDistributed;
  uint public bonusTokensDistributed;
  uint public presaleTokensDistributed;
  uint public presaleBonusTokensDistributed;
  bool public crowdsaleFinalized;
  bool public presaleFunded;

  Controller public controller;
  Presale[] presales;
  Round[] public rounds;
  Round public currentRound;

  struct Presale {
    address purchaser;
    uint weiAmount;
  }

  struct Round {
    uint index;
    uint endAmount;
    uint rate;
    uint incentiveDivisor;
  }

  struct Purchase {
    uint tokens;
    uint bonus;
  }

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

  function Crowdsale() {
    require(END >= START);

    rounds.push(Round(0, 75 * (10 ** (6 + DECIMALS)), 33333333333333, 4));
    rounds.push(Round(1, 150 * (10 ** (6 + DECIMALS)), 1 * (10 ** 14), 10));
    rounds.push(Round(2, 250 * (10 ** (6 + DECIMALS)), 2 * (10 ** 14), 0));
    rounds.push(Round(3, 450 * (10 ** (6 + DECIMALS)), 3 * (10 ** 14), 0));
    currentRound = rounds[0];
  }

  function setController(address _address) onlyOwner {
    controller = Controller(_address);
  }

  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) payable {
    require(_beneficiary != 0x0);
    require(validPurchase());

    processPurchase(msg.sender, _beneficiary, msg.value);
    LIFE_CHANGE_WALLET.transfer(msg.value);  
  }

  function processPurchase(address _from, address _beneficiary, uint _weiAmount) internal returns (Purchase purchase) {
    purchase = getPurchase(_weiAmount, tokensDistributed);
    require(tokensDistributed.add(purchase.tokens) <= CAP);
    uint _tokensWithBonus = purchase.tokens.add(purchase.bonus);
    bonusTokensDistributed = bonusTokensDistributed.add(purchase.bonus);
    tokensDistributed = tokensDistributed.add(purchase.tokens);
    weiRaised = weiRaised.add(_weiAmount);
    controller.transferWithEvent(CROWDSALE_WALLET, _beneficiary, _tokensWithBonus);
    TokenPurchase(_from, _beneficiary, _weiAmount, _tokensWithBonus);
  }

  function getPurchase(uint _weiAmount, uint _tokensDistributed) internal returns (Purchase purchase) {
    uint _roundTokensRemaining = currentRound.endAmount.sub(_tokensDistributed);
    uint _roundWeiRemaining = _roundTokensRemaining.mul(currentRound.rate).div(10 ** DECIMALS);
    uint _tokens = _weiAmount.div(currentRound.rate).mul(10 ** DECIMALS);
    uint _incentiveDivisor = currentRound.incentiveDivisor;
    
    if (_tokens <= _roundTokensRemaining) {
      purchase.tokens = _tokens;

      if (_incentiveDivisor > 0) {
        purchase.bonus = _tokens.div(_incentiveDivisor);
      }
    } else {
      currentRound = rounds[currentRound.index + 1];

      uint _roundBonus = 0;
      if (_incentiveDivisor > 0) {
        _roundBonus = _roundTokensRemaining.div(_incentiveDivisor);
      }
      
      purchase = getPurchase(_weiAmount.sub(_roundWeiRemaining), _tokensDistributed.add(_roundTokensRemaining));
      purchase.tokens = purchase.tokens.add(_roundTokensRemaining);
      purchase.bonus = purchase.bonus.add(_roundBonus);
    }
  }

  function validPurchase() internal constant returns (bool) {
    bool notAtCap = tokensDistributed < CAP;
    bool nonZeroPurchase = msg.value != 0;
    bool withinPeriod = now >= START && now <= END;

    return notAtCap && nonZeroPurchase && withinPeriod;
  }

  function hasEnded() constant returns (bool) {
    return crowdsaleFinalized || tokensDistributed == CAP || now > END;
  }

  function fundPresale() onlyOwner {
    require(!presaleFunded);

    presales.push(Presale(0xEc8CDf09eF13f48a95ED6E7d260ebfF2a8E6a232, 13 * (10 ** 18)));
    presales.push(Presale(0xdD0BF270a36d0BF41E9f8ECAe08fEe14999a0693, 20 * (10 ** 18)));

    for (uint i = 0; i < presales.length; i++) {
      Purchase memory purchase = processPurchase(0x0, presales[i].purchaser, presales[i].weiAmount);
      presaleTokensDistributed = presaleTokensDistributed.add(purchase.tokens);
      presaleBonusTokensDistributed = presaleBonusTokensDistributed.add(purchase.bonus);
    }

    currentRound = rounds[1];
    presaleFunded = true;
  }

  function finalizeCrowdsale() onlyOwner {
    require(!crowdsaleFinalized);
    require(hasEnded());
    
    uint _toVest = controller.balanceOf(CROWDSALE_WALLET);
    if (tokensDistributed == CAP) {
      _toVest = _toVest.sub(CAP.div(4)); // 25% bonus to token holders if sold out
    }

    controller.transferWithEvent(CROWDSALE_WALLET, LIFE_CHANGE_VESTING_WALLET, _toVest);
    controller.startVesting(_toVest, 7 years);

    crowdsaleFinalized = true;
  }
}