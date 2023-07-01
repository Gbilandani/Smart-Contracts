// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

enum PlanStatus{ACTIVE, DEACTIVE, COMPLETED}
enum Phases{ DRILLING, CRASHING, REFINING, TRANSPORTATION, SHIPMENT}

contract SupplyChain is ERC20{
    AggregatorV3Interface internal Etherprice;
    using Counters for Counters.Counter;
    Counters.Counter private PlanId;
    // PlanStatus status;
    uint256 private maxsupply;
    uint256 private minted=0;
    mapping(address => bool) public Approvers;
    mapping(address => bool) public Vendors;
    // uint256 StartDate;
    // uint256 EndDate;

    struct Plan{
        uint256 planid;
        uint256 tokensupply;
        address Vendors;
        PlanStatus planstatus;
        Phases currentphase;
        uint256 startDate;
        uint256 endDate;
    }

    address[] private newaddress;
    address[] private approvers;
    mapping(uint256 => Plan) public plans;
    // mapping(uint256 => mapping(Phases => PlanStatus)) public approved;
    mapping(uint256 => mapping(address => bool)) public phaseapproval;

    address private _owner;
    constructor(uint256 _MaxSupply) ERC20("IronOre", "IOR") {
        Etherprice = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        _owner = msg.sender;
        maxsupply = _MaxSupply;
    }

    modifier onlyOwner() {
        require(msg.sender ==_owner, "You are not the Owner, You can't change");
        _;
    }

    modifier notOwner(address _approvers) {
        require(_approvers!= owner(), "You are Owner. You can't be Approver or Vendor");
        _;
    }

    modifier onlyApprover() {
        require(Approvers[msg.sender],"You are not the Approver.");
        _;
    }

    modifier onlyvendor() {
        require(Vendors[msg.sender],"You are not the vendor.");
        _;
    }

    modifier checkPlan(uint256 _PlanId) {
        require(plans[_PlanId].planstatus== PlanStatus.ACTIVE,"The Plan is NOT Activated.");
        _;
    }

    modifier checkDate(uint256 _EndDate){
        require(_EndDate > block.timestamp, "End Date must be in future.");
        _;
    }

    function GiveApproval(uint256 _PlanId) public checkPlan(_PlanId) {
        
        if(msg.sender == owner())
        {
            
            uint ab = uint(plans[_PlanId].currentphase);
            if(ab == 4)
            {
                uint256 tokens = plans[_PlanId].tokensupply;
                address vendor = plans[_PlanId].Vendors;
                transfer(vendor,tokens);
                plans[_PlanId].planstatus = PlanStatus.COMPLETED;

            }
            else
            {
            ab++ ;
            plans[_PlanId].currentphase = Phases(ab);
            }
            for(uint i=0 ; i< approvers.length ; i++)
            {
                phaseapproval[_PlanId][approvers[i]]=false;
            }
        }
        else
        {
            require(Approvers[msg.sender],"You are not the Approver.");
            phaseapproval[_PlanId][msg.sender] = true;
            CheckPhaseApproval(_PlanId);
        }
    }

    function CheckPhaseApproval(uint256 _PlanId) internal checkPlan(_PlanId) {
        uint flag=0;
        for(uint256 i=0 ; i< approvers.length; i++)
        {
            if(!phaseapproval[_PlanId][approvers[i]])
            {
                flag=1;
                
            }
        }
        if(flag==0)
        {   
            if(plans[_PlanId].currentphase == Phases.SHIPMENT)
            {
                uint256 tokens = plans[_PlanId].tokensupply;
                address vendor = plans[_PlanId].Vendors;
                transferFrom(owner(),vendor,tokens);
                plans[_PlanId].planstatus = PlanStatus.COMPLETED;
            }
            else
            {
                uint ab = uint(plans[_PlanId].currentphase);
                ab++ ;
                
                plans[_PlanId].currentphase = Phases(ab);
            }
            for(uint i=0 ; i< approvers.length ; i++)
            {
                phaseapproval[_PlanId][approvers[i]]=false;
            }
        }
    }

    function Drilling(uint256 amount, uint256 _EndDate) public onlyvendor() checkDate(_EndDate) {
        PlanId.increment();
        uint256 PLANID = PlanId.current();
        // StartDate = block.timestamp;
        // EndDate = _EndDate;
        require((minted + amount) < maxsupply , "Out of Max Supply");
        _mint(owner(), amount);
        plans[PLANID]= Plan(
            PLANID,
            amount,
            msg.sender,
            PlanStatus.ACTIVE,
            Phases.DRILLING,
            block.timestamp,
            _EndDate
        );
        minted += amount;
    }

    function owner() public view returns(address){
        return _owner;
    }

    function changeMaxSupply(uint256 _max) public onlyOwner {
        maxsupply = _max;
    }

    function GetMaxSupply() public view returns(uint256) {
        return maxsupply;
    }    

    function AddApprovers(address _approvers) public onlyOwner notOwner(_approvers) {
        approve(_approvers,maxsupply);
        Approvers[_approvers]=true;
        approvers.push(_approvers);
    }

    function ApproversList() view public returns( address[] memory) {
        return approvers;
    }

    function RemoveApprovers(address _approvers) public onlyOwner returns(address[] memory) {
        for(uint i=0 ; i < approvers.length; i++)
        {
            if(approvers[i] != _approvers)
            {
                newaddress.push(approvers[i]);
            }
        }

        Approvers[_approvers]=false;
        approvers = newaddress;
        for(uint j = 0; j <= newaddress.length ; j++)
        {
            newaddress.pop();
        }
        return approvers;
        
    }

    function AddVendors(address _vendors) public onlyOwner notOwner(_vendors){
        // approve(_vendors,maxsupply);
        Vendors[_vendors]=true;
    }

    function RemoveVendors(address _vendors) public onlyOwner {
        Vendors[_vendors]=false;
    }

    function ChangeDate(uint256 _PlanId, uint256 _enddate) public onlyOwner {
        require(_enddate > block.timestamp,"End Date must be after Start Date.");
        // StartDate = _startdate;
        plans[_PlanId].endDate = _enddate;
        // EndDate = _enddate;
    }

    function TerminatePlan(uint256 _PlanId) public onlyOwner checkPlan(_PlanId) {
        // require(plans[_PlanId].planstatus != PlanStatus.COMPLETED, "The Plan is already Completed.");
        plans[_PlanId].planstatus = PlanStatus.DEACTIVE;
    }

    modifier checkClaim(uint256 _PlanId) {
        require(plans[_PlanId].planstatus== PlanStatus.COMPLETED,"The Plan is NOT Completed.");
        require(msg.sender == plans[_PlanId].Vendors,"You are not the vendor of this plan.");
        _;
    }

    function Claim(uint256 _PlanId) public view checkClaim(_PlanId) returns(uint256) {
        
        //approve(address(this),tokens);
        uint256 tokens = plans[_PlanId].tokensupply;
        // address vendor = plans[_PlanId].Vendors;
        ( , int256 Ether, , , ) = Etherprice.latestRoundData();
        //Ether = (Ether/10**8);
        uint256 Eth = uint256(Ether);
        uint256 USD = (tokens*Eth)/1000;
        return USD;
    }

    
}