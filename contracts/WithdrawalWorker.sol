// SPDX-License-Identifier: MIT
// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IERC6777 } from "./interfaces/IBridge.sol";

contract WithdrawalWorker {
  constructor(
    IERC6777 token,
    address[] memory targets,
    bytes[] memory calldatas
  ) public {
    for (uint256 i = 0; i < targets.length; i++) {
      (bool success, ) = targets[i].call(calldatas[i]);
      require(success, "WW: call failed");
    }
    require(token.balanceOf(address(this)) == 0, "WW: no stuck tokens");
    assembly {
      return(0, 0)
    }
  }
}
