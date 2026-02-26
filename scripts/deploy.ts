import NoxComputeModule from "@iexec-nox/nox-protocol-contracts/ignition/modules/NoxCompute.ts";
import connection from "./utils/hardhat-connection-singleton.ts";

const INITIAL_OWNER = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"; // Hardhat Account #0
const KMS_PUBLIC_KEY = "0x026f0005c5c3807e69dcbe52a97ca55aa26c8655999b5a81f5098666cd7dd5d1f6";

/**
 * Deploys the Nox protocol infrastructure (NoxCompute) needed for integration tests.
 * Uses the same CREATE2 salt and compiler settings as nox-protocol-contracts to deploy
 * at the deterministic address hardcoded in the Nox SDK library for chainId 31337.
 *
 * @param printLogs whether to print deployment messages or not
 * @returns Viem contract instance for the deployed NoxCompute proxy
 */
export async function deploy(printLogs = true) {
    const _log = printLogs ? console.log : () => {};
    const { viem } = connection;

    const { proxy: noxComputeProxy } = await connection.ignition.deploy(NoxComputeModule, {
        deploymentId: connection.networkName,
        displayUi: printLogs,
        strategy: "create2",
        parameters: {
            NoxCompute: {
                initialOwner: INITIAL_OWNER,
                kmsPublicKey: KMS_PUBLIC_KEY,
            },
        },
    });
    _log(`NoxCompute: ${noxComputeProxy.address}`);

    const noxCompute = await viem.getContractAt("NoxCompute", noxComputeProxy.address);
    return { noxCompute };
}
