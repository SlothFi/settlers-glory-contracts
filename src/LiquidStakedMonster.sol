// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LiquidStakedMonster is ERC20 {
    constructor() ERC20("Liquid Staked Monster", "lsMON") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}