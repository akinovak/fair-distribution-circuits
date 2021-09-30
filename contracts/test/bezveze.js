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

describe("Greeter", function () {
  it.skip("Withdrawal", async function () {
    const noteSecret = Fq.random();
    const noteNullifier = Fq.random();

    const noteCommitmnet = circomlib.poseidon([noteSecret, noteNullifier]);
    const noteNullifierHash = Withdraw.genNullifierHash(noteNullifier);

    const leaf = 2;

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

        const pubSignals = [notesTree.root, noteNullifierHash];


        const withdrawalRes = await Withdraw.verifyProof(withdrawalVKey, { proof: fullProofW.proof, publicSignals: fullProofW.publicSignals })
        if (withdrawalRes === true) {
            console.log("Withdrawal verification OK");
        } else {
            console.log("Withdrawal invalid proof");
        }

        // const [owner, addr1] = await ethers.getSigners();

        // console.log(pubSignals);
        // console.log(fullProofW.publicSignals)

        // await fairDistribution.withdraw(packedProof, notesTree.root, noteNullifierHash, addr1.address);

    }


  });
});
