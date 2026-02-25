// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Nox, ebool, euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984Receiver} from "../../interfaces/IERC7984Receiver.sol";

/**
 * @dev Mock receiver that decodes a success boolean from `data` and returns it as an encrypted boolean.
 * Reverts with {InvalidInput} if the input is not 0 or 1.
 */
contract ERC7984ReceiverMock is IERC7984Receiver {
    event ConfidentialTransferCallback(bool success);

    error InvalidInput(uint8 input);

    /// @inheritdoc IERC7984Receiver
    /// @dev Data should contain a success boolean (plaintext). Revert if not.
    function onConfidentialTransferReceived(
        address,
        address,
        euint256,
        bytes calldata data
    ) external returns (ebool) {
        uint8 input = abi.decode(data, (uint8));

        if (input > 1) revert InvalidInput(input);

        bool success = input == 1;
        emit ConfidentialTransferCallback(success);

        ebool returnVal = Nox.toEbool(success);
        Nox.allowTransient(returnVal, msg.sender);

        return returnVal;
    }
}
