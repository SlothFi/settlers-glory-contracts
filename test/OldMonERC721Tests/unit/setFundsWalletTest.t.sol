// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title SetFundsWalletTest
 * @dev Test the setFundsWallet function
 */
contract SetFundsWalletTest is MonERC721TestBase {
    event FundsWalletChanged(address indexed oldWallet, address indexed newWallet);

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the setFundsWallet function
     * @notice Asserts that the funds wallet is set correctly
     */
    function test_setFundsWallet() public {
        address newFundsWallet = makeAddr("newFundsWallet");
        vm.startPrank(owner);
        monERC721.setFundsWallet(newFundsWallet);
        vm.stopPrank();

        assertEq(monERC721.fundsWallet(), newFundsWallet);
    }

    /**
     * @dev Test the setFundsWallet function
     * @notice Asserts that it reverts if the caller is not the owner
     */
    function test_setFundsWallet_revertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);
        monERC721.setFundsWallet(alice);
        vm.stopPrank();
    }

    /**
     * @dev Test the setFundsWallet function
     * @notice Asserts that it reverts if the address is zero
     */
    function test_setFundsWallet_revertsIfAddressIsZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidWallet.selector);
        vm.startPrank(owner);
        monERC721.setFundsWallet(address(0));
        vm.stopPrank();
    }

    /**
     * @dev Test the setFundsWallet function
     * @notice Asserts that it emits an event
     */
    function test_setFundsWallet_emitsAnEvent() public {
        address newFundsWallet = makeAddr("newFundsWallet");
        vm.expectEmit(true, true, false, false);
        emit FundsWalletChanged(fundsWallet, newFundsWallet);
        vm.startPrank(owner);
        monERC721.setFundsWallet(newFundsWallet);
        vm.stopPrank();
    }
}
