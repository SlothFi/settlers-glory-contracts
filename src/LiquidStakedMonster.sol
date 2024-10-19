// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IMonStaking} from "./interfaces/IMonStaking.sol";

contract LiquidStakedMonster is ERC20, AccessControl {
    error LiquidStakedMonster__InvalidMarketPlace();
    error LiquidStakedMonster__InvalidOperatorRole();
    error LiquidStakedMonster__InvalidDefaultAdminRole();
    error LiquidStakedMonster__NoZeroAmount();
    error LiquidStakedMonster__NoZeroAddress();
    error LiquidStakedMonster__TokenNotTransferable();

    event Minted(address indexed to, uint256 indexed amount);
    event Burned(address indexed from, uint256 indexed amount);
    event MarketPlaceChanged(address indexed oldMarketPlace, address indexed newMarketPlace);

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public s_marketPlace;
    IMonStaking public immutable i_stakingContract;

    constructor(address _operatorRole, address _defaultAdmin, address _marketPlace)
        ERC20("Liquid Staked Monster", "lsMON")
    {
        if (_marketPlace == address(0)) revert LiquidStakedMonster__InvalidMarketPlace();
        if (_operatorRole == address(0)) revert LiquidStakedMonster__InvalidOperatorRole();
        if (_defaultAdmin == address(0)) revert LiquidStakedMonster__InvalidDefaultAdminRole();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(CONTROLLER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operatorRole);
        // This is to prevent the DEFAULT_ADMIN_ROLE from being able to grant the MINTER_ROLE which is only of the staking contract
        _setRoleAdmin(CONTROLLER_ROLE, CONTROLLER_ROLE);

        s_marketPlace = _marketPlace;
        i_stakingContract = IMonStaking(msg.sender);
    }

    function mint(address _to, uint256 _amount) external onlyRole(CONTROLLER_ROLE) {
        if (_to == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        if (_amount == 0) revert LiquidStakedMonster__NoZeroAmount();

        _mint(_to, _amount);

        emit Minted(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(CONTROLLER_ROLE) {
        if (_from == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        if (_amount == 0) revert LiquidStakedMonster__NoZeroAmount();

        _burn(_from, _amount);

        emit Burned(_from, _amount);
    }

    function transfer(uint256 _value, address _to) public payable returns (bool) {
        if (_to == s_marketPlace) i_stakingContract.updateStakingBalance{value: msg.value}(msg.sender, _to, _value);

        return transfer(_to, _value);
    }

    function transferFrom(uint256 _value, address _from, address _to) public payable returns (bool) {
        if (_from == s_marketPlace) i_stakingContract.updateStakingBalance{value: msg.value}(_from, _to, _value);

        return transferFrom(_from, _to, _value);
    }

    function setMarketPlace(address _marketPlace) external onlyRole(OPERATOR_ROLE) {
        if (_marketPlace == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        address oldMarketPlace = s_marketPlace;
        s_marketPlace = _marketPlace;
        emit MarketPlaceChanged(oldMarketPlace, _marketPlace);
    }

    function _update(address _from, address _to, uint256 _value) internal override {
        if (_from != address(0) && (_to != address(0) && _to != s_marketPlace)) {
            revert LiquidStakedMonster__TokenNotTransferable();
        }
        super._update(_from, _to, _value);
    }
}
