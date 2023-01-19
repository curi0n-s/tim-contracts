// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { nftmsg } from "src/nftmsg.sol";

contract NftmsgScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
            new nftmsg();
        vm.stopBroadcast();
    }
}
