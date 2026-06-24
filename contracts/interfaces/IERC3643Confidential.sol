// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256, externalEuint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "./IERC7984.sol";
import {IIdentityRegistry} from "./IIdentityRegistry.sol";
import {IConfidentialCompliance} from "./IConfidentialCompliance.sol";

/**
 * @dev Interface for a confidential ERC-3643 (T-REX) security token.
 *
 * Extends {IERC7984} with compliance, identity verification, freeze, pause,
 * agent roles, forced transfers, and wallet recovery as specified in ERC-3643.
 * All token amounts are encrypted using `euint256` for full confidentiality.
 *
 * NOTE: `owner()`, `transferOwnership()`, and `paused()` are NOT declared here.
 * They are inherited from OZ {Ownable} and {Pausable} by the implementing contract.
 */
interface IERC3643Confidential is IERC7984 {
    // ============ Events ============

    /**
     * @dev Emitted when the Identity Registry has been set for the token.
     * Emitted by the constructor and by {setIdentityRegistry}.
     * @param identityRegistry the address of the Identity Registry of the token.
     */
    event IdentityRegistryAdded(address indexed identityRegistry);

    /**
     * @dev Emitted when the Compliance contract has been set for the token.
     * Emitted by the constructor and by {setCompliance}.
     * @param compliance the address of the Compliance contract of the token.
     */
    event ComplianceAdded(address indexed compliance);

    /**
     * @dev Emitted when an investor successfully recovers tokens from a lost wallet.
     * Emitted by {recoveryAddress}.
     * @param lostWallet the address of the wallet that the investor lost access to.
     * @param newWallet the address of the wallet provided for the recovery.
     * @param investorOnchainID the address of the onchainID of the investor who asked for a recovery.
     */
    event RecoverySuccess(address lostWallet, address newWallet, address investorOnchainID);

    /**
     * @dev Emitted when the wallet of an investor is frozen or unfrozen.
     * Emitted by {setAddressFrozen}.
     * If `isFrozen` is `true` the wallet is frozen after emission of the event.
     * If `isFrozen` is `false` the wallet is unfrozen after emission of the event.
     * @param account the wallet of the investor concerned by the freezing status.
     * @param isFrozen the new freezing status of the wallet.
     * @param agent the address of the agent who called the function.
     */
    event AddressFrozen(address indexed account, bool indexed isFrozen, address indexed agent);

    /**
     * @dev Emitted when a certain amount of tokens is frozen on a wallet.
     * Emitted by {freezePartialTokens}.
     * @param account the wallet of the investor concerned by the partial freeze.
     * @param amount the encrypted amount of tokens that are frozen.
     */
    event TokensFrozen(address indexed account, euint256 amount);

    /**
     * @dev Emitted when a certain amount of tokens is unfrozen on a wallet.
     * Emitted by {unfreezePartialTokens}.
     * @param account the wallet of the investor concerned by the partial unfreeze.
     * @param amount the encrypted amount of tokens that are unfrozen.
     */
    event TokensUnfrozen(address indexed account, euint256 amount);

    // NOTE: Paused(address) and Unpaused(address) events are inherited from OZ Pausable.

    /**
     * @dev Emitted when an agent is added.
     * @param agent the address of the new agent.
     */
    event AgentAdded(address indexed agent);

    /**
     * @dev Emitted when an agent is removed.
     * @param agent the address of the removed agent.
     */
    event AgentRemoved(address indexed agent);

    // ============ Errors ============

    /// @dev The wallet `account` is frozen.
    error ERC3643WalletFrozen(address account);

    /// @dev The address `account` is not verified in the identity registry.
    error ERC3643NotVerified(address account);

    /// @dev The transfer is not compliant.
    error ERC3643TransferNotCompliant(address from, address to);

    /// @dev The caller is not an authorized agent.
    error ERC3643UnauthorizedAgent(address caller);

    // ============ Getters ============

    /**
     * @dev Returns the address of the onchainID of the token.
     * The onchainID of the token gives all the information available
     * about the token and is managed by the token issuer or their agent.
     */
    function onchainID() external view returns (address);

    /**
     * @dev Returns the version of the token.
     * Current version is 1.0.0.
     */
    function version() external pure returns (string memory);

    /**
     * @dev Returns the Identity Registry linked to the token.
     */
    function identityRegistry() external view returns (IIdentityRegistry);

    /**
     * @dev Returns the Compliance contract linked to the token.
     */
    function compliance() external view returns (IConfidentialCompliance);

    /**
     * @dev Returns the freezing status of a wallet.
     * If returns `true` the wallet is frozen.
     * If returns `false` the wallet is not frozen.
     * A frozen wallet returning `true` does not mean that the balance is free:
     * tokens could be blocked by a partial freeze or the whole token could be paused.
     * @param account the address of the wallet to check.
     */
    function isFrozen(address account) external view returns (bool);

    /**
     * @dev Returns the encrypted amount of tokens that are partially frozen on a wallet.
     * The amount of frozen tokens is always <= to the total balance of the wallet.
     * @param account the address of the wallet to check.
     */
    function getFrozenTokens(address account) external view returns (euint256);

    // ============ Agent Role ============

    /**
     * @dev Returns true if `account` is an authorized agent.
     * @param account the address to check.
     */
    function isAgent(address account) external view returns (bool);

    /**
     * @dev Adds `agent` as an authorized agent.
     * Only the owner of the token smart contract can call this function.
     * Emits an {AgentAdded} event.
     * @param agent the address to add as agent.
     */
    function addAgent(address agent) external;

    /**
     * @dev Removes `agent` from authorized agents.
     * Only the owner of the token smart contract can call this function.
     * Emits an {AgentRemoved} event.
     * @param agent the address to remove from agents.
     */
    function removeAgent(address agent) external;

    // ============ Token Operations (Agent Only) ============

    /**
     * @dev Mints tokens to a verified wallet.
     * Tokens can be minted to an address only if it is a verified address
     * as per the Identity Registry linked to the token.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {ConfidentialTransfer} event.
     * @param to address to mint the tokens to.
     * @param amount encrypted amount of tokens to mint.
     * @return the encrypted amount actually minted.
     */
    function mint(address to, euint256 amount) external returns (euint256);

    /**
     * @dev Mints tokens to a verified wallet using an external encrypted amount with proof.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {ConfidentialTransfer} event.
     * @param to address to mint the tokens to.
     * @param amount external encrypted amount of tokens to mint.
     * @param proof the input proof for the encrypted amount.
     * @return the encrypted amount actually minted.
     */
    function mint(
        address to,
        externalEuint256 amount,
        bytes calldata proof
    ) external returns (euint256);

    /**
     * @dev Burns tokens from a wallet.
     * If the `from` address has not enough free tokens (unfrozen tokens)
     * but has a total balance higher or equal to the `amount`,
     * the amount of frozen tokens is reduced in order to proceed the burn.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {ConfidentialTransfer} event.
     * @param from address to burn the tokens from.
     * @param amount encrypted amount of tokens to burn.
     * @return the encrypted amount actually burned.
     */
    function burn(address from, euint256 amount) external returns (euint256);

    /**
     * @dev Forces a transfer of tokens between 2 wallets, bypassing compliance and freeze checks.
     * If the `from` address has not enough free tokens (unfrozen tokens)
     * but has a total balance higher or equal to the `amount`,
     * the frozen tokens are included in the transfer.
     * Requires that the `to` address is a verified address.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {ConfidentialTransfer} event.
     * @param from the address of the sender.
     * @param to the address of the receiver.
     * @param amount the encrypted number of tokens to transfer.
     * @return the encrypted amount actually transferred.
     */
    function forcedTransfer(address from, address to, euint256 amount) external returns (euint256);

    // ============ Freeze Operations (Agent Only) ============

    /**
     * @dev Sets a frozen status for a wallet.
     * This function can only be called by a wallet set as agent of the token.
     * Emits an {AddressFrozen} event.
     * @param account the address for which to update the frozen status.
     * @param frozen the new frozen status of the address.
     */
    function setAddressFrozen(address account, bool frozen) external;

    /**
     * @dev Freezes an encrypted token amount for a given address.
     * The frozen amount is added to any previously frozen amount.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {TokensFrozen} event.
     * @param account the address on which tokens need to be frozen.
     * @param amount the encrypted amount of tokens to freeze.
     */
    function freezePartialTokens(address account, euint256 amount) external;

    /**
     * @dev Unfreezes an encrypted token amount for a given address.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {TokensUnfrozen} event.
     * @param account the address on which tokens need to be unfrozen.
     * @param amount the encrypted amount of tokens to unfreeze.
     */
    function unfreezePartialTokens(address account, euint256 amount) external;

    // ============ Pause (Agent Only) ============

    /**
     * @dev Pauses the token contract. When paused, investors cannot transfer tokens.
     * This function can only be called by a wallet set as agent of the token.
     * Emits a {Paused} event.
     */
    function pause() external;

    /**
     * @dev Unpauses the token contract. When unpaused, investors can transfer tokens
     * if their wallet is not frozen and the amount to transfer is <= to their free balance.
     * This function can only be called by a wallet set as agent of the token.
     * Emits an {Unpaused} event.
     */
    function unpause() external;

    // ============ Admin (Owner Only) ============

    /**
     * @dev Sets the Identity Registry for the token.
     * Only the owner of the token smart contract can call this function.
     * Emits an {IdentityRegistryAdded} event.
     * @param registry the address of the Identity Registry to set.
     */
    function setIdentityRegistry(address registry) external;

    /**
     * @dev Sets the Compliance contract of the token.
     * Only the owner of the token smart contract can call this function.
     * Emits a {ComplianceAdded} event.
     * @param complianceContract the address of the Compliance contract to set.
     */
    function setCompliance(address complianceContract) external;

    /**
     * @dev Sets the onchainID of the token.
     * Only the owner of the token smart contract can call this function.
     * @param id the address of the onchainID to set.
     */
    function setOnchainID(address id) external;

    /**
     * @dev Recovery function used to force transfer tokens from a
     * lost wallet to a new wallet for an investor.
     * Only the owner of the token smart contract can call this function.
     * Emits a {RecoverySuccess} event if the recovery is successful.
     * @param lostWallet the wallet that the investor lost access to.
     * @param newWallet the newly provided wallet on which tokens have to be transferred.
     * @param investorOnchainID the onchainID of the investor asking for a recovery.
     * @return `true` if the recovery is successful.
     */
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        address investorOnchainID
    ) external returns (bool);
}
