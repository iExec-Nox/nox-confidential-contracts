// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {euint64, externalEuint64} from "encrypted-types/EncryptedTypes.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";

/**
 * @title ERC7984
 * @notice Confidential fungible token implementing ERC-7984 with Nox TEE infrastructure.
 */
abstract contract ERC7984 is IERC7984, ERC165, Ownable {
    mapping(address holder => euint64) private _balances;
    mapping(address holder => mapping(address spender => uint48)) private _operators;
    euint64 private _totalSupply;
    string private _name;
    string private _symbol;
    string private _contractURI;

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

    // ============ Transfer Functions (TODO: implement with Nox lib) ============

    /// @inheritdoc IERC7984
    function confidentialTransfer(
        address,
        externalEuint64,
        bytes calldata
    ) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransfer(address, euint64) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address,
        address,
        externalEuint64,
        bytes calldata
    ) external virtual returns (euint64) {}

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address,
        address,
        euint64
    ) external virtual returns (euint64) {}

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
}
