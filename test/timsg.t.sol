// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// import {ERC1155Recipient} from "lib/solmate/src/test/ERC1155.t.sol";
// import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "lib/forge-std/src/Test.sol";

import {TIM} from "../src/timsg.sol";



// contract TimsgERC1155Tester is ERC1155Recipient, Test {
contract TimsgERC1155Tester is Test {

    //======================================================================
    //SETUP
    //======================================================================

    TIM public TIMSG;

    address public ownerAddress = 0xf0dbd59b214405FF0b2364dac77Ae14662CcfcDD;
    bool public loggingIsOn = true;
    uint256 public numberOfAddresses = 10000;

    address[] public addressList = new address[](numberOfAddresses);
    string[] public stringList;

    //======================================================================

    function setUp() public {
        
        generateAddressListAndDealEther();

        vm.startPrank(ownerAddress);
            TIMSG = new TIM();
            TIMSG.setmintPrice(0.00 ether);
            stringList.push("hello");
            stringList.push("testing");
            stringList.push("12345");
            TIMSG.mintTo{ value: 0.00 ether }(
                stringList,
                ownerAddress,
                true
            );
        vm.stopPrank();
        

    }

    //======================================================================
    //FUNCTIONS
    //======================================================================

    //generate list of 100 random addresses
    function generateAddressListAndDealEther() public {
        for (uint256 i = 0; i < 10; i++) {
            addressList[i] = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, i)))));
            vm.deal(addressList[i], 1 ether); // and YOU get an ETH
        }
        // emit log_array(addressList);
    }

    //======================================================================
    //TESTS
    //======================================================================

    //test to check that the Pendings contract is deployed
    function testIsDeployed() public {
        assertTrue(address(TIMSG) != address(0));
    }

    function testMetadataCallForID1() public {
        emit log_string(TIMSG.buildMetadata(1));
    }




    
}
