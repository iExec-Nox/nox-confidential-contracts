// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Compliance interface for confidential ERC-3643 tokens.
 *
 * Enforces token-level compliance rules independent of individual investor
 * eligibility. The compliance module is called by the token contract to
 * validate transfer eligibility and update internal state after transfers,
 * mints, and burns.
 */
interface IConfidentialCompliance {
    /**
     * @dev Checks that the transfer is compliant.
     * Default compliance always returns true.
     * READ ONLY FUNCTION: this function cannot be used to increment
     * counters, emit events, etc.
     * This function will call all checks implemented on compliance.
     * If all checks return TRUE, the function returns TRUE, returns FALSE otherwise.
     * @param from the address of the sender.
     * @param to the address of the receiver.
     */
    function canTransfer(address from, address to) external view returns (bool);

    /**
     * @dev Function called whenever tokens are transferred from one wallet to another.
     * This function can be used to update state variables of the compliance contract.
     * This function can be called ONLY by the token contract bound to the compliance.
     * @param from the address of the sender.
     * @param to the address of the receiver.
     * @param amount the encrypted amount of tokens involved in the transfer.
     */
    function transferred(address from, address to, euint256 amount) external;

    /**
     * @dev Function called whenever tokens are created on a wallet.
     * This function can be used to update state variables of the compliance contract.
     * This function can be called ONLY by the token contract bound to the compliance.
     * @param to the address of the receiver.
     * @param amount the encrypted amount of tokens involved in the minting.
     */
    function created(address to, euint256 amount) external;

    /**
     * @dev Function called whenever tokens are destroyed from a wallet.
     * This function can be used to update state variables of the compliance contract.
     * This function can be called ONLY by the token contract bound to the compliance.
     * @param from the address on which tokens are burnt.
     * @param amount the encrypted amount of tokens involved in the burn.
     */
    function destroyed(address from, euint256 amount) external;
}
