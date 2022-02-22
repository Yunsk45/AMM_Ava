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


   function provide(uint256 _amountToken1, uint256 _amountToken2) external 
                                                                  validAmountCheck(token1Balance, _amountToken1)
                                                                  validAmountCheck(token2Balance, _amountToken2) 
                                                                  returns (uint256 share)
                                                                  {

      if(totalShares == 0) {
         share = 100*PRECISION;
      }
      else {
         uint256 share1 = totalShares.mul(_amountToken1).div(totalToken1);
         uint256 share2 = totalShares.mul(_amountToken2).div(totalToken2);
         require(share1 == share2, "Equivalent value of tokens not provided !");
         share = share1;
      }
      require(share > 0, "Asset value less than thresold contrib");
      token1Balance[msg.sender] -= amountToken1;
      token2Balance[msg.sender] -= amountToken2; // preventing reentrancy attack by updating balances first.

      totalToken1 += _amountToken1;
      totalToken2 += _amountToken2;
      K = totalToken1.mul(totalToken2); 

      totalShares += share;
      shares[msg.sender] += share;
   }


   function getEquivalentToken1Estimate(uint256 _amountToken2) public view activePool returns(uint256 reqToken1) {
      reqToken1 = totalToken1.mul(_amountToken2).div(totalToken2);
   }
   function getEquivalentToken2Estimate(uint256 _amountToken1) public view activePool returns(uint256 reqToken2) {
      reqToken2 = totalToken2.mul(_amountToken1).div(totalToken1);
   }
   
   function getWithdrawEstimate(uint256 _share) public biew activePool returns(uint256 amountToken1, uint256 amountToken2) {
      require(_share <= totalShares, "Share should be less than totalShare");
      amountToken1 = _share.mul(totalToken1).div(totalShares);
      amountToken2 = _share.mul(totalToken2).div(totalShares);
   }

   function withdraw(uint256 _share) external activepool validAmountCheck(shares, _share) 
                                     returns(uint256 amountToken1, uint256 amountToken2) {
      
      (amountToken1, amountToken2) = getWithdrawEstimate(_share);

      shares[msg.sender] -= _share;
      totalShares -= _share;

      totalToken1 -= amountToken1;
      totalToken2 -= amountToken2;
      K = totalToken1.mul(totalToken2);

      token1Balance[msg.sender] += amountToken1;
      token2Balance[msg.sender] += amountToken2;


   }



   //Swapping functions
  function getSwapToken1Estimate(uint256 _amountToken1) public view activePool returns(uint256 amountToken2) {
    uint256 token1After = totalToken1.add(_amountToken1);
    uint256 token2After = K.div(token1After);
    amountToken2 = totalToken2.sub(token2After);

    // To ensure that Token2's pool is not completely depleted leading to inf:0 ratio
    if(amountToken2 == totalToken2) amountToken2--;
  } 

  function getSwapToken1EstimateGivenToken2(uint256 _amountToken2) public view actovePool
                                                                   returns(uint256 amountToken1) {
      require(_amountToken2 < totalToken2, "Insufficient bool balance");
      uint256 token2after = totalToken2.sub(_amountToken2);
      uint256 token1After = K.div(token2after);
      _amountToken1 = token1After.sub(totalToken1);
   }


   function swapToken1(uint256 _amountToken1) public external 
                                              activePool validAmountCheck(token1Balance, _amountToken1) 
                                              returns(uint256 amountToken2) {
      amountToken2 = getSwapToken1Estimate(_amountToken1);

      token1Balance[msg.sender] -= _amountToken1;

      totalToken1 += _amountToken1;
      totalToken2 -= amountToken2;

      token2Balance[msg.sender] += amountToken2;

   }
}
