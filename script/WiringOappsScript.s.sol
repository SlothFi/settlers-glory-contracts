// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MonStaking} from "../src/MonStaking.sol";

contract WiringOappsScript is Script {
    function run() public {
        address ethereumMonStakingOApp = vm.envAddress("ETHEREUM_MONSTAKING_OAPP");
        address arbitrumMonStakingOApp = vm.envAddress("ARBITRUM_MONSTAKING_OAPP");

        vm.startBroadcast();

        // Wire the OApps
        if (block.chainid == 1) {
            MonStaking(ethereumMonStakingOApp).setPeer(uint32(42161), bytes32(uint256(uint160(arbitrumMonStakingOApp))));
        } else if (block.chainid == 42161) {
            MonStaking(arbitrumMonStakingOApp).setPeer(uint32(1), bytes32(uint256(uint160(ethereumMonStakingOApp))));
        }
        vm.stopBroadcast();
    }
}