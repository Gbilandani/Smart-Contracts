// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Iescrow.sol";
import "./ERC20Contract.sol";

enum SaleType{AUCTION,INSTANT}


contract MyToken is ERC1155 ,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokend;
    IERC20 private paymenttoken;
    address public escrowcontractaddress;
    bool private paymenttokenenabled; 

    struct tokens {
        uint256 maxcopies;
        uint256 tokenid;
        SaleType saletype;
        string uri;
    }


    mapping (uint256 => tokens) private token;

    mapping(uint256 => string) private tokenuri;

    

    constructor(address _paymenttoken,address _escrowcontract) ERC1155("") {
        paymenttoken = IERC20(_paymenttoken);
        escrowcontractaddress = _escrowcontract;
    }
    
    modifier abc(){
        require(paymenttokenenabled==false,"PaymentToken is already enabled");
        _;
    }
    function enablepaymenttoken() public onlyOwner abc{
        paymenttokenenabled=true;
    }

    modifier adc(){
        require(paymenttokenenabled==true,"PaymentToken is already disabled");
        _;
    }
    function disablepaymenttoken() public onlyOwner adc{
        paymenttokenenabled=false;
    }

    modifier mintcondition(uint256 numberofcopies, string memory Tokenuri, SaleType saletype,uint256 priceperNFT) {
        require(numberofcopies>0,"Number Of Copies must be greater than 0.");
        require(bytes(Tokenuri).length>0,"Please enter Token URI.");
        require(saletype==SaleType.AUCTION || saletype==SaleType.INSTANT,"saletype must be 0 for AUCTION and 1 for INSTANT.");
        require(priceperNFT >0,"Price per NFT must be greater than 0.");
        _;
    }


    function Minttoken(uint256 numberofcopies, string memory Tokenuri, SaleType saletype,uint256 priceperNFT) public mintcondition(numberofcopies, Tokenuri, saletype, priceperNFT) {
        tokend.increment();
        uint256 TOKENID = tokend.current();
        _mint(msg.sender, TOKENID, numberofcopies, "");
        setURI(TOKENID, Tokenuri);
        setApprovalForAll(escrowcontractaddress, true);
        token[TOKENID] = tokens(
            numberofcopies,
            TOKENID,
            saletype,
            Tokenuri
        );

        // MyTokenerc20(escrowcontractaddress)._approve(escrowcontractaddress, 100000000000000000);
        Iescrowcontract(escrowcontractaddress).PlaceOrder( address(this) , msg.sender , TOKENID, numberofcopies, priceperNFT);
        
        
    }

    function setURI(uint256 id ,string memory newuri) public onlyOwner {
        tokenuri[id]= newuri;
    }

    function GetTokenUri (uint256 id) public view returns(string memory) {
        return tokenuri[id];
    }


    function PaymentTokenEnabled() public view returns(bool){
        return paymenttokenenabled;
    }

    function PaymentToken() public view returns(IERC20){
        return paymenttoken;
    }

    function getSaletype(uint256 id) public view returns(SaleType){
        return token[id].saletype;
    }

    // function GetBalance () public view returns(uint256) {
    //     return msg.sender.balance;
    // }
}