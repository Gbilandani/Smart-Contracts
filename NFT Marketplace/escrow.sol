// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Iescrow.sol";
import "./nftassignment.sol";
import "./ERC20Contract.sol";

// interface escrow {

//     function PlaceOrder(uint256 tokenid, address owner, uint256 copies, uint256 priceperNFT, SaleType saletype, uint256 timeline, address paymentToken) external returns(bool);

    
// }
// enum SaleType{AUCTION,INSTANT}

contract escrowcontract is ERC1155Holder, Iescrowcontract {
    using Counters for Counters.Counter;
    address payable admin;
    address tokenaddress;
    Counters.Counter private orderNumber;
    // Counters.Counter private bidNumber;


    struct Order {
        address seller;
        uint256 tokenid;
        uint256 amount;
        uint256 priceperNFT;
        SaleType saletype;
        // IERC20 paymentToken;
        uint256 timeline;
    }

    struct Bid {
        address bidder;
        uint256 bidvalue;
        uint256 timestamp;
    }

    mapping(uint256 => Order) public order;
    mapping (uint256 => Bid) public biding;
    // mapping(uint256 => mapping(address =>  Bid)) public bid;
    mapping(uint256 => uint256) private Copies;

    event OrderPlaced(uint256 OrderNumber, address Owner, uint256 TokenID, uint256 amount, uint256 Pricepernft, SaleType sale, uint256 TimeStamp);
    event BidPlaced(uint256 OrderNumber, address Buyer, uint256 BidAmount, uint256 TimeStamp);
    event OrderBought( uint256 OrderNumber , address Seller, address Buyer, SaleType sale , uint256 Price, uint256 amount , uint256 Time);

    function PlaceOrder(address _nftaddress, address seller,uint256 tokenid,  uint256 copies, uint256 priceperNFT) public {
        orderNumber.increment();        
        uint256 a=orderNumber.current();
        order[a] = Order(
            seller,
            tokenid,
            copies,
            priceperNFT,
            GetSaleType(_nftaddress,tokenid),
            block.timestamp
        );
        Copies[a] += copies;

        // transfer token from owner to contract
        ERC1155(_nftaddress).safeTransferFrom( seller, address(this), tokenid, copies, "" );
        emit OrderPlaced(a,seller,tokenid,copies,priceperNFT,GetSaleType(_nftaddress,tokenid), block.timestamp);
        
    }

        modifier checkbuynow(uint256 o, uint256 c) {
            require(c <= order[o].amount,"Not enough tokens to buy");
            require(order[o].saletype==SaleType.INSTANT,"SaleType is not INSTANT.");
            require(order[o].seller != msg.sender,"You are the seller, You Can't Buy.");
             
            _;
        }

        function BuyNow( address _nftaddress , uint256 ordernumber, uint256 copynumber) public payable checkbuynow(ordernumber, copynumber) {
            

            // transfer token from contract to buyer
            if(GetPayement(_nftaddress))
            {
                require(IERC20(GetPayementToken(_nftaddress)).balanceOf(msg.sender) >= order[ordernumber].priceperNFT * copynumber,"You Don't have enough tokens to Buy.");
                //IERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order.tokenid, _copynumber, "" ); 

                // give allowance to escrow contract from the buyer in ERC20 contract
                // address abcds = address(this);
                // // address qwer = msg.sender;
                // IERC20(GetPayementToken(_nftaddress)).approve(abcds, 100000000000000000);
                // give allowance to escrow contract from the buyer in ERC20 contract
                //IERC20(GetPayementToken(msg.sender)).approve(address(this), 100000000000000000);   
                IERC20(GetPayementToken(_nftaddress)).transferFrom(msg.sender,order[ordernumber].seller,(order[ordernumber].priceperNFT * copynumber));

            }
            else
            {
            require( msg.value == (order[ordernumber].priceperNFT * copynumber),"Enter Correct value.");
            payable(order[ordernumber].seller).transfer(msg.value);
            }
            ERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order[ordernumber].tokenid, copynumber, "" );
            order[ordernumber].amount -= copynumber;
            emit OrderBought(ordernumber, order[ordernumber].seller, msg.sender, order[ordernumber].saletype, copynumber, msg.value, block.timestamp);
        }


        modifier checkbid(uint256 o, uint256 Amount) {
            require(order[o].amount != 0, "Auction is closed for this order, You can't BID.");
            require(order[o].seller != msg.sender,"You are the seller, You Can't BID.");
            require(order[o].saletype==SaleType.AUCTION,"SaleType is not AUCTION.");
            require(Amount >= (order[o].priceperNFT * order[o].amount), "Enter Valid Price.");
            // require(Amount > bid[o][msg.sender].bidvalue,"New Bid Amount should be greater than your last bid.");
            require(Amount > biding[o].bidvalue,"Enter High bid amouunt.");
            _;

        }

        function placebid(address _nftaddress, uint256 ordernumber, uint256 bidAmount) public checkbid( ordernumber,bidAmount) {
            if(GetPayement(_nftaddress))
            {
                require(IERC20(GetPayementToken(_nftaddress)).balanceOf(msg.sender) >= bidAmount ,"You Don't have enough tokens to Place the Bid.");
                //IERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order.tokenid, _copynumber, "" );    
                //IERC20(GetPayementToken(_nftaddress)).transferFrom(msg.sender,order[ordernumber].seller,copynumber);

            }
            else
            {
                require(msg.sender.balance >= bidAmount, "You Dont Have enough balance to bid.");
                
            }
            biding[ordernumber]= Bid(
                msg.sender,
                bidAmount,
                block.timestamp
            );
            // bid[ordernumber][msg.sender] = Bid (
            //     msg.sender,
            //     bidAmount,
            //     block.timestamp
            // );
            emit BidPlaced(ordernumber, msg.sender, bidAmount, block.timestamp);
        }

        modifier checkclaimbid(uint256 o) {
            require(order[o].amount != 0, "Auction is closed for this order, BID was CLAIMED.");
            require(msg.sender == biding[o].bidder,"You are not the winner of the Auction of this Order.");
            // require(msg.value == biding[o].bidvalue,"Enter correct value.");
            _;
        }
    
        function ClaimBid( address _nftaddress , uint256 ordernumber) public payable checkclaimbid(ordernumber) {
            if(GetPayement(_nftaddress))
            {
                //require(IERC20(GetPayementToken(_nftaddress)).balanceOf(msg.sender) >= order[ordernumber].priceperNFT * copynumber,"You Don't have enough tokens to Buy.");
                //IERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order.tokenid, _copynumber, "" ); 
                
                // give allowance to escrow contract from the buyer in ERC20 contract    
                //IERC20(GetPayementToken(_nftaddress)).approve(address(this), 100000000000000000);
                IERC20(GetPayementToken(_nftaddress)).transferFrom(msg.sender,order[ordernumber].seller,biding[ordernumber].bidvalue);

            }
            else
            {
            //require( msg.value == (order[ordernumber].priceperNFT * order[ordernumber.amount]),"Enter Correct value.");
            require(msg.value == biding[ordernumber].bidvalue,"Enter correct value.");
            payable(order[ordernumber].seller).transfer(msg.value);
            }
            
            //payable(order[ordernumber].seller).transfer(msg.value);
            ERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order[ordernumber].tokenid, order[ordernumber].amount, "" );
            emit OrderBought(ordernumber, order[ordernumber].seller, msg.sender, order[ordernumber].saletype, order[ordernumber].amount, msg.value, block.timestamp);
            order[ordernumber].amount = 0;
        }

        function GetPayement(address _nftaddress) private view returns(bool){
            bool b = MyToken(_nftaddress).PaymentTokenEnabled();
            return b;
        }
        
        function GetPayementToken(address _nftaddress) private view returns(IERC20){
            IERC20 a = MyToken(_nftaddress).PaymentToken();
            return a;
        }

        function GetSaleType(address _nftaddress, uint256 id) private view returns(SaleType){
            return MyToken(_nftaddress).getSaletype(id);
        }

        function TotalOrders() public view returns(uint256) {
            return orderNumber.current();
        }

}
