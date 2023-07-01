// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ICOINSTALLMENTGAURAV is Ownable { 
    using Counters for Counters.Counter;
    Counters.Counter private icoID;
  
    struct ico{
        address token;
        uint256 startTime;
        uint256 endTime;
        uint256 amount ;
        uint256 pricePerToken;
    }
    
    uint256 installmentTotalToken;
    
    struct installment{
        uint installmentToken;
        uint installmentTime;
    }

    // mappings
    mapping( uint icoid => mapping (address user => installment)) private installmentMap; // installments of user
    
    mapping ( uint256 => address) private Token; // payment token (ICO)

    mapping (uint256 IcoId => uint256 InstallmentTokens) public ICOInstallmentToken; // total installment token of a particular ICOid
    
    mapping (uint256 icoID => ico) public ICOmap; // ICO mapping (new ICO)


    // Events
    event NewICOCreated(uint256 icoID, address token, uint256 tokenAmount, uint256 pricePerToken, uint256 startTime, uint256 endTime, uint256 currentTime);
    event ICOTokenBought(uint256 icoID, address buyer, uint256 tokenAmount, uint256 pricePerToken, uint256 FundsGiven, uint256 tokenPrice, uint256 RefundFunds, uint256 time);
    event ICOTokenSold(uint256 icoID, address seller, uint256 tokenAmount, uint256 pricePerToken, uint256 FundsGiven, uint256 time);
    event WithdrawEthers(uint256 time, uint256 Amount);
    event priceChange(uint256 icoID, uint256 oldPrice, uint256 newPrice, uint256 time);
    event installmentTokentransferred(uint256 icoID, address buyer, uint256 TokenAmount, uint256 timestamp);


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

    modifier checkEndTime(uint256 _icoID){
        require(ICOmap[_icoID].endTime > block.timestamp, "This ICO has ended, buy other ICO.");
        _;
    }

    modifier checkStartTime(uint256 _icoID){
        require(ICOmap[_icoID].startTime < block.timestamp, "This ICO has not yet started, buy other ICO.");
        _;
    }

    modifier checkInstallment(uint256 _icoID){
        require((installmentMap[_icoID][msg.sender].installmentTime) < block.timestamp, "Installment Time not over yet.");
        require((installmentMap[_icoID][msg.sender].installmentToken) > 0, "You dont have Installment Tokens.");
        _;
    }

    modifier checkNotOwner(){
        require(msg.sender != owner(),"You are the Owner, You can't access this function.");
        _;
    }


    // Functions
    function createNewICO(address _token, uint256 _startTime, uint256 _endTime, uint256 _amount, uint256 _pricePerToken) public onlyOwner {
        if(_startTime == 0){
            _startTime = block.timestamp;
        }
        else
        {
            require(_startTime > block.timestamp,"enter 0 for start ico now OR enter future time.");
        }
        if(_endTime == 0){
            _endTime = block.timestamp+(24*60*60); // set default end time 1 day
        }
        else
        {
            require(_endTime > (block.timestamp+60),"Minimum time for ICO is 60 seconds. OR Enter 0 ");
        }
        require((_startTime+60) < _endTime ,"Please enter Correct timings. Minimum time for ICO is 60 seconds.");
        icoID.increment();
        uint256 ICOID = icoID.current();
        ICOmap[ICOID] = ico(
            _token,
            _startTime,
            _endTime,
            _amount,
            _pricePerToken
        );
        Token[ICOID] = address(_token);
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit NewICOCreated(ICOID, _token, _amount, _pricePerToken, _startTime, _endTime, block.timestamp);
    }

    function newRate (uint256 _icoID, uint amount )  external onlyOwner checkICO(_icoID) checkNewRate(amount) { 
        ICOmap[_icoID].pricePerToken = amount;
        emit priceChange(_icoID, ICOmap[_icoID].pricePerToken, amount, block.timestamp);
    }
   
    function etherWithdraw () external onlyOwner checkBalance { 
        uint256 Balance = address(this).balance;
        payable(owner()).transfer(Balance);
        emit WithdrawEthers(block.timestamp, Balance);
    }

    function buyToken (uint256 _icoID) external payable checkNotOwner checkICO(_icoID) checkStartTime(_icoID)  checkValue checkToken(_icoID) checkEndTime(_icoID)  {
        uint tokensAmount = msg.value / ICOmap[_icoID].pricePerToken;
        uint newTokenAmount = tokensAmount / 2 ;
        uint256 tokenPrice = msg.value;
        uint256 refundPrice = 0;
        if(tokenBalance(_icoID) < tokensAmount)
        {
            tokensAmount = tokenBalance(_icoID);
            newTokenAmount = tokensAmount / 2 ;
            tokenPrice = ( tokensAmount * ICOmap[_icoID].pricePerToken);
            refundPrice = msg.value - tokenPrice;
            payable(msg.sender).transfer(refundPrice);
        }
        IERC20(Token[_icoID]).transfer(msg.sender, newTokenAmount);
        installmentMap[_icoID][msg.sender] = installment(
            newTokenAmount,
            (block.timestamp+300)
        );
        ICOInstallmentToken[_icoID] += newTokenAmount; 
        installmentTotalToken += newTokenAmount;
        ICOmap[_icoID].amount -= (newTokenAmount*2) ;
        emit ICOTokenBought(_icoID, msg.sender, (newTokenAmount*2), ICOmap[_icoID].pricePerToken, msg.value, tokenPrice, refundPrice, block.timestamp);
    }

    function GetInstallment(uint _icoID) public checkNotOwner checkICO(_icoID) checkInstallment(_icoID) {
        uint instamt = installmentMap[_icoID][msg.sender].installmentToken;
        IERC20(Token[_icoID]).transfer(msg.sender, instamt);
        installmentMap[_icoID][msg.sender].installmentToken -= instamt;
        installmentTotalToken -= instamt;
        ICOInstallmentToken[_icoID] -= instamt; 
        emit installmentTokentransferred(_icoID, msg.sender, instamt, block.timestamp);
    }
    
    function sellToken (uint256 _icoID, uint _tokenAmount ) checkNotOwner external checkICO(_icoID) checkTokenBalance(_icoID,_tokenAmount) { 
        uint allowanceToken = ERC20(Token[_icoID]).allowance(msg.sender, address(this));
        uint etheramount = _tokenAmount * ICOmap[_icoID].pricePerToken; 
        require( allowanceToken >= _tokenAmount, "give allowance first "); 
        IERC20(Token[_icoID]).transferFrom(msg.sender , address(this), _tokenAmount);
        payable(msg.sender).transfer(etheramount);
        ICOmap[_icoID].amount += _tokenAmount;
        emit ICOTokenSold(_icoID, msg.sender, _tokenAmount, ICOmap[_icoID].pricePerToken, etheramount, block.timestamp);
    }

    // Getter Functions
    function myTokenBalance(uint256 _icoID) public view returns(uint256){
        uint balance = IERC20(Token[_icoID]).balanceOf(msg.sender);
        return (balance);
    }

    function tokenBalance(uint256 _icoID) public  view returns ( uint ) { 
        uint balance = IERC20(Token[_icoID]).balanceOf(address(this));
        return (balance-ICOInstallmentToken[_icoID]);
    }
    
    function etherBalance () public view returns ( uint ) { 
        return address(this).balance;
    }

    function NumberOfICO() public view returns(uint256){
        return icoID.current();
    }

    function currentTime() public view returns(uint256){
        return block.timestamp;
    }

    function myInstallmentToken(uint _icoID) public view returns(uint256 installmentToken, uint256 installmentTime){
        return (installmentMap[_icoID][msg.sender].installmentToken,installmentMap[_icoID][msg.sender].installmentTime);
    }

    function totalInstallmentToken() public view returns(uint256){
        return installmentTotalToken;
    }
}