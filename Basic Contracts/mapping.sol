// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract studentContract {
    struct student {
        string name;
        uint age;
    }
    mapping(address => student) public studentMap;

    function getData(address Address, string memory Name, uint Age) public {
        studentMap[Address] = student(Name,Age);
    }
}