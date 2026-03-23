import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";
import solc from "./.solc.json" with { type: "json" };

const baseProfile = {
    version: solc.version,
    settings: {
        evmVersion: "osaka",
    },
} as const;

export default defineConfig({
    plugins: [hardhatToolboxViemPlugin],
    solidity: {
        profiles: {
            default: baseProfile,
            production: {
                version: baseProfile.version,
                settings: {
                    ...baseProfile.settings,
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        },
        // Required for Hardhat to compile and link the Nox library used in Solidity tests.
        npmFilesToBuild: ["@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol"],
    },
    networks: {
        hardhatMainnet: {
            type: "edr-simulated",
            chainType: "l1",
        },
        hardhatOp: {
            type: "edr-simulated",
            chainType: "op",
        },
        sepolia: {
            type: "http",
            chainType: "l1",
            url: configVariable("SEPOLIA_RPC_URL"),
            accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
        },
    },
});
