const { expect } = require("chai");
const { ethers } = require("hardhat");
const path = require('path');
const fs = require('fs');
const SNARK_FIELD_SIZE = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const ZqField = require('ffjavascript').ZqField;
const Fq = new ZqField(SNARK_FIELD_SIZE);
const poseidonGenContract = require('circomlib/src/poseidon_gencontract.js');
const circomlib = require('circomlib');
const bigintConversion = require('bigint-conversion');

const { FastSemaphore, Withdraw } = require('semaphore-lib');

const SEMAPHORE_ZERO_VALUE = BigInt(ethers.utils.solidityKeccak256(['bytes'], [ethers.utils.toUtf8Bytes('SEMAPHORE')])) % SNARK_FIELD_SIZE;
const NOTES_ZERO_VALUE = BigInt(ethers.utils.solidityKeccak256(['bytes'], [ethers.utils.toUtf8Bytes('NOTES')])) % SNARK_FIELD_SIZE;

describe("FairDistribution", function () {
  it("Should test full deposit and withdrawal pipeline", async function () {

        const PoseidonT3 = await ethers.getContractFactory(
            poseidonGenContract.generateABI(2),
            poseidonGenContract.createCode(2)
        )
        const poseidonT3 = await PoseidonT3.deploy();
        await poseidonT3.deployed();


        const PoseidonT6 = await ethers.getContractFactory(
            poseidonGenContract.generateABI(5),
            poseidonGenContract.createCode(5)
        );
        const poseidonT6 = await PoseidonT6.deploy();
        await poseidonT6.deployed();

        const FairDistribution = await ethers.getContractFactory("FairDistribution", {
            libraries: {
                PoseidonT3: poseidonT3.address,
                PoseidonT6: poseidonT6.address,
            }
        });

        //deposit, limit, semaphore_tree_levels, notes_tree_levels, _inital_epoch
        FastSemaphore.setHasher('poseidon');
        const initialEpoch = FastSemaphore.genExternalNullifier('initial-epoch');
        const fairDistribution = await FairDistribution.deploy(1, 3, 20, 20, initialEpoch);
        await fairDistribution.deployed();

        const identity = FastSemaphore.genIdentity();
        const identityCommitment = FastSemaphore.genIdentityCommitment(identity);

        const leafIndex = 3;
        const idCommitments = [];

        for (let i=0; i<leafIndex;i++) {
          const tmpIdentity = FastSemaphore.genIdentity();
          const tmpCommitment = FastSemaphore.genIdentityCommitment(tmpIdentity);
          idCommitments.push(tmpCommitment);
        }

        const promises = idCommitments.map(async (id) => {
            const index = await fairDistribution.insertIdentity(id);
            return index;
        });
    
        await Promise.all(promises);
        idCommitments.push(identityCommitment);
    
        await fairDistribution.insertIdentity(identityCommitment);
    
        const noteSecret = Fq.random();
        const noteNullifier = Fq.random();
    
        let noteCommitmnet = circomlib.poseidon([noteSecret, noteNullifier]);
        noteCommitmnet = `0x${bigintConversion.bigintToHex(noteCommitmnet)}`;
        const noteNullifierHash = Withdraw.genNullifierHash(noteNullifier);

        const wasmFilePath = path.join('./semaphore-zkeyFiles', 'semaphore.wasm');
        const finalZkeyPath = path.join('./semaphore-zkeyFiles', 'semaphore_final.zkey');
    
        const witnessData = await FastSemaphore.genProofFromIdentityCommitments(identity, initialEpoch, noteCommitmnet, wasmFilePath, finalZkeyPath, idCommitments, 20, SEMAPHORE_ZERO_VALUE, 2, false);
        
        const { fullProof, root } = witnessData;
        const solidityProof = FastSemaphore.packToSolidityProof(fullProof);
        
        const packedProof = await fairDistribution.packProof(
            solidityProof.a, 
            solidityProof.b, 
            solidityProof.c,
        );

        const nullifierHash = FastSemaphore.genNullifierHash(initialEpoch, identity.identityNullifier, 20);
        
        let leaf = await fairDistribution.deposit(packedProof, bigintConversion.hexToBigint(noteCommitmnet.slice(2)), root, nullifierHash, { value: "1" });

        // if verification was ok, add note_commitment to tree and try to withdraw it
        if(leaf) {
            console.log('DEPOSIT WAS SUCCESSFUL');
            const notesTree = FastSemaphore.createTree(20, NOTES_ZERO_VALUE, 2);
            const withdrawalVkeyPath = path.join('./w-zkeyFiles', 'verification_key.json');
            const withdrawalVKey = JSON.parse(fs.readFileSync(withdrawalVkeyPath, 'utf-8'));
        
            const withdrawalWasmFilePath = path.join('./w-zkeyFiles', 'withdraw.wasm');
            const withdrawalFinalZkeyPath = path.join('./w-zkeyFiles', 'withdraw_final.zkey');
        
            notesTree.insert(bigintConversion.hexToBigint(noteCommitmnet.slice(2)));
        
            const withdrawalMerkleProof = notesTree.genMerklePath(0);

            console.log(notesTree.root);
            const rawRoot = await fairDistribution.getRoot();
            console.log(bigintConversion.hexToBigint(rawRoot._hex.slice(2)))

            const fullProofW = await Withdraw.genProofFromBuiltTree(noteSecret, noteNullifier, withdrawalMerkleProof, withdrawalWasmFilePath, withdrawalFinalZkeyPath);
        
            const pubSignals = [notesTree.root, noteNullifierHash];
        
            const withdrawalRes = await Withdraw.verifyProof(withdrawalVKey, { proof: fullProofW.proof, publicSignals: pubSignals })
            if (withdrawalRes === true) {
                console.log("Withdrawal verification OK");
            } else {
                console.log("Withdrawal invalid proof");
            }

            const [owner, addr1] = await ethers.getSigners();

            const WsolidityProof = FastSemaphore.packToSolidityProof(fullProofW);

            const WpackedProof = await fairDistribution.packProof(
                WsolidityProof.a, 
                WsolidityProof.b, 
                WsolidityProof.c,
            );

            await fairDistribution.withdraw(WpackedProof, notesTree.root, noteNullifierHash, addr1.address);
            const shares = await fairDistribution.shares(addr1.address);

            console.log(shares);
        }

  });
});
