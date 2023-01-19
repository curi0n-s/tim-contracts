// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TIM } from "src/timsg.sol";

contract TimsgScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
            new TIM();
        vm.stopBroadcast();
    }
}
