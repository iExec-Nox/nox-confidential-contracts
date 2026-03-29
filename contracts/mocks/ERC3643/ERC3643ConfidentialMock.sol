// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC3643Confidential} from "../../interfaces/IERC3643Confidential.sol";
import {ERC3643Confidential} from "../../token/ERC3643Confidential.sol";

/**
 * @dev Test-only interface that extends {IERC3643Confidential} with
 * an unrestricted `transfer` function for direct internal transfers.
 */
interface IERC3643ConfidentialTestableMock is IERC3643Confidential {
    /**
     * @dev Transfers `amount` from `from` to `to` by calling `_transfer` directly,
     * bypassing agent, compliance, pause, and freeze checks. Test-only.
     */
    function transfer(address from, address to, euint256 amount) external returns (euint256);
}

/**
 * @dev Implementation of {ERC3643Confidential} for testing purposes.
 *
 * Exposes an unrestricted `transfer(from, to, amount)` that calls the internal
 * `_transfer` directly, allowing tests to set up balances and move tokens
 * without requiring agent roles or passing compliance/identity checks.
 */
contract ERC3643ConfidentialMock is IERC3643ConfidentialTestableMock, ERC3643Confidential {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address identityRegistry_,
        address compliance_,
        address onchainID_
    )
        ERC3643Confidential(
            name_,
            symbol_,
            contractURI_,
            identityRegistry_,
            compliance_,
            onchainID_
        )
    {}

    /// @inheritdoc IERC3643ConfidentialTestableMock
    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}
