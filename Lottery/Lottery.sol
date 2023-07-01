//SPDX-License-Identifier:MIT

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address public manager ;
    address payable[] public participants;
    event logAddress(address winner);

    function print(address winner) public pure returns(address){
        return winner;
    }

    constructor(){
        manager = msg.sender;
    }

    receive() external payable{
        require(msg.value == 100000000000000);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint){
        require(msg.sender == manager);
        return(address(this).balance);
    }


    function random() public view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    /*
    function selectWinner() public view returns (address){

        require(msg.sender == manager);
        require(participants.length >= 3);
        uint r = random();

        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        
        return winner;
    }
    */

    function selectWinner() public{

        require(msg.sender == manager);
        require(participants.length >= 3);
        uint r = random();

        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        emit logAddress(winner);
        winner.transfer(getBalance());
        participants = new address payable[](0);
}
}