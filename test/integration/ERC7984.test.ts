import { afterEach, beforeEach, describe, it } from "node:test";
import assert from "node:assert";
import { zeroHash, encodeAbiParameters } from "viem";
import { loadFixture } from "../utils/fixture.ts";
import connection from "../../scripts/utils/hardhat-connection-singleton.ts";
import { OffChainServices } from "../utils/OffChainServicesMock.ts";
import { TEEType } from "../utils/TEEType.ts";

const TOKEN_NAME = "Confidential Token";
const TOKEN_SYMBOL = "CTK";
const TOKEN_CONTRACT_URI = "https://example.com/token";

let noxCompute: Awaited<ReturnType<typeof loadFixture>>["noxCompute"];
let admin: Awaited<ReturnType<typeof loadFixture>>["admin"];
let user: Awaited<ReturnType<typeof loadFixture>>["wallet1"];
let user2: Awaited<ReturnType<typeof loadFixture>>["wallet2"];
let gateway: Awaited<ReturnType<typeof loadFixture>>["gateway"];
let offChainServices: OffChainServices;

describe("[IT] ERC7984", function () {
    beforeEach(async function () {
        ({ noxCompute, admin, wallet1: user, wallet2: user2, gateway } = await loadFixture());
        offChainServices = new OffChainServices(noxCompute.address, gateway);
        await offChainServices.start();
    });

    afterEach(async function () {
        await offChainServices.stop();
    });

    // ============ Mint Tests ============

    describe("mint", function () {
        it("Should mint tokens to a recipient", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const mintAmount = 1_000_000n;
            const { handle: amountHandle, proof: amountProof } = await offChainServices.generateAndStoreHandle(
                mintAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, amountHandle, amountProof], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const totalSupplyHandle = await token.read.confidentialTotalSupply();
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);

            assert.notEqual(totalSupplyHandle, zeroHash, "totalSupply handle should be set");
            assert.notEqual(adminBalanceHandle, zeroHash, "admin balance handle should be set");
            assert.equal(offChainServices.decrypt(totalSupplyHandle), mintAmount);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), mintAmount);
        });

        it("Should mint tokens to multiple recipients", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const amount1 = 1_000n;
            const amount2 = 2_000n;

            const { handle: h1, proof: p1 } = await offChainServices.generateAndStoreHandle(
                amount1,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, h1, p1], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const { handle: h2, proof: p2 } = await offChainServices.generateAndStoreHandle(
                amount2,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([user.account.address, h2, p2], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const totalSupplyHandle = await token.read.confidentialTotalSupply();
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const userBalanceHandle = await token.read.confidentialBalanceOf([user.account.address]);

            assert.equal(offChainServices.decrypt(totalSupplyHandle), amount1 + amount2);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), amount1);
            assert.equal(offChainServices.decrypt(userBalanceHandle), amount2);
        });
    });

    // ============ Transfer Tests ============

    describe("confidentialTransfer (with external handle + proof)", function () {
        it("Should transfer tokens from admin to user", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 1_000_000n;
            const transferAmount = 1_000n;

            // Mint initial supply to admin.
            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            // Transfer from admin to user.
            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                transferAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.confidentialTransfer([user.account.address, transferHandle, transferProof], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const totalSupplyHandle = await token.read.confidentialTotalSupply();
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const userBalanceHandle = await token.read.confidentialBalanceOf([user.account.address]);

            assert.equal(offChainServices.decrypt(totalSupplyHandle), totalSupply);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply - transferAmount);
            assert.equal(offChainServices.decrypt(userBalanceHandle), transferAmount);
        });

        it("Should do nothing when transferring more than the sender balance (all-or-nothing)", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 1_000n;
            const excessAmount = 2_000n;

            // Mint initial supply.
            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            // Attempt to transfer more than balance.
            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                excessAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.confidentialTransfer([user.account.address, transferHandle, transferProof], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            // Balances should be unchanged due to all-or-nothing semantics.
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const userBalanceHandle = await token.read.confidentialBalanceOf([user.account.address]);

            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply);
            // user balance handle may be zero hash if user never received any tokens
            // OR it may be set to an encrypted 0. Check both cases.
            if (userBalanceHandle !== zeroHash) {
                assert.equal(offChainServices.decrypt(userBalanceHandle), 0n);
            }
        });

        it("Should transfer zero tokens (no-op)", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 1_000n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const { handle: zeroHandle, proof: zeroProof } = await offChainServices.generateAndStoreHandle(
                0n,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.confidentialTransfer([user.account.address, zeroHandle, zeroProof], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply);
        });
    });

    // ============ Burn Tests ============

    describe("burn", function () {
        it("Should burn tokens from a holder", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 1_000n;
            const burnAmount = 400n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const { handle: burnHandle, proof: burnProof } = await offChainServices.generateAndStoreHandle(
                burnAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.burn([admin.account.address, burnHandle, burnProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const totalSupplyHandle = await token.read.confidentialTotalSupply();
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);

            assert.equal(offChainServices.decrypt(totalSupplyHandle), totalSupply - burnAmount);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply - burnAmount);
        });

        it("Should do nothing when burning more than balance (all-or-nothing)", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 100n;
            const excessBurn = 200n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const { handle: burnHandle, proof: burnProof } = await offChainServices.generateAndStoreHandle(
                excessBurn,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.burn([admin.account.address, burnHandle, burnProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const totalSupplyHandle = await token.read.confidentialTotalSupply();
            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);

            // All-or-nothing: burn should have no effect since excessBurn > balance.
            assert.equal(offChainServices.decrypt(totalSupplyHandle), totalSupply);
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply);
        });
    });

    // ============ TransferAndCall Tests ============

    describe("confidentialTransferAndCall", function () {
        it("Should transfer and call receiver, receiver accepts", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const receiver = await connection.viem.deployContract("ERC7984ReceiverMock", []);
            const totalSupply = 1_000n;
            const transferAmount = 300n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            // data = abi.encode(uint8(1)) => receiver returns true (accepts transfer)
            const data = encodeAbiParameters([{ type: "uint8" }], [1]);
            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                transferAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.confidentialTransferAndCall([receiver.address, transferHandle, transferProof, data], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const receiverBalanceHandle = await token.read.confidentialBalanceOf([receiver.address]);

            // Receiver accepted: full amount transferred.
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply - transferAmount);
            assert.equal(offChainServices.decrypt(receiverBalanceHandle), transferAmount);
        });

        it("Should refund sender when receiver rejects the transfer", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const receiver = await connection.viem.deployContract("ERC7984ReceiverMock", []);
            const totalSupply = 1_000n;
            const transferAmount = 300n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            // data = abi.encode(uint8(0)) => receiver returns false (rejects transfer)
            const data = encodeAbiParameters([{ type: "uint8" }], [0]);
            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                transferAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.confidentialTransferAndCall([receiver.address, transferHandle, transferProof, data], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const receiverBalanceHandle = await token.read.confidentialBalanceOf([receiver.address]);

            // Receiver rejected: tokens should be refunded to admin.
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply);
            // Receiver balance should be 0 (encrypted).
            if (receiverBalanceHandle !== zeroHash) {
                assert.equal(offChainServices.decrypt(receiverBalanceHandle), 0n);
            }
        });

        it("Should transfer full amount to EOA (no callback)", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 500n;
            const transferAmount = 200n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                transferAmount,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            // Transfer to EOA (user.account.address, no code) with empty data.
            await token.write.confidentialTransferAndCall([user.account.address, transferHandle, transferProof, "0x"], {
                account: admin.account,
            });
            await offChainServices.waitForEventProcessing();

            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const userBalanceHandle = await token.read.confidentialBalanceOf([user.account.address]);

            // EOA: callback is skipped, full amount is transferred.
            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply - transferAmount);
            assert.equal(offChainServices.decrypt(userBalanceHandle), transferAmount);
        });
    });

    // ============ Operator Tests ============

    describe("confidentialTransferFrom (with operator)", function () {
        it("Should allow operator to transfer on behalf of holder", async function () {
            const token = await connection.viem.deployContract("ERC7984Mock", [
                TOKEN_NAME,
                TOKEN_SYMBOL,
                TOKEN_CONTRACT_URI,
                admin.account.address,
            ]);
            const totalSupply = 5_000n;
            const transferAmount = 1_000n;

            const { handle: mintHandle, proof: mintProof } = await offChainServices.generateAndStoreHandle(
                totalSupply,
                TEEType.Uint256,
                admin.account.address,
                token.address,
            );
            await token.write.mint([admin.account.address, mintHandle, mintProof], { account: admin.account });
            await offChainServices.waitForEventProcessing();

            // Admin sets user as operator (far future expiry).
            const until = BigInt(Math.floor(Date.now() / 1000) + 3600);
            await token.write.setOperator([user.account.address, until], { account: admin.account });

            // User transfers from admin to user2 on admin's behalf.
            const { handle: transferHandle, proof: transferProof } = await offChainServices.generateAndStoreHandle(
                transferAmount,
                TEEType.Uint256,
                user.account.address,
                token.address,
            );
            await token.write.confidentialTransferFrom(
                [admin.account.address, user2.account.address, transferHandle, transferProof],
                { account: user.account },
            );
            await offChainServices.waitForEventProcessing();

            const adminBalanceHandle = await token.read.confidentialBalanceOf([admin.account.address]);
            const user2BalanceHandle = await token.read.confidentialBalanceOf([user2.account.address]);

            assert.equal(offChainServices.decrypt(adminBalanceHandle), totalSupply - transferAmount);
            assert.equal(offChainServices.decrypt(user2BalanceHandle), transferAmount);
        });
    });
});
