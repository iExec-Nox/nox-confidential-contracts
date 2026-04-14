// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Nox, euint256, ebool} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Base} from "./ERC7984Base.sol";

/**
 * @dev Reference implementation for {ERC7984} using "basic" Nox primitives.
 */
abstract contract ERC7984BasicPrimitives is ERC7984Base {
    /**
     * @dev Transfers `amount` from `from` to `to`, updating balances and total supply.
     * All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * - `from == address(0)` → mint: {Nox.safeAdd} increases the total supply.
     * - `to == address(0)` → burn: {Nox.sub} decreases the total supply.
     * - Both non-zero → transfer: {Nox.safeSub} decreases sender balance, {Nox.add} increases recipient balance.
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
        ERC7984Storage storage $ = _getERC7984Storage();
        ebool success;
        euint256 ptr;

        if (from == address(0)) {
            // Mint: safely increase total supply.
            (success, ptr) = Nox.safeAdd($._totalSupply, amount);
            ptr = Nox.select(success, ptr, $._totalSupply);
            Nox.allowThis(ptr);
            $._totalSupply = ptr;
        } else {
            // Transfer/burn: safely decrease sender balance.
            euint256 fromBalance = $._balances[from];
            require(Nox.isInitialized(fromBalance), ERC7984ZeroBalance(from));
            (success, ptr) = Nox.safeSub(fromBalance, amount);
            ptr = Nox.select(success, ptr, fromBalance);
            Nox.allowThis(ptr);
            Nox.allow(ptr, from);
            $._balances[from] = ptr;
        }

        transferred = Nox.select(success, amount, Nox.toEuint256(0));

        if (to == address(0)) {
            // Burn: decrease total supply by actually transferred amount.
            ptr = Nox.sub($._totalSupply, transferred);
            Nox.allowThis(ptr);
            $._totalSupply = ptr;
        } else {
            // Mint/transfer: increase recipient balance by actually transferred amount.
            ptr = Nox.add($._balances[to], transferred);
            Nox.allowThis(ptr);
            Nox.allow(ptr, to);
            $._balances[to] = ptr;
        }

        if (from != address(0)) {
            Nox.allow(transferred, from);
        }
        if (to != address(0)) {
            Nox.allow(transferred, to);
        }
        Nox.allowThis(transferred);
        emit ConfidentialTransfer(from, to, transferred);
    }
}
