// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7984} from "../interfaces/IERC7984.sol";
import {
    Nox,
    euint256,
    externalEuint256,
    ebool
} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Reference implementation for {IERC7984}.
 *
 * This contract implements a fungible token where balances and transfers are encrypted using the Nox TEE,
 * providing confidentiality to users. Token amounts are stored as encrypted, unsigned integers (`euint256`)
 * that can only be decrypted by authorized parties.
 *
 * Key features:
 *
 * - All balances are encrypted
 * - Transfers happen without revealing amounts
 * - Support for operators (delegated transfer capabilities with time bounds)
 * - Safe overflow/underflow handling for TEE operations
 *
 */
abstract contract ERC7984 is IERC7984, ERC165 {
    mapping(address holder => euint256) private _balances;
    mapping(address holder => mapping(address spender => uint48 until)) private _operators;
    euint256 private _totalSupply;
    string private _name;
    string private _symbol;
    string private _contractURI;

    /// @dev The given receiver `receiver` is invalid for transfers.
    error ERC7984InvalidReceiver(address receiver);

    /// @dev The given sender `sender` is invalid for transfers.
    error ERC7984InvalidSender(address sender);

    /// @dev The given holder `holder` is not authorized to spend on behalf of `spender`.
    error ERC7984UnauthorizedSpender(address holder, address spender);

    /**
     * @dev The caller `user` does not have access to the encrypted amount `amount`.
     *
     * NOTE: Try using the equivalent transfer function with an input proof.
     */
    error ERC7984UnauthorizedUseOfEncryptedAmount(euint256 amount, address user);

    /// @dev The holder `holder` is trying to send tokens but has a balance of 0.
    error ERC7984ZeroBalance(address holder);

    constructor(string memory name_, string memory symbol_, string memory contractURI_) {
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
    }

    // ============ View Functions ============

    /// @inheritdoc ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC7984).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC7984
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC7984
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC7984
    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    /// @inheritdoc IERC7984
    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    /// @inheritdoc IERC7984
    function confidentialTotalSupply() public view virtual returns (euint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC7984
    function confidentialBalanceOf(address account) public view virtual returns (euint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC7984
    function isOperator(address holder, address spender) public view virtual returns (bool) {
        return holder == spender || block.timestamp <= _operators[holder][spender];
    }

    // ============ External Functions ============

    /// @inheritdoc IERC7984
    function setOperator(address operator, uint48 until) public virtual {
        _setOperator(msg.sender, operator, until);
    }

    // ============ Transfer Functions ============

    /// @inheritdoc IERC7984
    function confidentialTransfer(
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint256) {
        return _transfer(msg.sender, to, Nox.fromExternal(encryptedAmount, inputProof));
    }

    /// @inheritdoc IERC7984
    function confidentialTransfer(address to, euint256 amount) public virtual returns (euint256) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        return _transfer(msg.sender, to, amount);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint256) {
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        euint256 transferred = _transfer(from, to, Nox.fromExternal(encryptedAmount, inputProof));
        Nox.allowTransient(transferred, msg.sender);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        euint256 amount
    ) public virtual returns (euint256) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        euint256 transferred = _transfer(from, to, amount);
        Nox.allowTransient(transferred, msg.sender);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address,
        externalEuint256,
        bytes calldata,
        bytes calldata
    ) public virtual returns (euint256) {}

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address,
        euint256,
        bytes calldata
    ) public virtual returns (euint256) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address,
        address,
        externalEuint256,
        bytes calldata,
        bytes calldata
    ) public virtual returns (euint256) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address,
        address,
        euint256,
        bytes calldata
    ) public virtual returns (euint256) {}

    // ============ Internal Functions ============

    function _setOperator(address holder, address operator, uint48 until) internal virtual {
        _operators[holder][operator] = until;
        emit OperatorSet(holder, operator, until);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `to`, updating the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {ConfidentialTransfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual. Override {_update} to customize token creation.
     */
    function _mint(address to, euint256 amount) internal returns (euint256) {
        require(to != address(0), ERC7984InvalidReceiver(address(0)));
        return _update(address(0), to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `from`, reducing the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {ConfidentialTransfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual. Override {_update} to customize token destruction.
     */
    function _burn(address from, euint256 amount) internal returns (euint256) {
        require(from != address(0), ERC7984InvalidSender(address(0)));
        return _update(from, address(0), amount);
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to`.
     * Relies on the `_update` mechanism.
     *
     * Emits a {ConfidentialTransfer} event.
     *
     * NOTE: This function is not virtual. Override {_update} to customize token transfers.
     */
    function _transfer(address from, address to, euint256 amount) internal returns (euint256) {
        require(from != address(0), ERC7984InvalidSender(address(0)));
        require(to != address(0), ERC7984InvalidReceiver(address(0)));
        return _update(from, to, amount);
    }

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
    ) internal virtual returns (euint256 transferred) {
        ebool success;
        euint256 ptr;

        if (from == address(0)) {
            // Mint: safely increase total supply.
            (success, ptr) = Nox.safeAdd(_totalSupply, amount);
            Nox.allowThis(ptr);
            _totalSupply = ptr;
        } else {
            // Transfer/burn: safely decrease sender balance.
            euint256 fromBalance = _balances[from];
            require(Nox.isInitialized(fromBalance), ERC7984ZeroBalance(from));
            (success, ptr) = Nox.safeSub(fromBalance, amount);
            Nox.allowThis(ptr);
            Nox.allow(ptr, from);
            _balances[from] = ptr;
        }

        transferred = Nox.select(success, amount, Nox.toEuint256(0));

        if (to == address(0)) {
            // Burn: decrease total supply by actually transferred amount.
            ptr = Nox.sub(_totalSupply, transferred);
            Nox.allowThis(ptr);
            _totalSupply = ptr;
        } else {
            // Mint/transfer: increase recipient balance by actually transferred amount.
            ptr = Nox.add(_balances[to], transferred);
            Nox.allowThis(ptr);
            Nox.allow(ptr, to);
            _balances[to] = ptr;
        }

        if (from != address(0)) Nox.allow(transferred, from);
        if (to != address(0)) Nox.allow(transferred, to);
        Nox.allowThis(transferred);
        emit ConfidentialTransfer(from, to, transferred);
    }
}
