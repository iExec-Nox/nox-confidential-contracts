// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (token/ERC20/ERC20.sol)
pragma solidity ^0.8.28;

import {
    Nox,
    euint256,
    externalEuint256,
    ebool
} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984} from "./ERC7984.sol";

// Find a better name for this contract.
/**
 * @dev Reference implementation for {ERC7984} using advanced Nox primitives.
 * @dev See {ERC7984}.
 */
abstract contract ERC7984Advanced is ERC7984 {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984(name, symbol, contractURI) {}

    /**
     * @dev Transfers `amount` from `from` to `to`, updating balances and total supply.
     * All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * - `from == address(0)` → mint: {Nox.mint} updates recipient balance and total supply.
     *   If total supply is uninitialized, it is initialized to `amount` and success is true.
     * - `to == address(0)` → burn: {Nox.burn} updates sender balance and total supply.
     * - Both non-zero → transfer: {Nox.transfer} updates sender and recipient balances.
     *
     * For mint/transfer, an uninitialized recipient balance is treated as encrypted 0.
     * For burn/transfer, the sender balance must be initialized.
     *
     * The actually transferred amount may be less than `amount` when the operation would overflow or underflow.
     * In that case success is false (encrypted) and the transferred amount is encrypted 0.
     *
     * Emits a {ConfidentialTransfer} event.
     */
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        ebool success;

        // Mint
        if (from == address(0)) {
            euint256 newToBalance;
            euint256 newTotalSupply;
            if (!Nox.isInitialized(_totalSupply)) {
                success = Nox.toEbool(true);
                newToBalance = amount;
                newTotalSupply = amount;
            } else {
                euint256 toBalance = _balances[to];
                if (!Nox.isInitialized(toBalance)) {
                    toBalance = Nox.toEuint256(0);
                }
                (success, newToBalance, newTotalSupply) = Nox.mint(toBalance, amount, _totalSupply);
            }
            _balances[to] = newToBalance;
            _totalSupply = newTotalSupply;
            Nox.allowThis(newToBalance);
            Nox.allow(newToBalance, to);
        }

        // Burn
        if (to == address(0)) {
            euint256 fromBalance = _balances[from];
            euint256 newFromBalance;
            euint256 newTotalSupply;
            require(Nox.isInitialized(fromBalance), ERC7984ZeroBalance(from));
            (success, newFromBalance, newTotalSupply) = Nox.burn(fromBalance, amount, _totalSupply);
            _totalSupply = newTotalSupply;
            _balances[from] = newFromBalance;
            Nox.allowThis(newFromBalance);
            Nox.allow(newFromBalance, from);
        }

        // Transfer
        if (from != address(0) && to != address(0)) {
            euint256 fromBalance = _balances[from];
            euint256 toBalance = _balances[to];
            euint256 newFromBalance;
            euint256 newToBalance;
            require(Nox.isInitialized(fromBalance), ERC7984ZeroBalance(from));
            toBalance = Nox.isInitialized(toBalance) ? toBalance : Nox.toEuint256(0);
            (success, newFromBalance, newToBalance) = Nox.transfer(fromBalance, toBalance, amount);
            _balances[from] = newFromBalance;
            _balances[to] = newToBalance;
            Nox.allowThis(newFromBalance);
            Nox.allow(newFromBalance, from);
            Nox.allowThis(newToBalance);
            Nox.allow(newToBalance, to);
        }

        transferred = Nox.select(success, amount, Nox.toEuint256(0));
        emit ConfidentialTransfer(from, to, transferred);
    }
}
