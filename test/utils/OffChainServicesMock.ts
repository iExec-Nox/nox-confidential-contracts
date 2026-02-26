// A mock service to simulate the off-chain Runner for ERC7984 integration tests.
// Listens to NoxCompute events and maintains a handle-to-value map,
// replicating the TEE computation semantics defined in the Nox protocol spec.

import { randomBytes } from "crypto";
import connection from "../../scripts/utils/hardhat-connection-singleton.ts";
import { concatHex, parseAbiItem, PrivateKeyAccount, toHex, WatchEventReturnType } from "viem";
import { TEEType } from "./TEEType.ts";

const MAX_UINT256 = 2n ** 256n - 1n;

const eventsToWatch = [
    "event PlaintextToEncrypted(address indexed caller,bytes32 plaintext,uint8 toType,bytes32 result)",
    "event Add(address indexed caller,bytes32 leftHandOperand,bytes32 rightHandOperand,bytes32 result)",
    "event Sub(address indexed caller,bytes32 leftHandOperand,bytes32 rightHandOperand,bytes32 result)",
    "event SafeAdd(address indexed caller,bytes32 leftHandOperand,bytes32 rightHandOperand,bytes32 success,bytes32 result)",
    "event SafeSub(address indexed caller,bytes32 leftHandOperand,bytes32 rightHandOperand,bytes32 success,bytes32 result)",
    "event Select(address indexed caller,bytes32 condition,bytes32 ifTrue,bytes32 ifFalse,bytes32 result)",
];

const client = await connection.viem.getPublicClient();

export class OffChainServices {
    private printLogs = false;
    private noxComputeAddress: `0x${string}`;
    private gateway: PrivateKeyAccount;
    private chainId: number;
    private running = false;
    private handleToValueMap!: Map<`0x${string}`, bigint>;
    private stopWatcher!: WatchEventReturnType;

    constructor(noxComputeAddress: `0x${string}`, gateway: PrivateKeyAccount) {
        this.noxComputeAddress = noxComputeAddress;
        this.gateway = gateway;
        this.chainId = client.chain.id;
    }

    /**
     * Starts the off-chain Runner mock.
     */
    async start() {
        if (this.running) {
            throw new Error("Mock services are already running");
        }
        this.running = true;
        this.handleToValueMap = new Map();
        this.stopWatcher = this._startWatcher();
        this._log("Mock services started");
    }

    /**
     * Stops the off-chain Runner mock.
     */
    async stop() {
        if (!this.running) {
            return;
        }
        this.running = false;
        this.handleToValueMap.clear();
        this.stopWatcher();
        this._log("Mock services stopped");
    }

    /**
     * Simulates the Gateway: generates a handle and its EIP-712 proof, then stores the value.
     */
    async generateAndStoreHandle(
        value: bigint,
        teeType: TEEType,
        userAddress: `0x${string}`,
        appAddress: `0x${string}`,
    ): Promise<{ handle: `0x${string}`; proof: `0x${string}` }> {
        const { handle, proof } = await this.generateHandle(teeType, userAddress, appAddress);
        this._saveHandle(handle, value);
        return { handle, proof };
    }

    /**
     * Generates a random handle and its EIP-712 proof, without storing a value.
     */
    async generateHandle(
        teeType: TEEType,
        userAddress: `0x${string}`,
        appAddress: `0x${string}`,
    ): Promise<{ handle: `0x${string}`; proof: `0x${string}` }> {
        const preHandle = toHex(randomBytes(26));
        const chainIdBytes = toHex(this.chainId, { size: 4 });
        const teeTypeByte = toHex(teeType, { size: 1 });
        const versionByte = toHex(0, { size: 1 });
        const handle = concatHex([preHandle, chainIdBytes, teeTypeByte, versionByte]);
        const createdAt = BigInt(Math.floor(Date.now() / 1000));
        const domain = {
            name: "NoxCompute",
            version: "1",
            chainId: this.chainId,
            verifyingContract: this.noxComputeAddress,
        } as const;
        const types = {
            HandleProof: [
                { name: "handle", type: "bytes32" },
                { name: "owner", type: "address" },
                { name: "app", type: "address" },
                { name: "createdAt", type: "uint256" },
            ],
        } as const;
        const message = {
            handle,
            owner: userAddress,
            app: appAddress,
            createdAt,
        } as const;
        const signature = await this.gateway.signTypedData({ domain, types, primaryType: "HandleProof", message });
        const proof = concatHex([userAddress, appAddress, toHex(createdAt, { size: 32 }), signature]);
        return { handle, proof };
    }

    /**
     * Waits for the event listener to process pending events.
     */
    async waitForEventProcessing() {
        await new Promise((resolve) => setTimeout(resolve, 100));
    }

    /**
     * Simulates decryption by looking up the stored handle value.
     */
    decrypt(handle: `0x${string}`): bigint {
        const value = this.handleToValueMap.get(handle);
        if (value === undefined) {
            throw new Error(`Handle not found: ${handle}`);
        }
        return value;
    }

    private _saveHandle(handle: `0x${string}`, value: bigint) {
        this.handleToValueMap.set(handle, value);
        this._log(`Saved handle: ${handle} -> ${value}`);
    }

    private _startWatcher(): WatchEventReturnType {
        return client.watchEvent({
            address: this.noxComputeAddress,
            events: eventsToWatch.map((e) => parseAbiItem(e)),
            onLogs: (logs) => this._processEvents(logs),
            onError(error) {
                console.error("Event listener error:", error);
            },
        });
    }

    /**
     * Simulates the off-chain Runner: processes NoxCompute events and resolves handles.
     * Implements the computation semantics from the Nox protocol spec.
     */
    private _processEvents(eventLogs: any[]) {
        this._log(`Processing ${eventLogs.length} event(s): ${eventLogs.map((e) => e.eventName).join(", ")}`);
        for (const log of eventLogs) {
            const eventName = log.eventName;
            if (eventName === "PlaintextToEncrypted") {
                this._processPlaintextToEncrypted(log);
            } else if (eventName === "Add") {
                this._processAdd(log);
            } else if (eventName === "Sub") {
                this._processSub(log);
            } else if (eventName === "SafeAdd") {
                this._processSafeAdd(log);
            } else if (eventName === "SafeSub") {
                this._processSafeSub(log);
            } else if (eventName === "Select") {
                this._processSelect(log);
            } else {
                throw new Error(`Unexpected event: ${eventName}`);
            }
        }
    }

    private _processPlaintextToEncrypted(log: any) {
        const { plaintext, result } = log.args as { plaintext: `0x${string}`; result: `0x${string}` };
        this._log(`PlaintextToEncrypted: ${result} -> ${plaintext}`);
        this._saveHandle(result, BigInt(plaintext));
    }

    private _processAdd(log: any) {
        const { leftHandOperand, rightHandOperand, result } = log.args as {
            leftHandOperand: `0x${string}`;
            rightHandOperand: `0x${string}`;
            result: `0x${string}`;
        };
        const lhs = this.decrypt(leftHandOperand);
        const rhs = this.decrypt(rightHandOperand);
        // Wrapping addition (mod 2^256)
        const addResult = (lhs + rhs) & MAX_UINT256;
        this._log(`Add: ${lhs} + ${rhs} = ${addResult}`);
        this._saveHandle(result, addResult);
    }

    private _processSub(log: any) {
        const { leftHandOperand, rightHandOperand, result } = log.args as {
            leftHandOperand: `0x${string}`;
            rightHandOperand: `0x${string}`;
            result: `0x${string}`;
        };
        const lhs = this.decrypt(leftHandOperand);
        const rhs = this.decrypt(rightHandOperand);
        // Wrapping subtraction (mod 2^256)
        const subResult = (lhs - rhs + 2n ** 256n) & MAX_UINT256;
        this._log(`Sub: ${lhs} - ${rhs} = ${subResult}`);
        this._saveHandle(result, subResult);
    }

    // SafeAdd: success = true if no overflow, result = sum; success = false if overflow, result = 0.
    private _processSafeAdd(log: any) {
        const { leftHandOperand, rightHandOperand, success, result } = log.args as {
            leftHandOperand: `0x${string}`;
            rightHandOperand: `0x${string}`;
            success: `0x${string}`;
            result: `0x${string}`;
        };
        const lhs = this.decrypt(leftHandOperand);
        const rhs = this.decrypt(rightHandOperand);
        const sum = lhs + rhs;
        if (sum <= MAX_UINT256) {
            this._log(`SafeAdd success: ${lhs} + ${rhs} = ${sum}`);
            this._saveHandle(success, 1n);
            this._saveHandle(result, sum);
        } else {
            this._log(`SafeAdd overflow: ${lhs} + ${rhs}`);
            this._saveHandle(success, 0n);
            this._saveHandle(result, 0n);
        }
    }

    // SafeSub: success = true if no underflow, result = diff; success = false if underflow, result = 0.
    private _processSafeSub(log: any) {
        const { leftHandOperand, rightHandOperand, success, result } = log.args as {
            leftHandOperand: `0x${string}`;
            rightHandOperand: `0x${string}`;
            success: `0x${string}`;
            result: `0x${string}`;
        };
        const lhs = this.decrypt(leftHandOperand);
        const rhs = this.decrypt(rightHandOperand);
        if (lhs >= rhs) {
            const subResult = lhs - rhs;
            this._log(`SafeSub success: ${lhs} - ${rhs} = ${subResult}`);
            this._saveHandle(success, 1n);
            this._saveHandle(result, subResult);
        } else {
            this._log(`SafeSub underflow: ${lhs} - ${rhs}`);
            this._saveHandle(success, 0n);
            this._saveHandle(result, 0n);
        }
    }

    private _processSelect(log: any) {
        const { condition, ifTrue, ifFalse, result } = log.args as {
            condition: `0x${string}`;
            ifTrue: `0x${string}`;
            ifFalse: `0x${string}`;
            result: `0x${string}`;
        };
        const cond = this.decrypt(condition);
        const trueVal = this.decrypt(ifTrue);
        const falseVal = this.decrypt(ifFalse);
        const selected = cond !== 0n ? trueVal : falseVal;
        this._log(`Select: ${cond} ? ${trueVal} : ${falseVal} = ${selected}`);
        this._saveHandle(result, selected);
    }

    private _log = this.printLogs ? console.log : () => {};
}
