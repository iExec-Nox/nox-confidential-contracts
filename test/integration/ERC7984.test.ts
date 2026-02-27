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

        // TODO: Add more tests
    });
});
