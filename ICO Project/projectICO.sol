// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ICOGAURAV is Ownable { 
    using Counters for Counters.Counter;
    Counters.Counter private icoID;
  
    struct ico{
        address token;
        uint256 startTime;
        uint256 amount ;
        uint256 pricePerToken;
    }
    mapping (uint256 icoID => ico) public ICOmap;
    
    mapping ( uint256 => address) private Token;


    // Events
    event NewICOCreated(uint256 icoID, address token, uint256 tokenAmount, uint256 pricePerToken, uint256 time);
    event ICOTokenBought(uint256 icoID, address buyer, uint256 tokenAmount, uint256 pricePerToken, uint256 FundsGiven, uint256 time);
    event ICOTokenSold(uint256 icoID, address seller, uint256 tokenAmount, uint256 pricePerToken, uint256 FundsGiven, uint256 time);
    event WithdrawEthers(uint256 time, uint256 Amount);
    event priceChange(uint256 icoID, uint256 oldPrice, uint256 newPrice, uint256 time);


    // Modifiers
    modifier checkBalance(){
        require( address(this).balance > 0 , "There are no Ethers in this contract");
        _;
    }
    
    modifier checkICO(uint256 _icoID ){
        require(ICOmap[_icoID].pricePerToken!=0,"This ICO is unavailable currently.");
        _;
    }

    modifier checkNewRate(uint256 amount){
        require(amount > 0 , "Rate can not be 0");
        _;
    }

    modifier checkValue(){
        require(msg.value>0,"Enter value greater than 0");
        _;
    }

    modifier checkTokenBalance(uint256 _icoID, uint256 _tokenAmount){
        require(myTokenBalance(_icoID)>=_tokenAmount,"You dont have enough tokens");
        _;
    }

    modifier checkToken(uint256 _icoID){
        require(tokenBalance(_icoID)!=0,"No tokens to buy in this ICO.");
        _;
    }


    // Functions
    function createNewICO(address _token, uint256 _amount, uint256 _pricePerToken) public {
        icoID.increment();
        uint256 ICOID = icoID.current();
        emit NewICOCreated(ICOID, _token, _amount, _pricePerToken, block.timestamp);
        ICOmap[ICOID] = ico(
            _token,
            block.timestamp,
            _amount,
            _pricePerToken
        );
        Token[ICOID] = address(_token);
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function newRate (uint256 _icoID, uint amount )  external onlyOwner checkICO(_icoID) checkNewRate(amount) { 
        emit priceChange(_icoID, ICOmap[_icoID].pricePerToken, amount, block.timestamp);
        ICOmap[_icoID].pricePerToken = amount;
    }
   
    function etherWithdraw () external onlyOwner checkBalance { 
        uint256 Balance = address(this).balance;
        emit WithdrawEthers(block.timestamp, Balance);
        payable(owner()).transfer(Balance);
    }

    function buyToken (uint256 _icoID) external payable checkICO(_icoID) checkValue checkToken(_icoID){
        uint tokensAmount = msg.value / ICOmap[_icoID].pricePerToken;
        
        if(tokensAmount >= tokenBalance (_icoID))
        {
            tokensAmount = tokenBalance(_icoID);
        }
        emit ICOTokenBought(_icoID, msg.sender, tokensAmount, ICOmap[_icoID].pricePerToken, msg.value, block.timestamp);
        IERC20(Token[_icoID]).transfer(msg.sender, tokensAmount);
        ICOmap[_icoID].amount = tokenBalance(_icoID);
    }
    
    function sellToken (uint256 _icoID, uint _tokenAmount ) external checkICO(_icoID) checkTokenBalance(_icoID,_tokenAmount) { 
        uint allowanceToken = ERC20(Token[_icoID]).allowance(msg.sender, address(this));
        uint etheramount = _tokenAmount * ICOmap[_icoID].pricePerToken; 
        require( allowanceToken >= _tokenAmount, "give allowance first "); 
        emit ICOTokenSold(_icoID, msg.sender, _tokenAmount, ICOmap[_icoID].pricePerToken, etheramount, block.timestamp);
        IERC20(Token[_icoID]).transferFrom(msg.sender , address(this), _tokenAmount);
        payable(msg.sender).transfer(etheramount);
        ICOmap[_icoID].amount = tokenBalance(_icoID);
    }

    // Getter Functions
    function myTokenBalance(uint256 _icoID) public view returns(uint256){
        uint balance = IERC20(Token[_icoID]).balanceOf(msg.sender);
        return balance;
    }
   
    function tokenBalance(uint256 _icoID) public  view returns ( uint ) { 
        return IERC20(Token[_icoID]).balanceOf(address(this));
    }
    
    function etherBalance () public view returns ( uint ) { 
        return address(this).balance;
    }

    function getICO(uint256 _icoID) public view returns(ico memory){
        return(ICOmap[_icoID]);
    }

    function NumberOfICO() public view returns(uint256){
        return icoID.current();
    }
}