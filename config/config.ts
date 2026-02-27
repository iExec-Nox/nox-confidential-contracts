export default {
    // Default Hardhat network.
    default: {
        chainId: 31337,
        initialOwner: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", // Hardhat Account #0
        kmsPublicKey: "0x026f0005c5c3807e69dcbe52a97ca55aa26c8655999b5a81f5098666cd7dd5d1f6",
    },
} as {
    [network: string]: {
        chainId: number;
        initialOwner: string;
        kmsPublicKey?: string;
    };
};
