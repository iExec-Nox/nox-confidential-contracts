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

contract ERC7984Test is Test {
    ERC7984Mock internal token;

    // TODO: Replace hardcoded address with Nox._acl() when exposed publicly from the lib.
    // ACL address on local dev chain (chainid 31337)
    address internal constant ACL = 0x3219A802B61028Fc29848863268FE17d750E5701;

    address internal owner = makeAddr("owner");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    string internal constant NAME = "Nox Confidential Token";
    string internal constant SYMBOL = "NCT";
    string internal constant CONTRACT_URI = "https://example.com/contract.json";

    function setUp() public {
        token = new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI, owner);
        vm.label(address(token), "ERC7984Mock");
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
}
