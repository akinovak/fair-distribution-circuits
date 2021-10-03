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

describe("Greeter", function () {
  it.skip("Should return the new greeting once it's changed", async function () {
    const noteSecret = Fq.random();
    const noteNullifier = Fq.random();
    const noteCommitmnet = circomlib.poseidon([noteSecret, noteNullifier]);
    const noteNullifierHash = Withdraw.genNullifierHash(noteNullifier);

    const notesTree = FastSemaphore.createTree(20, BigInt(0), 2);
    // if verification was ok, add note_commitment to tree and try to withdraw it
    console.log('DEPOSIT WAS SUCCESSFUL');
    const withdrawalVkeyPath = path.join('./w-zkeyFiles', 'verification_key.json');
    const withdrawalVKey = JSON.parse(fs.readFileSync(withdrawalVkeyPath, 'utf-8'));

    const withdrawalWasmFilePath = path.join('./w-zkeyFiles', 'withdraw.wasm');
    const withdrawalFinalZkeyPath = path.join('./w-zkeyFiles', 'withdraw_final.zkey');

    notesTree.insert(noteCommitmnet);

    const withdrawalMerkleProof = notesTree.genMerklePath(0);
    const fullProof = await Withdraw.genProofFromBuiltTree(noteSecret, noteNullifier, withdrawalMerkleProof, withdrawalWasmFilePath, withdrawalFinalZkeyPath);

    const pubSignals = [notesTree.root, noteNullifierHash];

    const withdrawalRes = await Withdraw.verifyProof(withdrawalVKey, { proof: fullProof.proof, publicSignals: pubSignals })
    if (withdrawalRes === true) {
        console.log("Withdrawal verification OK");
    } else {
        console.log("Withdrawal invalid proof");
    }
    
  });
});
