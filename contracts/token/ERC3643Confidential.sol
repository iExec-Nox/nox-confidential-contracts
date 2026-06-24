// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC7984} from "../interfaces/IERC7984.sol";
import {IERC3643Confidential} from "../interfaces/IERC3643Confidential.sol";
import {IIdentityRegistry} from "../interfaces/IIdentityRegistry.sol";
import {IConfidentialCompliance} from "../interfaces/IConfidentialCompliance.sol";
import {ERC7984} from "./ERC7984.sol";
import {ERC7984Advanced} from "./ERC7984Advanced.sol";
import {
    Nox,
    euint256,
    externalEuint256,
    ebool
} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Confidential implementation of the ERC-3643 (T-REX) security token standard.
 *
 * Extends {ERC7984Advanced} with identity verification, compliance enforcement, wallet freezing,
 * partial token freezing, pause mechanism, agent roles, forced transfers, and wallet recovery.
 *
 */
abstract contract ERC3643Confidential is IERC3643Confidential, ERC7984Advanced, Ownable, Pausable {
    IIdentityRegistry private _identityRegistry;
    IConfidentialCompliance private _compliance;
    address private _onchainID;

    mapping(address account => bool) private _frozenAccounts;

    mapping(address account => euint256) private _frozenTokens;
    mapping(address account => bool) private _agents;

    modifier onlyAgent() {
        require(_agents[_msgSender()], ERC3643UnauthorizedAgent(_msgSender()));
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address identityRegistry_,
        address compliance_,
        address onchainID_
    ) ERC7984Advanced(name_, symbol_, contractURI_) Ownable(_msgSender()) {
        _identityRegistry = IIdentityRegistry(identityRegistry_);
        _compliance = IConfidentialCompliance(compliance_);
        _onchainID = onchainID_;
    }

    // ============ View Functions ============

    /// @inheritdoc ERC7984
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC7984) returns (bool) {
        return
            interfaceId == type(IERC3643Confidential).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC3643Confidential
    function onchainID() public view virtual returns (address) {
        return _onchainID;
    }

    /// @inheritdoc IERC3643Confidential
    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc IERC3643Confidential
    function identityRegistry() public view virtual returns (IIdentityRegistry) {
        return _identityRegistry;
    }

    /// @inheritdoc IERC3643Confidential
    function compliance() public view virtual returns (IConfidentialCompliance) {
        return _compliance;
    }

    /// @inheritdoc IERC3643Confidential
    function isFrozen(address account) public view virtual returns (bool) {
        return _frozenAccounts[account];
    }

    /// @inheritdoc IERC3643Confidential
    function getFrozenTokens(address account) public view virtual returns (euint256) {
        return _frozenTokens[account];
    }

    /// @inheritdoc IERC3643Confidential
    function isAgent(address account) public view virtual returns (bool) {
        return _agents[account];
    }

    // ============ Agent Role (Owner Only) ============

    /// @inheritdoc IERC3643Confidential
    function addAgent(address agent) external virtual onlyOwner {
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    /// @inheritdoc IERC3643Confidential
    function removeAgent(address agent) external virtual onlyOwner {
        _agents[agent] = false;
        emit AgentRemoved(agent);
    }

    // ============ Transfer Functions (Override ERC7984) ============

    /// @inheritdoc IERC7984
    function confidentialTransfer(
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override(IERC7984, ERC7984) returns (euint256) {
        _checkTransfer(msg.sender, to);
        euint256 transferred = _update(
            msg.sender,
            to,
            Nox.fromExternal(encryptedAmount, inputProof)
        );
        _compliance.transferred(msg.sender, to, transferred);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransfer(
        address to,
        euint256 amount
    ) public virtual override(IERC7984, ERC7984) returns (euint256) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        _checkTransfer(msg.sender, to);
        euint256 transferred = _update(msg.sender, to, amount);
        _compliance.transferred(msg.sender, to, transferred);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override(IERC7984, ERC7984) returns (euint256) {
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        _checkTransfer(from, to);
        euint256 transferred = _update(from, to, Nox.fromExternal(encryptedAmount, inputProof));
        _compliance.transferred(from, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        euint256 amount
    ) public virtual override(IERC7984, ERC7984) returns (euint256) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        _checkTransfer(from, to);
        euint256 transferred = _update(from, to, amount);
        _compliance.transferred(from, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
        return transferred;
    }

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override(IERC7984, ERC7984) returns (euint256 transferred) {
        _checkTransfer(msg.sender, to);
        transferred = _transferAndCall(
            msg.sender,
            to,
            Nox.fromExternal(encryptedAmount, inputProof),
            data
        );
        _compliance.transferred(msg.sender, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferAndCall(
        address to,
        euint256 amount,
        bytes calldata data
    ) public virtual override(IERC7984, ERC7984) returns (euint256 transferred) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        _checkTransfer(msg.sender, to);
        transferred = _transferAndCall(msg.sender, to, amount, data);
        _compliance.transferred(msg.sender, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override(IERC7984, ERC7984) returns (euint256 transferred) {
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        _checkTransfer(from, to);
        transferred = _transferAndCall(
            from,
            to,
            Nox.fromExternal(encryptedAmount, inputProof),
            data
        );
        _compliance.transferred(from, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
    }

    /// @inheritdoc IERC7984
    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint256 amount,
        bytes calldata data
    ) public virtual override(IERC7984, ERC7984) returns (euint256 transferred) {
        require(
            Nox.isAllowed(amount, msg.sender),
            ERC7984UnauthorizedUseOfEncryptedAmount(amount, msg.sender)
        );
        require(isOperator(from, msg.sender), ERC7984UnauthorizedSpender(from, msg.sender));
        _checkTransfer(from, to);
        transferred = _transferAndCall(from, to, amount, data);
        _compliance.transferred(from, to, transferred);
        Nox.allowTransient(transferred, msg.sender);
    }

    // ============ Token Operations (Agent Only) ============

    /// @inheritdoc IERC3643Confidential
    function mint(address to, euint256 amount) external virtual onlyAgent returns (euint256) {
        _requireVerified(to);
        euint256 minted = _mint(to, amount);
        _compliance.created(to, minted);
        return minted;
    }

    /// @inheritdoc IERC3643Confidential
    function mint(
        address to,
        externalEuint256 amount,
        bytes calldata proof
    ) external virtual onlyAgent returns (euint256) {
        _requireVerified(to);
        euint256 minted = _mint(to, Nox.fromExternal(amount, proof));
        _compliance.created(to, minted);
        return minted;
    }

    /// @inheritdoc IERC3643Confidential
    function burn(address from, euint256 amount) external virtual onlyAgent returns (euint256) {
        euint256 burned = _burn(from, amount);
        _compliance.destroyed(from, burned);
        return burned;
    }

    /// @inheritdoc IERC3643Confidential
    function forcedTransfer(
        address from,
        address to,
        euint256 amount
    ) external virtual onlyAgent returns (euint256) {
        _requireVerified(to);
        require(from != address(0), ERC7984InvalidSender(address(0)));
        require(to != address(0), ERC7984InvalidReceiver(address(0)));
        // Bypass frozen check by calling ERC7984Advanced._update directly.
        euint256 transferred = ERC7984Advanced._update(from, to, amount);
        _compliance.transferred(from, to, transferred);
        return transferred;
    }

    // ============ Freeze Operations (Agent Only) ============

    /// @inheritdoc IERC3643Confidential
    function setAddressFrozen(address account, bool frozen) external virtual onlyAgent {
        _frozenAccounts[account] = frozen;
        emit AddressFrozen(account, frozen, msg.sender);
    }

    /// @inheritdoc IERC3643Confidential
    function freezePartialTokens(address account, euint256 amount) external virtual onlyAgent {
        _frozenTokens[account] = Nox.add(_frozenTokens[account], amount);
        Nox.allowThis(_frozenTokens[account]);
        emit TokensFrozen(account, amount);
    }

    /// @inheritdoc IERC3643Confidential
    function unfreezePartialTokens(address account, euint256 amount) external virtual onlyAgent {
        _frozenTokens[account] = Nox.sub(_frozenTokens[account], amount);
        Nox.allowThis(_frozenTokens[account]);
        emit TokensUnfrozen(account, amount);
    }

    // ============ Pause (Agent Only) ============

    /// @inheritdoc IERC3643Confidential
    function pause() external virtual onlyAgent {
        _pause();
    }

    /// @inheritdoc IERC3643Confidential
    function unpause() external virtual onlyAgent {
        _unpause();
    }

    // ============ Admin (Owner Only) ============

    /// @inheritdoc IERC3643Confidential
    function setIdentityRegistry(address registry) external virtual onlyOwner {
        _identityRegistry = IIdentityRegistry(registry);
        emit IdentityRegistryAdded(registry);
    }

    /// @inheritdoc IERC3643Confidential
    function setCompliance(address complianceContract) external virtual onlyOwner {
        _compliance = IConfidentialCompliance(complianceContract);
        emit ComplianceAdded(complianceContract);
    }

    /// @inheritdoc IERC3643Confidential
    function setOnchainID(address id) external virtual onlyOwner {
        _onchainID = id;
    }

    /// @inheritdoc IERC3643Confidential
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        address investorOnchainID
    ) external virtual onlyOwner returns (bool) {
        require(newWallet != address(0), ERC7984InvalidReceiver(address(0)));
        _requireVerified(newWallet);

        // Move balance from lost to new wallet.
        _balances[newWallet] = Nox.add(_balances[newWallet], _balances[lostWallet]);
        Nox.allowThis(_balances[newWallet]);
        Nox.allow(_balances[newWallet], newWallet);
        _balances[lostWallet] = euint256.wrap(bytes32(0));

        // Move frozen tokens from lost to new wallet.
        _frozenTokens[newWallet] = Nox.add(_frozenTokens[newWallet], _frozenTokens[lostWallet]);
        Nox.allowThis(_frozenTokens[newWallet]);
        _frozenTokens[lostWallet] = euint256.wrap(bytes32(0));

        // Transfer frozen wallet status.
        if (_frozenAccounts[lostWallet]) {
            _frozenAccounts[newWallet] = true;
            delete _frozenAccounts[lostWallet];
        }

        emit RecoverySuccess(lostWallet, newWallet, investorOnchainID);
        return true;
    }

    // ============ Internal Functions ============

    /**
     * @dev Override of {ERC7984-_update} that enforces frozen token limits.
     *
     * For regular transfers (non-mint, non-burn), the sender's free balance
     * (total balance minus frozen tokens) is checked. If the requested amount
     * exceeds the free balance, the transfer amount is set to encrypted zero.
     *
     * Mints and burns are not affected by frozen tokens.
     */
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        // Apply frozen token check for transfers only (not mints or burns).
        if (from != address(0) && to != address(0)) {
            euint256 freeBalance = Nox.sub(_balances[from], _frozenTokens[from]);
            (ebool fits, ) = Nox.safeSub(freeBalance, amount);
            amount = Nox.select(fits, amount, Nox.toEuint256(0));
        }
        return super._update(from, to, amount);
    }

    /**
     * @dev Validates all public transfer requirements: pause, freeze, identity, compliance.
     * Reverts if any check fails.
     */
    function _checkTransfer(address from, address to) internal view {
        _requireNotPaused();
        _requireNotFrozen(from);
        _requireNotFrozen(to);
        _requireVerified(to);
        _requireCompliant(from, to);
    }

    function _requireNotFrozen(address account) internal view {
        require(!_frozenAccounts[account], ERC3643WalletFrozen(account));
    }

    function _requireVerified(address account) internal view {
        require(_identityRegistry.isVerified(account), ERC3643NotVerified(account));
    }

    function _requireCompliant(address from, address to) internal view {
        require(_compliance.canTransfer(from, to), ERC3643TransferNotCompliant(from, to));
    }
}
