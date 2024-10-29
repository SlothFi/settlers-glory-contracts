// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IMonStaking} from "./interfaces/IMonStaking.sol";


/**
 * @title LiquidStakedMonster
 * @dev LiquidStakedMonster is an ERC20 token that represents the staked MON tokens in the staking contract.
 * @dev The token is minted when MON tokens are staked and burned when MON tokens are unstaked.
 * @dev The token is not transferable except to the market place address.
 */
contract LiquidStakedMonster is ERC20, AccessControl {

    /// @dev Throws if the markeplace is address(0).
    error LiquidStakedMonster__InvalidMarketPlace();

    /// @dev Throws if the operator role is address(0).
    error LiquidStakedMonster__InvalidOperatorRole();

    /// @dev Throws if the default admin role is address(0).
    error LiquidStakedMonster__InvalidDefaultAdminRole();

    /// @dev Throws if the amount is 0.
    error LiquidStakedMonster__NoZeroAmount();

    /// @dev Throws if the address is address(0).
    error LiquidStakedMonster__NoZeroAddress();

    /// @dev Throws if a user tries to transfer the token to any other address.
    error LiquidStakedMonster__TokenNotTransferable();

    /**
    * @dev Emitted when the token is minted.
    * @param to The address to which the token is minted.
    * @param amount The amount of token minted.
    */
    event Minted(address indexed to, uint256 indexed amount);

    /**
    * @dev Emitted when the token is burned.
    * @param from The address from which the token is burned.
    * @param amount The amount of token burned.
    */
    event Burned(address indexed from, uint256 indexed amount);

    /**
    * @dev Emitted when the market place address is changed.
    * @param oldMarketPlace The old market place address.
    * @param newMarketPlace The new market place address.
    */
    event MarketPlaceChanged(address indexed oldMarketPlace, address indexed newMarketPlace);

    /// @dev The CONTROLLER_ROLE is the role that can mint and burn the token.
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    /// @dev The OPERATOR_ROLE is the role that can change the market place address.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev The market place address.
    address public s_marketPlace;

    /// @dev The staking contract address.
    IMonStaking public immutable i_stakingContract;

    /**
    * @dev Constructor to initialize the LiquidStakedMonster contract.
    * @param _operatorRole The address of the operator role.
    * @param _defaultAdmin The address of the default admin role.
    * @param _marketPlace The address of the market place.
    * @dev It is deployed by the staking contract.
    */
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

    /**
    * @dev Mint the token to the given address.
    * @param _to The address to which the token is minted.
    * @param _amount The amount of token to mint.
    * @dev Only the controller role can mint the token.
    */
    function mint(address _to, uint256 _amount) external onlyRole(CONTROLLER_ROLE) {
        if (_to == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        if (_amount == 0) revert LiquidStakedMonster__NoZeroAmount();

        _mint(_to, _amount);

        emit Minted(_to, _amount);
    }

    /**
    * @dev Burn the token from the given address.
    * @param _from The address from which the token is burned.
    * @param _amount The amount of token to burn.
    * @dev Only the controller role can burn the token.
    */
    function burn(address _from, uint256 _amount) external onlyRole(CONTROLLER_ROLE) {
        if (_from == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        if (_amount == 0) revert LiquidStakedMonster__NoZeroAmount();

        _burn(_from, _amount);

        emit Burned(_from, _amount);
    }

    /**
    * @dev Transfer the token to the given address.
    * @param _value The amount of token to transfer.
    * @param _to The address to which the token is transferred.
    * @dev Only the market place address can receive the token.
    * @dev It payable to update the staking balance in the staking contract if premium user total balance is spent
    */
    function transfer(uint256 _value, address _to) public payable returns (bool) {
        if (_to == s_marketPlace) i_stakingContract.updateStakingBalance{value: msg.value}(msg.sender, _to, _value);

        return transfer(_to, _value);
    }

    /**
    * @dev Transfer the token from the given address to the given address.
    * @param _value The amount of token to transfer.
    * @param _from The address from which the token is transferred.
    * @param _to The address to which the token is transferred.
    * @dev Only the market place address can receive the token.
    * @dev It payable to update the staking balance in the staking contract if premium user total balance is spent
    */
    function transferFrom(uint256 _value, address _from, address _to) public payable returns (bool) {
        if (_from == s_marketPlace) i_stakingContract.updateStakingBalance{value: msg.value}(_from, _to, _value);

        return transferFrom(_from, _to, _value);
    }

    /**
    * @dev Set the market place address.
    * @param _marketPlace The address of the market place.
    * @dev Only the operator role can set the market place address.
    */
    function setMarketPlace(address _marketPlace) external onlyRole(OPERATOR_ROLE) {
        if (_marketPlace == address(0)) revert LiquidStakedMonster__NoZeroAddress();
        address oldMarketPlace = s_marketPlace;
        s_marketPlace = _marketPlace;
        emit MarketPlaceChanged(oldMarketPlace, _marketPlace);
    }

    /**
    * @dev Internal function to update the token balance.
    * @param _from The address from which the token is transferred.
    * @param _to The address to which the token is transferred.
    * @param _value The amount of token to transfer.
    * @dev It reverts if the token is transferred to any address other than the market place address.
    */
    function _update(address _from, address _to, uint256 _value) internal override {
        if (_from != address(0) && (_to != address(0) && _to != s_marketPlace)) {
            revert LiquidStakedMonster__TokenNotTransferable();
        }
        super._update(_from, _to, _value);
    }
}
