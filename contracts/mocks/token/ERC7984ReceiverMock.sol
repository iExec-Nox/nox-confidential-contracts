// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (token/ERC721/utils/ERC721ReceiverMock.sol)
pragma solidity ^0.8.28;

import {Nox, ebool, euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984Receiver} from "../../interfaces/IERC7984Receiver.sol";

/**
 * @dev Mock receiver that decodes a success boolean from `data` and returns it as an encrypted boolean.
 * Reverts with {InvalidInput} if `success` is false.
 */
contract ERC7984ReceiverMock is IERC7984Receiver {
    event ConfidentialTransferCallback(bool success);
    error InvalidInput();

    /// @inheritdoc IERC7984Receiver
    /// @dev Data should contain a success boolean (plaintext). Revert if false.
    function onConfidentialTransferReceived(
        address,
        address,
        euint256,
        bytes calldata data
    ) external returns (ebool) {
        bool success = abi.decode(data, (bool));
        if (!success) {
            revert InvalidInput();
        }
        emit ConfidentialTransferCallback(success);
        ebool returnVal = Nox.toEbool(success);
        Nox.allowTransient(returnVal, msg.sender);
        return returnVal;
    }
}
