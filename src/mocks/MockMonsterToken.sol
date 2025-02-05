// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockMonsterToken is ERC20 {
    uint8 private _decimals;

    constructor() ERC20("MonsterToken", "MON") {
        _mint(msg.sender, 1000000 * 10 ** 18);
        _decimals = 18;
    }

    function mint(address user, uint amount) external {
        _mint(user, amount);
    }

    function setDecimals(uint8 decimals_) external {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}