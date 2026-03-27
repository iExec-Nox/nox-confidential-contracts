// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC7984} from "../../contracts/interfaces/IERC7984.sol";
import {IERC3643Confidential} from "../../contracts/interfaces/IERC3643Confidential.sol";
import {IConfidentialCompliance} from "../../contracts/interfaces/IConfidentialCompliance.sol";
import {ERC7984} from "../../contracts/token/ERC7984.sol";
import {
    ERC3643ConfidentialMock,
    IERC3643ConfidentialTestableMock
} from "../../contracts/mocks/ERC3643/ERC3643ConfidentialMock.sol";
import {IdentityRegistryMock} from "../../contracts/mocks/ERC3643/IdentityRegistryMock.sol";
import {ConfidentialComplianceMock} from "../../contracts/mocks/ERC3643/ConfidentialComplianceMock.sol";
import {NoxMock} from "../utils/NoxMock.sol";

/**
 * @dev Compliance mock that always rejects transfers.
 */
contract RejectingComplianceMock is IConfidentialCompliance {
    function canTransfer(address, address) external pure returns (bool) {
        return false;
    }
    function transferred(address, address, euint256) external {}
    function created(address, euint256) external {}
    function destroyed(address, euint256) external {}
}

contract ERC3643ConfidentialTest is NoxMock {
    ERC3643ConfidentialMock internal token;
    IdentityRegistryMock internal registry;
    ConfidentialComplianceMock internal complianceMock;

    address internal owner; // deployer, default msg.sender
    address internal agent = makeAddr("agent");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    string internal constant NAME = "Confidential Security Token";
    string internal constant SYMBOL = "CST";
    string internal constant CONTRACT_URI = "https://example.com/contract.json";
    address internal constant ONCHAIN_ID = address(0x1234);

    function setUp() public {
        owner = address(this);
        registry = new IdentityRegistryMock();
        complianceMock = new ConfidentialComplianceMock();

        token = new ERC3643ConfidentialMock(
            NAME,
            SYMBOL,
            CONTRACT_URI,
            address(registry),
            address(complianceMock),
            ONCHAIN_ID
        );

        // Setup: add agent and verify users.
        token.addAgent(agent);
        registry.setVerified(user1, true);
        registry.setVerified(user2, true);

        vm.label(address(token), "ERC3643Confidential");
        vm.label(address(registry), "IdentityRegistryMock");
        vm.label(address(complianceMock), "ConfidentialComplianceMock");
        vm.label(owner, "owner");
        vm.label(agent, "agent");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(operator, "operator");
    }

    // ============ constructor ============

    function test_Constructor() public view {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.decimals(), 18);
        assertEq(token.contractURI(), CONTRACT_URI);
        assertEq(token.version(), "1.0.0");
        assertEq(token.onchainID(), ONCHAIN_ID);
        assertEq(token.owner(), owner);
        assertEq(address(token.identityRegistry()), address(registry));
        assertEq(address(token.compliance()), address(complianceMock));
    }

    // ============ supportsInterface ============

    function test_SupportsInterface_IERC3643Confidential() public view {
        assertTrue(token.supportsInterface(type(IERC3643Confidential).interfaceId));
    }

    function test_SupportsInterface_IERC7984() public view {
        assertTrue(token.supportsInterface(type(IERC7984).interfaceId));
    }

    function test_SupportsInterface_IERC165() public view {
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
    }

    // ============ paused ============

    function test_InitiallyNotPaused() public view {
        assertFalse(token.paused());
    }

    // ============ isFrozen ============

    function test_InitiallyNotFrozen() public view {
        assertFalse(token.isFrozen(user1));
        assertFalse(token.isFrozen(user2));
    }

    // ============ addAgent ============

    function test_AddAgent() public {
        address newAgent = makeAddr("newAgent");
        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.AgentAdded(newAgent);
        token.addAgent(newAgent);
        assertTrue(token.isAgent(newAgent));
    }

    function test_RevertWhen_AddAgent_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.addAgent(user1);
    }

    // ============ removeAgent ============

    function test_RemoveAgent() public {
        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.AgentRemoved(agent);
        token.removeAgent(agent);
        assertFalse(token.isAgent(agent));
    }

    function test_RevertWhen_RemoveAgent_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.removeAgent(agent);
    }

    // ============ isAgent ============

    function test_IsAgent() public view {
        assertTrue(token.isAgent(agent));
        assertFalse(token.isAgent(user1));
    }

    // ============ pause ============

    function test_Pause() public {
        vm.expectEmit(false, false, false, true);
        emit Pausable.Paused(agent);
        vm.prank(agent);
        token.pause();
        assertTrue(token.paused());
    }

    function test_RevertWhen_Pause_NotAgent() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.pause();
    }

    // ============ unpause ============

    function test_Unpause() public {
        vm.prank(agent);
        token.pause();
        assertTrue(token.paused());

        vm.expectEmit(false, false, false, true);
        emit Pausable.Unpaused(agent);
        vm.prank(agent);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_RevertWhen_Unpause_NotAgent() public {
        vm.prank(agent);
        token.pause();

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.unpause();
    }

    // ============ setAddressFrozen ============

    function test_SetAddressFrozen() public {
        vm.expectEmit(true, true, true, true);
        emit IERC3643Confidential.AddressFrozen(user1, true, agent);
        vm.prank(agent);
        token.setAddressFrozen(user1, true);
        assertTrue(token.isFrozen(user1));

        vm.expectEmit(true, true, true, true);
        emit IERC3643Confidential.AddressFrozen(user1, false, agent);
        vm.prank(agent);
        token.setAddressFrozen(user1, false);
        assertFalse(token.isFrozen(user1));
    }

    function test_RevertWhen_SetAddressFrozen_NotAgent() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.setAddressFrozen(user2, true);
    }

    // ============ freezePartialTokens ============

    function test_FreezePartialTokens() public {
        _mockNoxPrimitives();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.TokensFrozen(user1, amount);
        vm.prank(agent);
        token.freezePartialTokens(user1, amount);
    }

    function test_RevertWhen_FreezePartialTokens_NotAgent() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.freezePartialTokens(user2, amount);
    }

    // ============ unfreezePartialTokens ============

    function test_UnfreezePartialTokens() public {
        _mockNoxPrimitives();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));

        // Freeze first.
        vm.prank(agent);
        token.freezePartialTokens(user1, amount);

        // Then unfreeze.
        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.TokensUnfrozen(user1, amount);
        vm.prank(agent);
        token.unfreezePartialTokens(user1, amount);
    }

    function test_RevertWhen_UnfreezePartialTokens_NotAgent() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.unfreezePartialTokens(user2, amount);
    }

    // ============ mint ============

    function test_Mint() public {
        _mockNoxPrimitives();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));

        vm.expectEmit(true, true, false, true);
        emit IERC7984.ConfidentialTransfer(address(0), user1, euint256.wrap(MOCK_HANDLE));
        vm.prank(agent);
        token.mint(user1, amount);
    }

    function test_RevertWhen_Mint_NotAgent() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.mint(user1, amount);
    }

    function test_RevertWhen_Mint_ReceiverNotVerified() public {
        address unverified = makeAddr("unverified");
        vm.label(unverified, "unverified");
        euint256 amount = euint256.wrap(bytes32(uint256(1)));

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643NotVerified.selector, unverified)
        );
        vm.prank(agent);
        token.mint(unverified, amount);
    }

    // ============ burn ============

    function test_Burn() public {
        _mockNoxPrimitives();

        // Mint first to give user1 a balance.
        vm.prank(agent);
        token.mint(user1, euint256.wrap(bytes32(uint256(1))));

        // Burn.
        euint256 burnAmount = euint256.wrap(bytes32(uint256(2)));
        vm.prank(agent);
        token.burn(user1, burnAmount);
    }

    function test_RevertWhen_Burn_NotAgent() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.burn(user1, amount);
    }

    // ============ forcedTransfer ============

    function test_ForcedTransfer() public {
        _mockNoxPrimitives();

        // Mint to user1.
        vm.prank(agent);
        token.mint(user1, euint256.wrap(bytes32(uint256(1))));

        // Freeze user1: forcedTransfer should still work.
        vm.prank(agent);
        token.setAddressFrozen(user1, true);

        // Forced transfer from user1 to user2.
        euint256 amount = euint256.wrap(bytes32(uint256(2)));
        vm.prank(agent);
        token.forcedTransfer(user1, user2, amount);
    }

    function test_RevertWhen_ForcedTransfer_NotAgent() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643UnauthorizedAgent.selector, user1)
        );
        vm.prank(user1);
        token.forcedTransfer(user1, user2, amount);
    }

    function test_RevertWhen_ForcedTransfer_ReceiverNotVerified() public {
        _mockNoxPrimitives();
        address unverified = makeAddr("unverified");
        vm.label(unverified, "unverified");

        // Mint to user1.
        vm.prank(agent);
        token.mint(user1, euint256.wrap(bytes32(uint256(1))));

        euint256 amount = euint256.wrap(bytes32(uint256(2)));
        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643NotVerified.selector, unverified)
        );
        vm.prank(agent);
        token.forcedTransfer(user1, unverified, amount);
    }

    // ============ confidentialTransfer ============

    function test_RevertWhen_ConfidentialTransfer_Paused() public {
        vm.prank(agent);
        token.pause();

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    function test_RevertWhen_ConfidentialTransfer_SenderFrozen() public {
        vm.prank(agent);
        token.setAddressFrozen(user1, true);

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643WalletFrozen.selector, user1)
        );
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    function test_RevertWhen_ConfidentialTransfer_ReceiverFrozen() public {
        vm.prank(agent);
        token.setAddressFrozen(user2, true);

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643WalletFrozen.selector, user2)
        );
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    function test_RevertWhen_ConfidentialTransfer_ReceiverNotVerified() public {
        address unverified = makeAddr("unverified");
        vm.label(unverified, "unverified");

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643NotVerified.selector, unverified)
        );
        vm.prank(user1);
        token.confidentialTransfer(unverified, amount);
    }

    function test_RevertWhen_ConfidentialTransfer_NotCompliant() public {
        RejectingComplianceMock rejecting = new RejectingComplianceMock();
        vm.label(address(rejecting), "RejectingComplianceMock");

        // Swap compliance to the rejecting one.
        token.setCompliance(address(rejecting));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC3643Confidential.ERC3643TransferNotCompliant.selector,
                user1,
                user2
            )
        );
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    // ============ confidentialTransferFrom ============

    function test_RevertWhen_ConfidentialTransferFrom_Paused() public {
        // Grant operator permission.
        vm.prank(user1);
        token.setOperator(operator, uint48(block.timestamp + 1 days));

        vm.prank(agent);
        token.pause();

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, operator, true);

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(operator);
        token.confidentialTransferFrom(user1, user2, amount);
    }

    function test_RevertWhen_ConfidentialTransferFrom_UnauthorizedSpender() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, operator, true);

        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        token.confidentialTransferFrom(user1, user2, amount);
    }

    // ============ setIdentityRegistry ============

    function test_SetIdentityRegistry() public {
        address newRegistry = makeAddr("newRegistry");
        vm.label(newRegistry, "newRegistry");

        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.IdentityRegistryAdded(newRegistry);
        token.setIdentityRegistry(newRegistry);
        assertEq(address(token.identityRegistry()), newRegistry);
    }

    function test_RevertWhen_SetIdentityRegistry_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.setIdentityRegistry(address(0));
    }

    // ============ setCompliance ============

    function test_SetCompliance() public {
        address newCompliance = makeAddr("newCompliance");
        vm.label(newCompliance, "newCompliance");

        vm.expectEmit(true, false, false, true);
        emit IERC3643Confidential.ComplianceAdded(newCompliance);
        token.setCompliance(newCompliance);
        assertEq(address(token.compliance()), newCompliance);
    }

    // ============ setOnchainID ============

    function test_SetOnchainID() public {
        address newID = makeAddr("newOnchainID");
        vm.label(newID, "newOnchainID");

        token.setOnchainID(newID);
        assertEq(token.onchainID(), newID);
    }

    // ============ transferOwnership ============

    function test_TransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        vm.label(newOwner, "newOwner");

        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);
    }

    function test_RevertWhen_TransferOwnership_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.transferOwnership(user1);
    }

    function test_RevertWhen_TransferOwnership_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        token.transferOwnership(address(0));
    }

    // ============ recoveryAddress ============

    function test_RecoveryAddress() public {
        _mockNoxPrimitives();

        // Mint tokens to user1 (the "lost" wallet).
        vm.prank(agent);
        token.mint(user1, euint256.wrap(bytes32(uint256(1))));

        address newWallet = makeAddr("newWallet");
        vm.label(newWallet, "newWallet");
        registry.setVerified(newWallet, true);

        address investorID = makeAddr("investorID");
        vm.label(investorID, "investorID");

        vm.expectEmit(false, false, false, true);
        emit IERC3643Confidential.RecoverySuccess(user1, newWallet, investorID);
        bool result = token.recoveryAddress(user1, newWallet, investorID);
        assertTrue(result);
    }

    function test_RevertWhen_RecoveryAddress_NotOwner() public {
        address newWallet = makeAddr("newWallet");
        vm.label(newWallet, "newWallet");
        registry.setVerified(newWallet, true);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.recoveryAddress(user1, newWallet, address(0));
    }

    function test_RevertWhen_RecoveryAddress_NewWalletNotVerified() public {
        address newWallet = makeAddr("newWallet");
        vm.label(newWallet, "newWallet");
        // Do NOT verify newWallet.

        vm.expectRevert(
            abi.encodeWithSelector(IERC3643Confidential.ERC3643NotVerified.selector, newWallet)
        );
        token.recoveryAddress(user1, newWallet, address(0));
    }

    function test_RevertWhen_RecoveryAddress_ZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        token.recoveryAddress(user1, address(0), address(0));
    }
}
