// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract valueContrace {
    int private num1;
    int private num2;
    function getData(int number1, int number2) public {
        num1 = number1;
        num2 = number2;
    }
    function difference() public view returns(int substraction){
        int diff = num1 - num2;
        if(diff < 0 ) {
            substraction = diff + 1;
        } else {
            substraction = diff + 10;
        }
    }
    function addition() public view returns(int addition) {
        int sum = num1 + num2;
        if(sum > 50 ) {
            addition = sum + 5;
        } else {
            addition = sum + 8;
        }
    }
}