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

const { RLN, Withdraw } = require('semaphore-lib');

const RLN_ZERO_VALUE = BigInt(ethers.utils.solidityKeccak256(['bytes'], [ethers.utils.toUtf8Bytes('RLN')])) % SNARK_FIELD_SIZE;
const NOTES_ZERO_VALUE = BigInt(ethers.utils.solidityKeccak256(['bytes'], [ethers.utils.toUtf8Bytes('FAIR')])) % SNARK_FIELD_SIZE;

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

        const fairDistribution = await FairDistribution.deploy(1, 15, 20);
        await fairDistribution.deployed();

        RLN.setHasher('poseidon');
        const identity = RLN.genIdentity();
        const identitySecret = RLN.calculateIdentitySecret(identity);
    
        const leafIndex = 3;
        const idCommitments = [];
    
        for (let i=0; i<leafIndex;i++) {
          const tmpIdentity = RLN.genIdentity();
          const tmpSecret = RLN.calculateIdentitySecret(tmpIdentity);
          const tmpCommitment = RLN.genIdentityCommitment(tmpSecret);
          idCommitments.push(tmpCommitment);
        }

        const promises = idCommitments.map(async (id) => {
            const index = await fairDistribution.insertIdentity(id);
            return index;
          });
    
        await Promise.all(promises);
    
        idCommitments.push(RLN.genIdentityCommitment(identitySecret));
        await fairDistribution.insertIdentity(RLN.genIdentityCommitment(identitySecret));
    
        const noteSecret = Fq.random();
        const noteNullifier = Fq.random();
    
        const noteCommitmnet = circomlib.poseidon([noteSecret, noteNullifier]);
        const noteNullifierHash = Withdraw.genNullifierHash(noteNullifier);
    
        const signal = bigintConversion.bigintToText(noteCommitmnet);
        const signalHash = RLN.genSignalHash(signal);
        const epoch = RLN.genExternalNullifier('test-epoch');
    
        const rlnIdentifier = RLN.genIdentifier();
    
        const wasmFilePath = path.join('./rln-zkeyFiles', 'rln.wasm');
        const finalZkeyPath = path.join('./rln-zkeyFiles', 'rln_final.zkey');
    
        const witnessData = await RLN.genProofFromIdentityCommitments(identitySecret, epoch, signal, wasmFilePath, finalZkeyPath, idCommitments, 15, RLN_ZERO_VALUE, 2, rlnIdentifier);
    
        const a1 = RLN.calculateA1(identitySecret, epoch, rlnIdentifier);
        const y = RLN.calculateY(a1, identitySecret, signalHash);
        const nullifier = RLN.genNullifier(a1, rlnIdentifier);
    
        const pubSignals = [y, witnessData.root, nullifier, signalHash, epoch, rlnIdentifier];

        const { fullProof, root } = witnessData;
        const solidityProof = RLN.packToSolidityProof(fullProof);

        const packedProof = await fairDistribution.packProof(
            solidityProof.a, 
            solidityProof.b, 
            solidityProof.c,
        );

        let leaf = await fairDistribution.deposit(packedProof, noteCommitmnet, ethers.utils.hexlify(ethers.utils.toUtf8Bytes(signal)), y, root, nullifier, epoch, rlnIdentifier, { value: "1" });

        const notesTree = RLN.createTree(20, NOTES_ZERO_VALUE, 2);
        // if verification was ok, add note_commitment to tree and try to withdraw it
        if(leaf) {
            console.log('DEPOSIT WAS SUCCESSFUL');
            const withdrawalVkeyPath = path.join('./w-zkeyFiles', 'verification_key.json');
            const withdrawalVKey = JSON.parse(fs.readFileSync(withdrawalVkeyPath, 'utf-8'));
        
            const withdrawalWasmFilePath = path.join('./w-zkeyFiles', 'withdraw.wasm');
            const withdrawalFinalZkeyPath = path.join('./w-zkeyFiles', 'withdraw_final.zkey');
    
            notesTree.insert(noteCommitmnet);
            
            const withdrawalMerkleProof = notesTree.genMerklePath(0);
            const fullProofW = await Withdraw.genProofFromBuiltTree(noteSecret, noteNullifier, withdrawalMerkleProof, withdrawalWasmFilePath, withdrawalFinalZkeyPath);
        
            const [owner, addr1] = await ethers.getSigners();
    
            const WsolidityProof = RLN.packToSolidityProof(fullProofW);

            const WpackedProof = await fairDistribution.packProof(
                WsolidityProof.a, 
                WsolidityProof.b, 
                WsolidityProof.c,
            );
    
            await fairDistribution.withdraw(WpackedProof, notesTree.root, noteNullifierHash, addr1.address);

        }

  });
});
