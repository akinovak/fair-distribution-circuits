include "../common/tree/incrementalMerkleTree.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template CalculateCommitment() {
    signal input note_secret;
    signal input nullifier;
    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== note_secret;
    hasher.inputs[1] <== nullifier;

    out <== hasher.out;
}

template CalculateNullifierHash() {
    signal input nullifier;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== nullifier;

    out <== hasher.out;
}


template Witdraw(n_levels) {

    //constants
    var LEAVES_PER_NODE = 2;
    var LEAVES_PER_PATH_LEVEL = LEAVES_PER_NODE - 1;

    // private inputs
    signal private input note_secret;
    signal private input nullifier;
    signal private input path_elements[n_levels][LEAVES_PER_PATH_LEVEL];
    signal private input path_indices[n_levels];

    // public inputs
    signal input root;
    signal input nullifier_hash;

    component note_commitment = CalculateCommitment();
    note_commitment.note_secret <== note_secret;
    note_commitment.nullifier <== nullifier;

        //begin tree
    var i;
    var j;
    component inclusionProof = MerkleTreeInclusionProof(n_levels);
    inclusionProof.leaf <== note_commitment.out;

    for (i = 0; i < n_levels; i++) {
      for (j = 0; j < LEAVES_PER_PATH_LEVEL; j++) {
        inclusionProof.path_elements[i][j] <== path_elements[i][j];
      }
      inclusionProof.path_index[i] <== path_indices[i];
    }

    root <== inclusionProof.root;
    //end tree

    component nullifier_hasher = CalculateNullifierHash();
    nullifier_hasher.nullifier <== nullifier;

    nullifier_hash <== nullifier_hasher.out;

}