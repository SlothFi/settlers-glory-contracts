// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract MonStaking is OApp {

    constructor(address _endpoint,address _delegated) OApp(_endpoint, _delegated) Ownable(_delegated){

    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal override {

    }

}