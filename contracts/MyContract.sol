// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MyContract {
    uint public value;

    function setValue(uint _value) public {
        value = _value;
    }
}