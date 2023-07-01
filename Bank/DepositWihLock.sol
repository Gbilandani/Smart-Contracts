// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4; 

contract DepositWithdraw {
    address public _owner;
    constructor() {
        _owner = msg.sender;
    }
    
    enum AccountType
    {
        SAVINGS,
        FIXED
    }
    struct Account {
        address owner;
        uint256 balance;
        uint256 accountCreatedTime;
        uint256 lockPeriod;
        uint256 atype;
    }
    mapping(address => Account) public MDAccount;

    event balanceAdded(address owner, uint256 balance, uint256 timestamp);
    event withdrawalDone(address owner, uint256 balance, uint256 timestamp);

    modifier minimum() {
        require(msg.value >= 0.00001 ether, "Doesn't follow minimum criteria");
        _;
    }

    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // account creation
    function accountCreated(AccountType _atype, uint256 lperiod) public payable minimum {

        MDAccount[msg.sender].owner = msg.sender;
        MDAccount[msg.sender].balance = msg.value;
        MDAccount[msg.sender].accountCreatedTime = block.timestamp;
        MDAccount[msg.sender].atype = uint256(_atype);
        if(_atype == AccountType.SAVINGS)
        {
            MDAccount[msg.sender].lockPeriod = 0;
           
        }
        else if(_atype == AccountType.FIXED)
        {
            MDAccount[msg.sender].lockPeriod = lperiod;
        }
        emit balanceAdded(msg.sender, msg.value, block.timestamp);
    }

    // depositing funds
    function deposit() public payable minimum {
        MDAccount[msg.sender].balance += msg.value;
        emit balanceAdded(msg.sender, msg.value, block.timestamp);
    }

    
    // withdrawal
    function withdrawal() public payable {
        // address.transfer(amount to transfer)
        if(MDAccount[msg.sender].atype == 1)
        {
            require(MDAccount[msg.sender].lockPeriod <= block.timestamp, "You cannot withdraw the funds with Fixed");
        }
        payable(msg.sender).transfer(MDAccount[msg.sender].balance);
        MDAccount[msg.sender].balance = 0; // clear the balance
        // payable(msg.sender)
        emit withdrawalDone(
            msg.sender,
            MDAccount[msg.sender].balance,
            block.timestamp
        );
    }

    function getBalance(address _add) public view onlyOwner returns(uint256)
    {
        return MDAccount[_add].balance;
    }
}