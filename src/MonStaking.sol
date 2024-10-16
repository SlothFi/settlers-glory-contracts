// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract MonStaking is OApp {

    constructor(address _endpoint,address _delegated) OApp(_endpoint, _delegated) Ownable(_delegated){

    }

}