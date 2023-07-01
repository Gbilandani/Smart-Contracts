// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract StudentSubject {
    struct student {
        uint grade;
        string name;
        string course;
        string subject;
    }

    mapping (uint => student) public studentMap;

    function getData(uint Id, uint Grade, string memory Name, string memory Course) public{
        studentMap[Id] = student(Grade, Name, Course,'');
        student storage stu = studentMap[Id];
        if(stu.grade < 70) {
           stu.subject = "Rust";
        } else {
            stu.subject = "Solidity";
        }
    }
}