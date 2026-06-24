// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IConfidentialCompliance} from "../../interfaces/IConfidentialCompliance.sol";

/**
 * @dev Permissive implementation of {IConfidentialCompliance} for testing purposes.
 *
 * `canTransfer` always returns true. All callback functions (`transferred`,
 * `created`, `destroyed`) are no-ops.
 */
contract ConfidentialComplianceMock is IConfidentialCompliance {
    /// @inheritdoc IConfidentialCompliance
    function canTransfer(address, address) external pure returns (bool) {
        return true;
    }

    /// @inheritdoc IConfidentialCompliance
    function transferred(address, address, euint256) external {}

    /// @inheritdoc IConfidentialCompliance
    function created(address, euint256) external {}

    /// @inheritdoc IConfidentialCompliance
    function destroyed(address, euint256) external {}
}
