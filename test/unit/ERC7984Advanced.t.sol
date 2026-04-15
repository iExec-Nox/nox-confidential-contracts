// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984Advanced} from "../../contracts/token/ERC7984Advanced.sol";
import {ERC7984CommonTest, TokenMock} from "./ERC7984Common.sol";

contract ERC7984AdvancedTest is ERC7984CommonTest {
    function _getTokenInstance() internal override returns (TokenMock) {
        return new ERC7984AdvancedMock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984Advanced";
    }

    function _assertUsedPrimitivesForMint() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.mint.selector));
    }

    function _assertUsedPrimitivesForBurn() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.burn.selector));
    }

    function _assertUsedPrimitivesForTransfer() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.transfer.selector));
    }
}

/**
 * @dev Mock implementation of {ERC7984Advanced}.
 */
contract ERC7984AdvancedMock is TokenMock, ERC7984Advanced {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984Advanced(name, symbol, contractURI) {}

    function mint(address to, euint256 amount) external override returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external override returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}
