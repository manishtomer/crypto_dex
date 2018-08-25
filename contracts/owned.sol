pragma solidity ^0.4.4;


contract owned {
    address owner; 

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        if (msg.sender == owner) {
            _;
        }
    }
}
