// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {euint64, externalEuint64, ebool} from "encrypted-types/EncryptedTypes.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {Nox} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {TEEType} from "@iexec-nox/nox-protocol-contracts/contracts/shared/TypeUtils.sol";

/**
 * @dev Reference implementation for {IERC7984}.
 *
 * This contract implements a fungible token where balances and transfers are encrypted using the Nox TEE,
 * providing confidentiality to users. Token amounts are stored as encrypted, unsigned integers (`euint64`)
 * that can only be decrypted by authorized parties.
 *
 * Key features:
 *
 * - All balances are encrypted
 * - Transfers happen without revealing amounts
 * - Support for operators (delegated transfer capabilities with time bounds)
 * - Safe overflow/underflow handling for TEE operations
 *
 * @dev Uses {Nox.NOX_COMPUTE} and {Nox.ACL} directly for `euint64` operations, as the Nox
 *      library typed wrappers currently only cover `euint16` and `euint256`.
 *      transferAndCall variants are not yet implemented.
 */
abstract contract ERC7984 is IERC7984, ERC165, Ownable {
    mapping(address holder => euint64) private _balances;
    mapping(address holder => mapping(address spender => uint48 until)) private _operators;
    euint64 private _totalSupply;
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
    error ERC7984UnauthorizedUseOfEncryptedAmount(euint64 amount, address user);

    /// @dev The holder `holder` is trying to send tokens but has a balance of 0.
    error ERC7984ZeroBalance(address holder);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address owner_
    ) Ownable(owner_) {
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
    function confidentialTotalSupply() public view virtual returns (euint64) {
        return _totalSupply;
    }

    /// @inheritdoc IERC7984
    function confidentialBalanceOf(address account) public view virtual returns (euint64) {
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
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external virtual returns (euint64) {
        return _transfer(msg.sender, to, _fromExternal(encryptedAmount, inputProof));
    }

    /// @inheritdoc IERC7984
    function confidentialTransfer(address to, euint64 amount) external virtual returns (euint64) {
        require(
            Nox.ACL.isAllowed(euint64.unwrap(amount), msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        return _transfer(msg.sender, to, amount);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external virtual returns (euint64 transferred) {
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        transferred = _transfer(from, to, _fromExternal(encryptedAmount, inputProof));
        Nox.ACL.allowTransient(euint64.unwrap(transferred), msg.sender);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) external virtual returns (euint64 transferred) {
        require(
            Nox.ACL.isAllowed(euint64.unwrap(amount), msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        transferred = _transfer(from, to, amount);
        Nox.ACL.allowTransient(euint64.unwrap(transferred), msg.sender);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address,
        externalEuint64,
        bytes calldata,
        bytes calldata
    ) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address,
        euint64,
        bytes calldata
    ) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address,
        address,
        externalEuint64,
        bytes calldata,
        bytes calldata
    ) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address,
        address,
        euint64,
        bytes calldata
    ) external virtual returns (euint64) {}

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
    function _mint(address to, euint64 amount) internal returns (euint64) {
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
    function _burn(address from, euint64 amount) internal returns (euint64) {
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
    function _transfer(address from, address to, euint64 amount) internal returns (euint64) {
        require(from != address(0), ERC7984InvalidSender(address(0)));
        require(to != address(0), ERC7984InvalidReceiver(address(0)));
        return _update(from, to, amount);
    }

    /**
     * @dev Transfers `amount` from `from` to `to`, updating balances and total supply.
     * All customizations to transfers, mints, and burns should be done by overriding this function.
     *
     * - `from == address(0)` → mint: {Nox.NOX_COMPUTE.safeAdd} increases the total supply.
     * - `to == address(0)` → burn: {Nox.NOX_COMPUTE.sub} decreases the total supply.
     * - Both non-zero → transfer: {Nox.NOX_COMPUTE.safeSub} decreases sender balance, {Nox.NOX_COMPUTE.add} increases recipient balance.
     *
     * The actually transferred amount may be less than `amount` when the operation would overflow or underflow.
     * In that case success is false (encrypted) and the transferred amount is encrypted 0.
     *
     * Emits a {ConfidentialTransfer} event.
     */
    function _update(
        address from,
        address to,
        euint64 amount
    ) internal virtual returns (euint64 transferred) {
        ebool success;
        euint64 ptr;

        if (from == address(0)) {
            // Mint: safely increase total supply.
            (bytes32 s, bytes32 r) = Nox.NOX_COMPUTE.safeAdd(
                euint64.unwrap(_totalSupply),
                euint64.unwrap(amount)
            );
            success = ebool.wrap(s);
            ptr = euint64.wrap(r);
            Nox.ACL.allow(r, address(this));
            _totalSupply = ptr;
        } else {
            // Transfer/burn: safely decrease sender balance.
            euint64 fromBalance = _balances[from];
            require(euint64.unwrap(fromBalance) != 0, ERC7984ZeroBalance(from));
            (bytes32 s, bytes32 r) = Nox.NOX_COMPUTE.safeSub(
                euint64.unwrap(fromBalance),
                euint64.unwrap(amount)
            );
            success = ebool.wrap(s);
            ptr = euint64.wrap(r);
            Nox.ACL.allow(r, address(this));
            Nox.ACL.allow(r, from);
            _balances[from] = ptr;
        }

        euint64 zero = euint64.wrap(
            Nox.NOX_COMPUTE.plaintextToEncrypted(bytes32(0), TEEType.Uint64)
        );
        transferred = euint64.wrap(
            Nox.NOX_COMPUTE.select(
                ebool.unwrap(success),
                euint64.unwrap(amount),
                euint64.unwrap(zero)
            )
        );

        if (to == address(0)) {
            // Burn: decrease total supply by actually transferred amount.
            bytes32 newSupply = Nox.NOX_COMPUTE.sub(
                euint64.unwrap(_totalSupply),
                euint64.unwrap(transferred)
            );
            Nox.ACL.allow(newSupply, address(this));
            _totalSupply = euint64.wrap(newSupply);
        } else {
            // Mint/transfer: increase recipient balance by actually transferred amount.
            bytes32 newBalance = Nox.NOX_COMPUTE.add(
                euint64.unwrap(_balances[to]),
                euint64.unwrap(transferred)
            );
            Nox.ACL.allow(newBalance, address(this));
            Nox.ACL.allow(newBalance, to);
            _balances[to] = euint64.wrap(newBalance);
        }

        if (from != address(0)) Nox.ACL.allow(euint64.unwrap(transferred), from);
        if (to != address(0)) Nox.ACL.allow(euint64.unwrap(transferred), to);
        Nox.ACL.allow(euint64.unwrap(transferred), address(this));
        emit ConfidentialTransfer(from, to, transferred);
    }

    /**
     * @dev Validates and unwraps a user-supplied encrypted amount `externalHandle` using
     * the provided `handleProof`. The proof is verified against `msg.sender` by {Nox.NOX_COMPUTE}.
     *
     * NOTE: Equivalent to {FHE.fromExternal} in the fhEVM implementation, adapted for Nox TEE.
     */
    function _fromExternal(
        externalEuint64 externalHandle,
        bytes calldata handleProof
    ) internal returns (euint64) {
        bytes32 handle = externalEuint64.unwrap(externalHandle);
        Nox.NOX_COMPUTE.validateProof(handle, msg.sender, handleProof, TEEType.Uint64);
        return euint64.wrap(handle);
    }
}
