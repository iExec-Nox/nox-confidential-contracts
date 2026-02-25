// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IACL} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/IACL.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {IERC7984} from "../../contracts/interfaces/IERC7984.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984} from "../../contracts/token/ERC7984.sol";
import {ERC7984Mock} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984ReceiverMock} from "../../contracts/mocks/token/ERC7984ReceiverMock.sol";

/// @dev ERC7984Mock that bypasses TEE computations in _update for testing callback behavior.
contract ERC7984BypassTEEMock is ERC7984Mock {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address owner_
    ) ERC7984Mock(name_, symbol_, contractURI_, owner_) {}

    function _update(
        address from,
        address to,
        euint256 amount
    ) internal override returns (euint256) {
        emit ConfidentialTransfer(from, to, amount);
        return amount;
    }
}

contract ERC7984Test is Test {
    ERC7984Mock internal token;
    ERC7984BypassTEEMock internal bypassToken;

    // TODO: Replace hardcoded addresses with Nox._acl() / Nox._compute() when exposed publicly.
    // Contract addresses on local dev chain (chainid 31337)
    address internal constant ACL = 0x3219A802B61028Fc29848863268FE17d750E5701;
    address internal constant COMPUTE = 0x463Bdd46031353138713a47D7056F7c85024a4A6;

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    address internal owner = makeAddr("owner");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    string internal constant NAME = "Nox Confidential Token";
    string internal constant SYMBOL = "NCT";
    string internal constant CONTRACT_URI = "https://example.com/contract.json";

    function setUp() public {
        token = new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI, owner);
        bypassToken = new ERC7984BypassTEEMock(NAME, SYMBOL, CONTRACT_URI, owner);
        vm.label(address(token), "ERC7984Mock");
        vm.label(address(bypassToken), "ERC7984BypassTEEMock");
        vm.label(owner, "owner");
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
        assertEq(token.owner(), owner);
    }

    // ============ supportsInterface ============

    function test_SupportsInterface_IERC7984() public view {
        assertTrue(token.supportsInterface(type(IERC7984).interfaceId));
    }

    function test_SupportsInterface_IERC165() public view {
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
    }

    function test_SupportsInterface_InvalidInterface() public view {
        assertFalse(token.supportsInterface(0xdeadbeef));
    }

    // ============ confidentialTotalSupply ============

    function test_ConfidentialTotalSupply_InitiallyZero() public view {
        assertEq(euint256.unwrap(token.confidentialTotalSupply()), bytes32(0));
    }

    // ============ confidentialBalanceOf ============

    function test_ConfidentialBalanceOf_InitiallyZero() public view {
        assertEq(euint256.unwrap(token.confidentialBalanceOf(user1)), bytes32(0));
    }

    // ============ isOperator ============

    function test_IsOperator_SelfIsAlwaysOperator() public view {
        assertTrue(token.isOperator(user1, user1));
    }

    function test_IsOperator_NotOperatorByDefault() public view {
        assertFalse(token.isOperator(user1, operator));
    }

    function test_IsOperator_AtExactTimestamp() public {
        uint48 until = uint48(block.timestamp);
        vm.prank(user1);
        token.setOperator(operator, until);
        // block.timestamp <= until is true at the exact boundary
        assertTrue(token.isOperator(user1, operator));
    }

    // ============ setOperator ============

    function test_SetOperator() public {
        uint48 until = uint48(block.timestamp + 1 days);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit IERC7984.OperatorSet(user1, operator, until);
        token.setOperator(operator, until);
        assertTrue(token.isOperator(user1, operator));
    }

    function test_SetOperator_RevokeBySettingPastTimestamp() public {
        uint48 until = uint48(block.timestamp + 1 days);
        vm.prank(user1);
        token.setOperator(operator, until);
        assertTrue(token.isOperator(user1, operator));

        vm.prank(user1);
        token.setOperator(operator, uint48(block.timestamp - 1));
        assertFalse(token.isOperator(user1, operator));
    }

    function test_SetOperator_Expired() public {
        uint48 until = uint48(block.timestamp + 1 hours);
        vm.prank(user1);
        token.setOperator(operator, until);
        assertTrue(token.isOperator(user1, operator));

        vm.warp(block.timestamp + 2 hours);
        assertFalse(token.isOperator(user1, operator));
    }

    // ============ _mint ============

    function test_RevertWhen_Mint_InvalidReceiver() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        token.mint(address(0), euint256.wrap(bytes32(uint256(1))));
    }

    // ============ _burn ============

    function test_RevertWhen_Burn_InvalidSender() public {
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984InvalidSender.selector, address(0)));
        token.burn(address(0), euint256.wrap(bytes32(uint256(1))));
    }

    function test_RevertWhen_Burn_ZeroBalance() public {
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984ZeroBalance.selector, user1));
        token.burn(user1, euint256.wrap(bytes32(uint256(1))));
    }

    // ============ _transfer ============

    function test_RevertWhen_Transfer_InvalidSender() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984InvalidSender.selector, address(0)));
        token.transfer(address(0), user1, amount);
    }

    function test_RevertWhen_Transfer_InvalidReceiver() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        token.transfer(user1, address(0), amount);
    }

    // ============ confidentialTransfer ============

    function test_RevertWhen_ConfidentialTransfer_UnauthorizedUseOfEncryptedAmount() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(false)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC7984.ERC7984UnauthorizedUseOfEncryptedAmount.selector,
                amount,
                user1
            )
        );
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    function test_RevertWhen_ConfidentialTransfer_InvalidReceiver() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(true)
        );
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        vm.prank(user1);
        token.confidentialTransfer(address(0), amount);
    }

    function test_RevertWhen_ConfidentialTransfer_ZeroBalance() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(true)
        );
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984ZeroBalance.selector, user1));
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    // ============ confidentialTransferFrom ============

    function test_RevertWhen_ConfidentialTransferFrom_UnauthorizedUseOfEncryptedAmount() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature(
                "isAllowed(bytes32,address)",
                euint256.unwrap(amount),
                operator
            ),
            abi.encode(false)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC7984.ERC7984UnauthorizedUseOfEncryptedAmount.selector,
                amount,
                operator
            )
        );
        vm.prank(operator);
        token.confidentialTransferFrom(user1, user2, amount);
    }

    function test_RevertWhen_ConfidentialTransferFrom_UnauthorizedSpender() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature(
                "isAllowed(bytes32,address)",
                euint256.unwrap(amount),
                operator
            ),
            abi.encode(true)
        );
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        token.confidentialTransferFrom(user1, user2, amount);
    }

    // ============ owner ============

    function test_TransferOwnership() public {
        vm.prank(owner);
        token.transferOwnership(user1);
        assertEq(token.owner(), user1);
    }

    function test_RevertWhen_TransferOwnership_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        token.transferOwnership(user2);
    }

    // ============ confidentialTransferAndCall Tests ============

    function test_RevertWhen_ConfidentialTransferAndCall_UnauthorizedUseOfEncryptedAmount() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(false)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC7984.ERC7984UnauthorizedUseOfEncryptedAmount.selector,
                amount,
                user1
            )
        );
        vm.prank(user1);
        token.confidentialTransferAndCall(user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_InvalidReceiver() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(true)
        );
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        vm.prank(user1);
        token.confidentialTransferAndCall(address(0), amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ZeroBalance() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user1),
            abi.encode(true)
        );
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984ZeroBalance.selector, user1));
        vm.prank(user1);
        token.confidentialTransferAndCall(user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ReceiverRevertsEmptyReason() public {
        // Passing empty data causes abi.decode to fail with no reason: ERC7984InvalidReceiver should be raised.
        ERC7984ReceiverMock receiver = new ERC7984ReceiverMock();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(receiver))
        );
        vm.prank(user1);
        bypassToken.confidentialTransferAndCall(address(receiver), amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ReceiverRevertsWithReason() public {
        // Passing an invalid input (> 1) triggers InvalidInput: reason is bubbled up as-is.
        ERC7984ReceiverMock receiver = new ERC7984ReceiverMock();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984ReceiverMock.InvalidInput.selector, uint8(2))
        );
        vm.prank(user1);
        bypassToken.confidentialTransferAndCall(address(receiver), amount, abi.encode(uint8(2)));
    }

    function test_ConfidentialTransferAndCall_ToEOA() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        // Mock TEE compute operations (toEbool, toEuint256, select, sub).
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("plaintextToEncrypted(bytes32,uint8)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("select(bytes32,bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("sub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.mockCall(ACL, abi.encodeWithSignature("allow(bytes32,address)"), "");
        vm.mockCall(ACL, abi.encodeWithSignature("allowTransient(bytes32,address)"), "");
        vm.prank(user1);
        // user2 is an EOA: checkOnTransferReceived skips the callback and returns toEbool(true).
        bypassToken.confidentialTransferAndCall(user2, amount, "");
    }

    function test_ConfidentialTransferAndCall_ToValidReceiver() public {
        ERC7984ReceiverMock receiver = new ERC7984ReceiverMock();
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        bytes memory data = abi.encode(uint8(1));
        // Mock TEE compute operations (toEbool, toEuint256, select, sub).
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("plaintextToEncrypted(bytes32,uint8)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("select(bytes32,bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("sub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.mockCall(ACL, abi.encodeWithSignature("allow(bytes32,address)"), "");
        vm.mockCall(ACL, abi.encodeWithSignature("allowTransient(bytes32,address)"), "");
        vm.expectEmit(address(receiver));
        emit ERC7984ReceiverMock.ConfidentialTransferCallback(true);
        vm.prank(user1);
        bypassToken.confidentialTransferAndCall(address(receiver), amount, data);
    }

    // ============ confidentialTransferFromAndCall Tests ============

    function test_RevertWhen_ConfidentialTransferFromAndCall_UnauthorizedUseOfEncryptedAmount()
        public
    {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature(
                "isAllowed(bytes32,address)",
                euint256.unwrap(amount),
                operator
            ),
            abi.encode(false)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC7984.ERC7984UnauthorizedUseOfEncryptedAmount.selector,
                amount,
                operator
            )
        );
        vm.prank(operator);
        token.confidentialTransferFromAndCall(user1, user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferFromAndCall_UnauthorizedSpender() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(
            ACL,
            abi.encodeWithSignature(
                "isAllowed(bytes32,address)",
                euint256.unwrap(amount),
                operator
            ),
            abi.encode(true)
        );
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        token.confidentialTransferFromAndCall(user1, user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferFromAndCall_ReceiverRevertsEmptyReason() public {
        // Passing empty data causes abi.decode to fail with no reason: ERC7984InvalidReceiver should be raised.
        ERC7984ReceiverMock receiver = new ERC7984ReceiverMock();
        uint48 until = uint48(block.timestamp + 1 days);
        vm.prank(user1);
        bypassToken.setOperator(operator, until);
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(receiver))
        );
        vm.prank(operator);
        bypassToken.confidentialTransferFromAndCall(user1, address(receiver), amount, "");
    }

    function test_ConfidentialTransferFromAndCall_ToValidReceiver() public {
        ERC7984ReceiverMock receiver = new ERC7984ReceiverMock();
        uint48 until = uint48(block.timestamp + 1 days);
        vm.prank(user1);
        bypassToken.setOperator(operator, until);
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        bytes memory data = abi.encode(uint8(1));
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("plaintextToEncrypted(bytes32,uint8)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("select(bytes32,bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("sub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.mockCall(ACL, abi.encodeWithSignature("allow(bytes32,address)"), "");
        vm.mockCall(ACL, abi.encodeWithSignature("allowTransient(bytes32,address)"), "");
        vm.expectEmit(address(receiver));
        emit ERC7984ReceiverMock.ConfidentialTransferCallback(true);
        vm.prank(operator);
        bypassToken.confidentialTransferFromAndCall(user1, address(receiver), amount, data);
    }
}
