import NoxComputeModule from "@iexec-nox/nox-protocol-contracts/ignition/modules/NoxCompute.ts";
import config from "@iexec-nox/nox-protocol-contracts/config/config.ts";
import connection from "./utils/hardhat-connection-singleton.ts";

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
    const chainConfig = config[connection.networkName];
    if (!chainConfig) {
        throw new Error(`No chain config found for network: ${connection.networkName}`);
    }

    const kmsPublicKey = process.env.KMS_PUBLIC_KEY ?? chainConfig.kmsPublicKey;
    if (!kmsPublicKey) {
        throw new Error("KMS_PUBLIC_KEY environment variable is required");
    }

    const { proxy: noxComputeProxy } = await connection.ignition.deploy(NoxComputeModule, {
        deploymentId: connection.networkName,
        displayUi: printLogs,
        strategy: "create2",
        parameters: {
            NoxCompute: {
                initialOwner: chainConfig.initialOwner,
                kmsPublicKey,
            },
        },
    });
    _log(`NoxCompute: ${noxComputeProxy.address}`);

    const noxCompute = await viem.getContractAt("NoxCompute", noxComputeProxy.address);
    return { noxCompute };
}

// Execute the deployment only if the script is run directly.
// This disables execution when the file is imported as a module.
if (_isHardhatRunCommand()) {
    await deploy();
}

function _isHardhatRunCommand() {
    // When running `hardhat run scripts/deploy.ts`, the argv looks like:
    // [ "/.../bin/node", "/.../cli.js", "run", "scripts/deploy.ts"];
    return process.argv.length >= 4 && process.argv[2] === "run" && process.argv[3].includes("scripts/deploy.ts");
}
