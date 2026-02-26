import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";
import { deploy } from "../../scripts/deploy.ts";
import connection from "../../scripts/utils/hardhat-connection-singleton.ts";

export async function loadFixture() {
    return await connection.networkHelpers.loadFixture(deployFixture);
}

/**
 * Deploys NoxCompute and sets up a test gateway.
 * NoxCompute is deployed at the deterministic CREATE2 address hardcoded in the Nox SDK for chainId 31337.
 */
async function deployFixture() {
    const viem = connection.viem;
    const publicClient = await viem.getPublicClient();
    const deployment = await deploy(false);
    const accounts = await viem.getWalletClients();
    const gateway = privateKeyToAccount(generatePrivateKey());
    const tx = await deployment.noxCompute.write.setGateway([gateway.address]);
    await publicClient.waitForTransactionReceipt({ hash: tx });
    return {
        ...deployment,
        admin: accounts[0],
        wallet1: accounts[1],
        wallet2: accounts[2],
        wallet3: accounts[3],
        gateway,
    };
}
