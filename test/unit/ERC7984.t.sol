// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7984} from "../../contracts/interfaces/IERC7984.sol";
import {ERC7984} from "../../contracts/token/ERC7984.sol";
import {ERC7984Mock, IERC7984TestableMock} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984ReceiverMock} from "../../contracts/mocks/token/ERC7984ReceiverMock.sol";
import {NoxMock} from "../utils/NoxMock.sol";

contract ERC7984Test is NoxMock {
    IERC7984TestableMock internal token;
    ERC7984ReceiverMock internal receiver;

    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    string internal constant NAME = "Nox Confidential Token";
    string internal constant SYMBOL = "NCT";
    string internal constant CONTRACT_URI = "https://example.com/contract.json";

    function setUp() public {
        token = _getTokenInstance();
        receiver = new ERC7984ReceiverMock();
        vm.label(address(token), _getTestedContractName());
        vm.label(address(receiver), "ERC7984ReceiverMock");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(operator, "operator");
    }

    /**
     * @dev Returns an instance of the token contract to be tested.
     * Can be overridden by derived test contracts to test different implementations
     * of the same interface IERC7984.
     */
    function _getTokenInstance() internal virtual returns (IERC7984TestableMock) {
        return new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI);
    }

    /**
     * Override to change tested contract name used in vm.label().
     */
    function _getTestedContractName() internal pure virtual returns (string memory) {
        return "ERC7984";
    }

    // ============ constructor ============

    function test_Constructor() public view {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.decimals(), 18);
        assertEq(token.contractURI(), CONTRACT_URI);
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
        _mockIsAllowedCall(amount, user1, false);
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
        _mockIsAllowedCall(amount, user1, true);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        vm.prank(user1);
        token.confidentialTransfer(address(0), amount);
    }

    function test_RevertWhen_ConfidentialTransfer_ZeroBalance() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984ZeroBalance.selector, user1));
        vm.prank(user1);
        token.confidentialTransfer(user2, amount);
    }

    // ============ confidentialTransferFrom ============

    function test_RevertWhen_ConfidentialTransferFrom_UnauthorizedUseOfEncryptedAmount() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, operator, false);
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
        _mockIsAllowedCall(amount, operator, true);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        token.confidentialTransferFrom(user1, user2, amount);
    }

    // ============ confidentialTransferAndCall Tests ============

    function test_RevertWhen_ConfidentialTransferAndCall_UnauthorizedUseOfEncryptedAmount() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, false);
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
        _mockIsAllowedCall(amount, user1, true);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        vm.prank(user1);
        token.confidentialTransferAndCall(address(0), amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ZeroBalance() public {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, user1, true);
        vm.expectRevert(abi.encodeWithSelector(ERC7984.ERC7984ZeroBalance.selector, user1));
        vm.prank(user1);
        token.confidentialTransferAndCall(user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ReceiverRevertsEmptyReason() public {
        // Passing empty data causes abi.decode to fail with no reason: ERC7984InvalidReceiver should be raised.
        _mockNoxPrimitives();
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(receiver))
        );
        vm.prank(user1);
        token.confidentialTransferAndCall(address(receiver), amount, "");
    }

    function test_RevertWhen_ConfidentialTransferAndCall_ReceiverRevertsWithReason() public {
        // Passing false triggers InvalidInput: reason is bubbled up as-is.
        _mockNoxPrimitives();
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(abi.encodeWithSelector(ERC7984ReceiverMock.InvalidInput.selector));
        vm.prank(user1);
        token.confidentialTransferAndCall(address(receiver), amount, abi.encode(false));
    }

    function test_ConfidentialTransferAndCall_ToEOA() public {
        _mockNoxPrimitives();
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.prank(user1);
        // user2 is an EOA: checkOnTransferReceived skips the callback and returns toEbool(true).
        token.confidentialTransferAndCall(user2, amount, "");
    }

    function test_ConfidentialTransferAndCall_ToValidReceiver() public {
        _mockNoxPrimitives();
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectEmit(address(receiver));
        emit ERC7984ReceiverMock.ConfidentialTransferCallback(true);
        vm.prank(user1);
        token.confidentialTransferAndCall(address(receiver), amount, abi.encode(true));
    }

    // ============ confidentialTransferFromAndCall Tests ============

    function test_RevertWhen_ConfidentialTransferFromAndCall_UnauthorizedUseOfEncryptedAmount()
        public
    {
        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        _mockIsAllowedCall(amount, operator, false);
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
        _mockIsAllowedCall(amount, operator, true);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        token.confidentialTransferFromAndCall(user1, user2, amount, "");
    }

    function test_RevertWhen_ConfidentialTransferFromAndCall_ReceiverRevertsEmptyReason() public {
        // Passing empty data causes abi.decode to fail with no reason: ERC7984InvalidReceiver should be raised.
        _mockNoxPrimitives();
        vm.prank(user1);
        token.setOperator(operator, uint48(block.timestamp + 1 days));
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(receiver))
        );
        vm.prank(operator);
        token.confidentialTransferFromAndCall(user1, address(receiver), amount, "");
    }

    function test_ConfidentialTransferFromAndCall_ToValidReceiver() public {
        _mockNoxPrimitives();
        vm.prank(user1);
        token.setOperator(operator, uint48(block.timestamp + 1 days));
        token.mint(user1, euint256.wrap(MOCK_HANDLE));

        euint256 amount = euint256.wrap(bytes32(uint256(1)));
        vm.expectEmit(address(receiver));
        emit ERC7984ReceiverMock.ConfidentialTransferCallback(true);
        vm.prank(operator);
        token.confidentialTransferFromAndCall(user1, address(receiver), amount, abi.encode(true));
    }
}
