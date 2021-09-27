include "../common/tree/incrementalMerkleTree.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template CalculateIdentityCommitment() {
    signal input identity_secret;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== identity_secret;

    out <== hasher.out;
}

template CalculateA1() {
    signal input a_0;
    signal input epoch;

    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== a_0;
    hasher.inputs[1] <== epoch;

    out <== hasher.out;
}


template CalculateNullifier() {
    signal input a_1;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== a_1;

    out <== hasher.out;
}

template Deposit(n_levels) {

    //constants
    var LEAVES_PER_NODE = 2;
    var LEAVES_PER_PATH_LEVEL = LEAVES_PER_NODE - 1;


    //private signals
    signal private input identity_secret;
    signal private input path_elements[n_levels][LEAVES_PER_PATH_LEVEL];
    signal private input identity_path_index[n_levels];

    //public signals
    signal input x; // x is actually just the secret hash
    signal input epoch;

    //outputs
    signal output y;
    signal output root;
    signal output nullifier;

    //begin identity commitment
    component identity_commitment = CalculateIdentityCommitment();
    identity_commitment.identity_secret <== identity_secret;
    //end identity commitment


    //begin tree
    var i;
    var j;
    component inclusionProof = MerkleTreeInclusionProof(n_levels);
    inclusionProof.leaf <== identity_commitment.out;

    for (i = 0; i < n_levels; i++) {
      for (j = 0; j < LEAVES_PER_PATH_LEVEL; j++) {
        inclusionProof.path_elements[i][j] <== path_elements[i][j];
      }
      inclusionProof.path_index[i] <== identity_path_index[i];
    }

    root <== inclusionProof.root;
    //end tree

    // 2. Part
    // Line Equation Constaints
    // a_1 = hash(a_0, epoch)
    // share_y == a_0 + a_1 * share_x
    component a_1 = CalculateA1();
    a_1.a_0 <== identity_secret;
    a_1.epoch <== epoch;

    y <== identity_secret + a_1.out * x;
    component calculateNullifier = CalculateNullifier();
    calculateNullifier.a_1 <== a_1.out;

    nullifier <== calculateNullifier.out;
}