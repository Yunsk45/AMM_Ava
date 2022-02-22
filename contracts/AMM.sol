// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract AMM {
   using SafeMath for uint256;

   uint256 totalShares;
   uint256 totalToken1;
   uint256 totalToken2;
   uint256 K;

   uint256 constant PRECISION = 1_000_000;

   mapping(address => uint256) shares;
   mapping(address => uint256) token1Balance;
   mapping(address => uint256) token2Balance;

   modifier validAmountCheck(mapping(address => uint256) storage _balance, uint256 _quantity) {
      require(_quantity > 0, "Amount cannot be zero !");
      require(_quantity <= _balance[msg.sender], "Insufficient funds.");
      _;
   }
}
