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

   modifier activePool() {
      require(totalShares > 0, "Zero Liquidity");
   }


   function getMyHoldings() external view returns(uint256 amountToken1, uint256 amountToken2, uint256 myShare) {
      amountToken1 = token1Balance[msg.sender];
      amountToken2 = token2Balance[msg.sender];
      myShare = shares[msg.sender];
   }

   function getPoolDetails() external view returns(uint256, uint256, uint256) {
      return (totalToken1, totalToken2, totalShares);
   }

   // Mock tokens
   function faucet(uint256 _amountToken1, uint256 _amountToken2) external {
      token1Balance[msg.sender] = token1Balance[msg.sender].add(_amountToken1);
      token2Balance[msg.sender] = token2Balance[msg.sender].add(_amountToken2);
   }
}
