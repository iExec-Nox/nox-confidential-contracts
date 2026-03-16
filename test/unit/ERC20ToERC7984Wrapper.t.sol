// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IERC7984} from "../../contracts/interfaces/IERC7984.sol";
import {IERC20ToERC7984Wrapper} from "../../contracts/interfaces/IERC20ToERC7984Wrapper.sol";
import {ERC7984} from "../../contracts/token/ERC7984.sol";
import {ERC20ToERC7984Wrapper} from "../../contracts/token/extensions/ERC20ToERC7984Wrapper.sol";
import {
    ERC20Mock,
    ERC20ToERC7984WrapperMock,
    IERC20ToERC7984WrapperTestableMock
} from "../../contracts/mocks/token/ERC20ToERC7984WrapperMock.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {NoxMock} from "../utils/NoxMock.sol";

contract ERC20ToERC7984WrapperTest is NoxMock {
    string internal constant NAME = "Wrapped Nox";
    string internal constant SYMBOL = "wNOX";
    string internal constant URI = "https://example.com";

    ERC20Mock internal underlying6;
    ERC20Mock internal underlying18;
    IERC20ToERC7984WrapperTestableMock internal wrapper;

    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    function setUp() public {
        underlying6 = new ERC20Mock("USD Coin", "USDC", 6);
        underlying18 = new ERC20Mock("DAI Stablecoin", "DAI", 18);
        wrapper = _getTokenInstance();

        vm.label(address(underlying6), "USDC");
        vm.label(address(underlying18), "DAI");
        vm.label(address(wrapper), _getTestedContractName());
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(operator, "operator");
        vm.label(noxCompute, "NoxCompute");
    }

    /**
     * @dev Returns an instance of the token contract to be tested.
     * Can be overridden by derived test contracts to test different implementations
     * of the same interface IERC7984.
     */
    function _getTokenInstance() internal virtual returns (IERC20ToERC7984WrapperTestableMock) {
        return new ERC20ToERC7984WrapperMock(NAME, SYMBOL, URI, underlying6);
    }

    /**
     * Override to change tested contract name used in vm.label().
     */
    function _getTestedContractName() internal pure virtual returns (string memory) {
        return "ERC20ToERC7984Wrapper";
    }

    // ============ constructor ============

    function test_Constructor_6DecimalUnderlying() public view {
        assertEq(wrapper.decimals(), 6);
        assertEq(wrapper.underlying(), address(underlying6));
    }

    function test_Constructor_18DecimalUnderlying() public {
        ERC20ToERC7984WrapperMock w18 = new ERC20ToERC7984WrapperMock(
            "W18",
            "w18",
            "",
            underlying18
        );
        assertEq(w18.decimals(), 18);
    }

    // ============ supportsInterface ============

    function test_SupportsInterface_IERC20ToERC7984Wrapper() public view {
        assertTrue(wrapper.supportsInterface(type(IERC20ToERC7984Wrapper).interfaceId));
    }

    function test_SupportsInterface_IERC1363Receiver() public view {
        assertTrue(wrapper.supportsInterface(type(IERC1363Receiver).interfaceId));
    }

    function test_SupportsInterface_IERC7984() public view {
        assertTrue(wrapper.supportsInterface(type(IERC7984).interfaceId));
    }

    function test_SupportsInterface_InvalidInterface() public view {
        assertFalse(wrapper.supportsInterface(0xdeadbeef));
    }

    // ============ wrap ============

    function test_Wrap() public {
        _mockNoxPrimitives();
        uint256 amount = 1000e6;
        underlying6.mint(user1, amount);
        vm.prank(user1);
        underlying6.approve(address(wrapper), amount);

        vm.prank(user1);
        euint256 wrapped = wrapper.wrap(user1, amount);

        assertEq(euint256.unwrap(wrapped), MOCK_HANDLE);
        assertEq(underlying6.balanceOf(address(wrapper)), amount);
        assertEq(underlying6.balanceOf(user1), 0);
    }

    function test_Wrap_18DecimalUnderlying() public {
        _mockNoxPrimitives();
        ERC20ToERC7984WrapperMock w18 = new ERC20ToERC7984WrapperMock(
            "W18",
            "w18",
            "",
            underlying18
        );
        uint256 amount = 1.5e18;

        underlying18.mint(user1, amount);
        vm.prank(user1);
        underlying18.approve(address(w18), amount);

        vm.prank(user1);
        w18.wrap(user1, amount);

        assertEq(underlying18.balanceOf(address(w18)), amount);
    }

    // ============ onTransferReceived ============

    function test_RevertWhen_OnTransferReceived_UnauthorizedCaller() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC20ToERC7984Wrapper.ERC7984UnauthorizedCaller.selector, user1)
        );
        vm.prank(user1);
        wrapper.onTransferReceived(user1, user1, 100e6, "");
    }

    function test_OnTransferReceived_ReturnsMagicValue() public {
        _mockNoxPrimitives();
        underlying6.mint(address(wrapper), 500e6);
        vm.prank(address(underlying6));
        bytes4 ret = wrapper.onTransferReceived(user1, user1, 500e6, "");
        assertEq(ret, IERC1363Receiver.onTransferReceived.selector);
    }

    // ============ unwrap ============

    function test_Unwrap_RecordsRequest() public {
        _mockNoxPrimitives();
        underlying6.mint(user1, 1000e6);
        vm.prank(user1);
        underlying6.approve(address(wrapper), 1000e6);
        vm.prank(user1);
        wrapper.wrap(user1, 1000e6);

        euint256 encAmount = euint256.wrap(MOCK_HANDLE);
        vm.prank(user1);
        euint256 unwrapped = wrapper.unwrap(user1, user2, encAmount);

        assertEq(wrapper.unwrapRequester(unwrapped), user2);
    }

    function test_RevertWhen_Unwrap_InvalidReceiver() public {
        _mockNoxPrimitives();
        underlying6.mint(user1, 1000e6);
        vm.prank(user1);
        underlying6.approve(address(wrapper), 1000e6);
        vm.prank(user1);
        wrapper.wrap(user1, 1000e6);

        euint256 encAmount = euint256.wrap(MOCK_HANDLE);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984InvalidReceiver.selector, address(0))
        );
        vm.prank(user1);
        wrapper.unwrap(user1, address(0), encAmount);
    }

    function test_RevertWhen_Unwrap_UnauthorizedSpender() public {
        _mockNoxPrimitives();
        underlying6.mint(user1, 1000e6);
        vm.prank(user1);
        underlying6.approve(address(wrapper), 1000e6);
        vm.prank(user1);
        wrapper.wrap(user1, 1000e6);

        euint256 encAmount = euint256.wrap(MOCK_HANDLE);
        vm.expectRevert(
            abi.encodeWithSelector(ERC7984.ERC7984UnauthorizedSpender.selector, user1, operator)
        );
        vm.prank(operator);
        wrapper.unwrap(user1, user2, encAmount);
    }

    // ============ finalizeUnwrap ============

    function test_FinalizeUnwrap() public {
        _mockNoxPrimitives();
        euint256 unwrapRequestId = _createPendingUnwrapRequest();
        uint256 plaintextAmount = 400e6;
        _mockPublicDecryptCall(plaintextAmount);

        vm.expectEmit(address(wrapper));
        emit IERC20ToERC7984Wrapper.UnwrapFinalized(user2, unwrapRequestId, plaintextAmount);

        wrapper.finalizeUnwrap(unwrapRequestId, plaintextAmount, hex"1234");

        assertEq(wrapper.unwrapRequester(unwrapRequestId), address(0));
        assertEq(underlying6.balanceOf(user2), plaintextAmount);
        assertEq(underlying6.balanceOf(address(wrapper)), 1000e6 - plaintextAmount);
    }

    function test_RevertWhen_FinalizeUnwrap_InvalidUnwrapRequest() public {
        euint256 invalidRequestId = euint256.wrap(MOCK_HANDLE);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20ToERC7984Wrapper.InvalidUnwrapRequest.selector,
                invalidRequestId
            )
        );
        wrapper.finalizeUnwrap(invalidRequestId, 100e6, hex"1234");
    }

    function test_RevertWhen_FinalizeUnwrap_InvalidDecryptionProof() public {
        _mockNoxPrimitives();
        euint256 unwrapRequestId = _createPendingUnwrapRequest();
        uint256 plaintextAmount = 400e6;
        _mockPublicDecryptCall(plaintextAmount + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20ToERC7984Wrapper.InvalidDecryptionProof.selector,
                unwrapRequestId
            )
        );
        wrapper.finalizeUnwrap(unwrapRequestId, plaintextAmount, hex"1234");
    }

    function test_RevertWhen_FinalizeUnwrap_UnderlyingTransferFails() public {
        _mockNoxPrimitives();
        euint256 unwrapRequestId = _createPendingUnwrapRequest();
        uint256 plaintextAmount = 400e6;
        _mockPublicDecryptCall(plaintextAmount);

        // Make the underlying transfer fail by draining the wrapper's balance
        vm.prank(address(wrapper));
        underlying6.transfer(address(0xdeadbeef), 1000e6);

        vm.expectRevert();
        wrapper.finalizeUnwrap(unwrapRequestId, plaintextAmount, hex"1234");
    }

    // ============ inferredTotalSupply / maxTotalSupply ============

    function test_InferredTotalSupply_AfterWrap() public {
        _mockNoxPrimitives();
        uint256 amount = 1000e6;
        underlying6.mint(user1, amount);
        vm.prank(user1);
        underlying6.approve(address(wrapper), amount);
        vm.prank(user1);
        wrapper.wrap(user1, amount);

        assertEq(wrapper.inferredTotalSupply(), amount);
    }

    function test_MaxTotalSupply() public view {
        assertEq(wrapper.maxTotalSupply(), type(uint256).max);
    }

    // ========== Helpers ============

    function _createPendingUnwrapRequest() internal returns (euint256) {
        underlying6.mint(user1, 1000e6);
        vm.startPrank(user1);
        underlying6.approve(address(wrapper), 1000e6);
        wrapper.wrap(user1, 1000e6);
        euint256 unwrapRequestId = wrapper.unwrap(user1, user2, euint256.wrap(MOCK_HANDLE));
        vm.stopPrank();
        return unwrapRequestId;
    }
}
