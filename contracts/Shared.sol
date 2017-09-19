pragma solidity ^0.4.11;

import "./Zeppelin/Ownable.sol";
import "./Finalizable.sol";

contract Shared is Ownable, Finalizable {
  uint internal constant DECIMALS = 8;
  
  address internal constant REWARDS_WALLET = 0x0A3Aa122b2Ab355DAc2413b52366db64CA7c0261;
  address internal constant CROWDSALE_WALLET = 0x86d9f2E47Db4309ffcCa5E2EB26155e24BDC749f;
  address internal constant LIFE_CHANGE_WALLET = 0x57337eecA46fc08FAcddB773b7044361334753ee;
  address internal constant LIFE_CHANGE_VESTING_WALLET = 0xAB86E25A362c0681767D2a4630Bffc369a29aC20;
}