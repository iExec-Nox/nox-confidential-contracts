// SPDX-License-Identifier: Apache-2.0
// Inspired by OpenZeppelin Confidential Contracts (token/ERC7984/extensions/ERC7984ERC20Wrapper.sol)
pragma solidity ^0.8.28;

import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {
    Nox,
    euint256,
    externalEuint256
} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "../../interfaces/IERC7984.sol";
import {IERC7984ERC20Wrapper} from "../../interfaces/IERC7984ERC20Wrapper.sol";
import {ERC7984} from "../ERC7984.sol";

/**
 * @dev Extension of {ERC7984} that wraps an ERC-20 token into a confidential ERC-7984 token.
 * Implements {IERC1363Receiver} so users can wrap via direct ERC-1363 transfers.
 *
 * The wrapped token uses the same decimals as the underlying ERC-20 (1:1 conversion).
 *
 * WARNING: Fee-on-transfer or deflationary tokens are not supported.
 */
abstract contract ERC7984ERC20Wrapper is ERC7984, IERC7984ERC20Wrapper, IERC1363Receiver {
    IERC20 private immutable _underlying;
    uint8 private immutable _decimals;

    mapping(euint256 unwrapAmount => address recipient) private _unwrapRequests;

    event UnwrapRequested(address indexed receiver, euint256 amount);
    event UnwrapFinalized(
        address indexed receiver,
        euint256 encryptedAmount,
        uint256 cleartextAmount
    );

    error ERC7984UnauthorizedCaller(address caller);
    error InvalidUnwrapRequest(euint256 amount);
    error ERC7984TotalSupplyOverflow();

    constructor(IERC20 underlying_) {
        _underlying = underlying_;
        _decimals = _tryGetAssetDecimals(underlying_);
    }

    // ============ External Functions ============

    /**
     * @dev ERC-1363 callback: wraps received tokens to the address in `data` (or `from` if empty).
     */
    function onTransferReceived(
        address /*operator*/,
        address from,
        uint256 amount,
        bytes calldata data
    ) public virtual returns (bytes4) {
        require(underlying() == msg.sender, ERC7984UnauthorizedCaller(msg.sender));
        address to = data.length < 20 ? from : address(bytes20(data));
        _mint(to, Nox.toEuint256(amount));
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /// @inheritdoc IERC7984ERC20Wrapper
    function wrap(address to, uint256 amount) public virtual override returns (euint256) {
        SafeERC20.safeTransferFrom(IERC20(underlying()), msg.sender, address(this), amount);
        euint256 wrappedAmount = _mint(to, Nox.toEuint256(amount));
        Nox.allowTransient(wrappedAmount, msg.sender);
        return wrappedAmount;
    }

    /// @dev Unwrap without an input proof. Caller must already be allowed by ACL for `amount`.
    function unwrap(address from, address to, euint256 amount) public virtual returns (euint256) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        return _unwrap(from, to, amount);
    }

    /// @inheritdoc IERC7984ERC20Wrapper
    function unwrap(
        address from,
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint256) {
        return _unwrap(from, to, Nox.fromExternal(encryptedAmount, inputProof));
    }

    // TODO: Implement finalizeUnwrap once Nox exposes a decryption verification mechanism
    // (equivalent to FHE.checkSignatures in FHEVM) to trustlessly verify `unwrapAmountCleartext`
    // against the encrypted `unwrapAmount` before releasing underlying tokens.

    // ============ View Functions ============

    /// @inheritdoc ERC7984
    function decimals() public view virtual override(IERC7984, ERC7984) returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC7984ERC20Wrapper
    function underlying() public view virtual override returns (address) {
        return address(_underlying);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC7984) returns (bool) {
        return
            interfaceId == type(IERC7984ERC20Wrapper).interfaceId ||
            interfaceId == type(IERC1363Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `balanceOf(address(this))`. Greater than or equal to the actual
     * {confidentialTotalSupply}. Can be inflated by directly sending underlying tokens to this contract.
     */
    function inferredTotalSupply() public view virtual returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @dev Returns the maximum total supply of wrapped tokens.
    function maxTotalSupply() public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @dev Returns the recipient of the pending unwrap request for `unwrapAmount`, or `address(0)`.
    function unwrapRequester(euint256 unwrapAmount) public view virtual returns (address) {
        return _unwrapRequests[unwrapAmount];
    }

    // ============ Internal Functions ============

    function _checkConfidentialTotalSupply() internal virtual {
        if (inferredTotalSupply() > maxTotalSupply()) revert ERC7984TotalSupplyOverflow();
    }

    /// @inheritdoc ERC7984
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256) {
        if (from == address(0)) _checkConfidentialTotalSupply();
        return super._update(from, to, amount);
    }

    /// @dev Burns `amount` from `from`, marks the result publicly decryptable, and records the unwrap request.
    function _unwrap(
        address from,
        address to,
        euint256 amount
    ) internal virtual returns (euint256) {
        require(to != address(0), ERC7984InvalidReceiver(to));
        require(
            from == msg.sender || isOperator(from, msg.sender),
            ERC7984UnauthorizedSpender(from, msg.sender)
        );
        euint256 unwrapAmount = _burn(from, amount);
        Nox.allowPublicDecryption(unwrapAmount);
        assert(unwrapRequester(unwrapAmount) == address(0));
        _unwrapRequests[unwrapAmount] = to;
        emit UnwrapRequested(to, unwrapAmount);
        return unwrapAmount;
    }

    /// @dev Default decimals when the underlying ERC-20 does not expose {IERC20Metadata.decimals}.
    function _fallbackUnderlyingDecimals() internal pure virtual returns (uint8) {
        return 18;
    }

    function _tryGetAssetDecimals(IERC20 asset_) private view returns (uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length == 32) return abi.decode(encodedDecimals, (uint8));
        return _fallbackUnderlyingDecimals();
    }
}
