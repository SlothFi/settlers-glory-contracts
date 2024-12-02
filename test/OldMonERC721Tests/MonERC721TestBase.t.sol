// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MonERC721} from "../../src/MonERC721.sol";
import {MockMonsterToken} from "../../src/mocks/MockMonsterToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RevertingContract} from "./helper/RevertingContract.t.sol";

/**
 * @title MonERC721TestBase
 * @dev Base contract for MonERC721 tests
 * @dev Contains common setup logic
 */
contract MonERC721TestBase is Test {
    uint256 public constant MAX_SUPPLY = 3;
    uint256 public constant PRICE_IN_NATIVE_TOKEN = 1 ether;
    uint256 public constant PRICE_IN_MONSTER_TOKEN = 100 * 10 ** 18;
    uint256 public constant ALICE_NATIVE_BALANCE = 100 ether;
    uint256 public constant ALICE_MONSTER_BALANCE = 1_000 * 10 ** 18;
    uint256 public constant REVERTING_CONTRACT_BALANCE = 5 ether;

    MonERC721 public monERC721;
    MockMonsterToken public monsterToken;
    RevertingContract public revertingContract;

    address public fundsWallet = makeAddr("fundsWallet");
    address public alice = makeAddr("alice");
    address public owner = makeAddr("owner");

    function setUp() public virtual {
        monsterToken = new MockMonsterToken();
        monERC721 = new MonERC721(
            "MonERC721",
            "MON",
            owner,
            MAX_SUPPLY,
            PRICE_IN_NATIVE_TOKEN,
            PRICE_IN_MONSTER_TOKEN,
            address(monsterToken),
            "https://example.com/",
            fundsWallet
        );

        revertingContract =
            new RevertingContract{value: REVERTING_CONTRACT_BALANCE}(address(monERC721), PRICE_IN_NATIVE_TOKEN, alice);

        vm.deal(alice, ALICE_NATIVE_BALANCE);
        monsterToken.transfer(alice, ALICE_MONSTER_BALANCE);

        vm.startPrank(alice);
        monsterToken.approve(address(monERC721), type(uint256).max);
        vm.stopPrank();

        assertEq(monERC721.owner(), owner);
        assertEq(monERC721.maxSupply(), MAX_SUPPLY);
        assertEq(monERC721.priceInNativeToken(), PRICE_IN_NATIVE_TOKEN);
        assertEq(monERC721.priceInMonsterToken(), PRICE_IN_MONSTER_TOKEN);
        assertEq(monERC721.monsterToken(), address(monsterToken));
        assertEq(monERC721.baseUri(), "https://example.com/");
        assertEq(monERC721.fundsWallet(), fundsWallet);

        assertEq(monsterToken.balanceOf(address(monERC721)), 0);
        assertEq(monsterToken.balanceOf(alice), ALICE_MONSTER_BALANCE);
        assertEq(monERC721.balanceOf(alice), 0);
        assertEq(address(alice).balance, ALICE_NATIVE_BALANCE);
        assertEq(monsterToken.allowance(alice, address(monERC721)), type(uint256).max);
    }
}
