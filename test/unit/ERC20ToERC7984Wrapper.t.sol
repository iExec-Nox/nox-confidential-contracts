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
    ERC20ToERC7984WrapperMock
} from "../../contracts/mocks/token/ERC20ToERC7984WrapperMock.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {NoxMock} from "../utils/NoxMock.sol";

contract ERC20ToERC7984WrapperTest is NoxMock {
    ERC20Mock internal underlying6;
    ERC20Mock internal underlying18;
    ERC20ToERC7984WrapperMock internal wrapper;

    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");
    address internal operator = makeAddr("operator");

    function setUp() public {
        underlying6 = new ERC20Mock("USD Coin", "USDC", 6);
        underlying18 = new ERC20Mock("DAI Stablecoin", "DAI", 18);
        wrapper = new ERC20ToERC7984WrapperMock(
            "Wrapped Nox",
            "wNOX",
            "https://example.com",
            underlying6
        );

        vm.label(address(underlying6), "USDC");
        vm.label(address(underlying18), "DAI");
        vm.label(address(wrapper), "ERC20ToERC7984WrapperMock");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(operator, "operator");
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
}
