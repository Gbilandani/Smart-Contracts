// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Iescrowcontract {

    function PlaceOrder(address _nftaddress, address seller,uint256 tokenid,  uint256 copies, uint256 priceperNFT) external;

    
}