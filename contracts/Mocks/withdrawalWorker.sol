// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract WithdrawalWorker {
  constructor(address[] memory targets, bytes[] memory calldatas) {
    for (uint256 i = 0; i < targets.length; i++) {
      (bool success, ) = targets[i].call(calldatas[i]);
      require(success, "WW: call failed");
    }
    assembly {
      return(0, 0)
    }
  }
}
