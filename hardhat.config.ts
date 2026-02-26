import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";

// Same CREATE2 salt as nox-protocol-contracts @ v0.1.0-beta.4.
// Ensures ACL and NoxCompute are deployed at the deterministic addresses
// hardcoded in the Nox SDK library for chainId 31337.
const CREATE2_SALT = "0x7ca392fef4d64c717e8251af66db8361674f99ec878f738bf72f4a9e6074bac7";

export default defineConfig({
    plugins: [hardhatToolboxViemPlugin],
    ignition: {
        strategyConfig: {
            create2: {
                salt: CREATE2_SALT,
            },
        },
    },
    solidity: {
        profiles: {
            default: {
                version: "0.8.34",
                settings: {
                    evmVersion: "osaka",
                    metadata: {
                        bytecodeHash: "none",
                    },
                },
            },
            production: {
                version: "0.8.34",
                settings: {
                    evmVersion: "osaka",
                    metadata: {
                        bytecodeHash: "none",
                    },
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                    viaIR: true,
                },
            },
        },
        npmFilesToBuild: [
            "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol",
            "@iexec-nox/nox-protocol-contracts/contracts/NoxCompute.sol",
        ],
    },
    networks: {
        default: {
            type: "edr-simulated",
            chainType: "op",
        },
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
