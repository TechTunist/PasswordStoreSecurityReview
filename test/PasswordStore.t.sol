// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;
    DeployPasswordStore public deployer;
    address public owner;

    // audit specific test setup
    address public NOT_OWNER = makeAddr("non_owner");
    /////////////////////////////////// 

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = msg.sender;
    }

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
    }

    function test_non_owner_reading_password_reverts() public {
        vm.startPrank(address(1));

        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
        vm.stopPrank();
    }

    // @audit test to prove that non_owners can set the password
    function test_non_owner_can_set_password() public {
        vm.startPrank(NOT_OWNER);
        string memory expectedPassword = "thisWasSetByANonOwnerFromAddress";
        passwordStore.setPassword(expectedPassword);
        vm.stopPrank();

        vm.startPrank(owner);
        string memory actualPassword = passwordStore.getPassword();
        passwordStore.setPassword("thisWasSetByANonOwnerFromAddress:");
        assertEq(actualPassword, expectedPassword);
    
        console.log("The password: ", passwordStore.getPassword(), " was changed by the non-owner", NOT_OWNER);
        console.log("The owner's address: ", owner, "The address of the user that set the password: ", NOT_OWNER);
        vm.stopPrank();
    }
}
