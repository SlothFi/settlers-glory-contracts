// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MonERC721} from "../../src/MonERC721.sol";
import {MockMonsterToken} from "../../src/mocks/MockMonsterToken.sol";
import {MockERC721Receiver} from "./helper/MockERC721Receiver.t.sol";
import {MockRevertOnReceiveContract} from "./helper/MockRevertOnReceiveContract.t.sol";
/**
 * @title 
 */
contract MonERC721TestBase is Test {
    MonERC721 public monERC721;
    MockMonsterToken public monsterToken;

    string public name = "MonERC721";
    string public symbol = "MON";
    string public baseURI = "https://api.defimons.com/mon/";
    
    address public monsterTokenAddress;

    address public user = makeAddr("user");
    address public owner = makeAddr("owner");
    address public fundsWallet = makeAddr("fundsWallet");

    address public mockERC721Receiver = address(new MockERC721Receiver());
    address public mockRevertOnReceiveContract = address(new MockRevertOnReceiveContract());

    uint256 public maxSupply = 10000;
    uint256 public priceInNativeToken = 1000;
    uint256 public priceInMonsterToken = 1;


    function setUp() public virtual {
        monsterToken = new MockMonsterToken();
        monsterTokenAddress = address(monsterToken);

        // give the user and mockERC721Receiver some monster tokens
        monsterToken.transfer(user, 1000000);
        monsterToken.transfer(mockERC721Receiver, 1000000);
        monsterToken.transfer(mockRevertOnReceiveContract, 1000000);

        // give the user and mockERC721Receiver some native tokens
        vm.deal(user, 1000000 * priceInNativeToken);
        vm.deal(mockERC721Receiver, 1000000 * priceInNativeToken);
        vm.deal(mockRevertOnReceiveContract, 1000000 * priceInNativeToken);

        monERC721 = new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            baseURI,
            fundsWallet
        );
    }
}
