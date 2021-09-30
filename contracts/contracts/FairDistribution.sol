//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { IncrementalQuinTree } from "./IncrementalMerkleTree.sol";
import { Verifier as RLNVerifier } from "./RLNVerifier.sol";
import { Verifier as WithdrawVerifier } from "./WithdrawVerifier.sol";
import { Constants } from "./Constants.sol";
import { Utils } from "./Utils.sol";

contract FairDistribution is Constants, Utils {

    uint256 public immutable DEPOSIT;

    IncrementalQuinTree public participantsTree;
    IncrementalQuinTree public notesTree;

    RLNVerifier private rlnVerifier;
    WithdrawVerifier private withdrawVerifier;

    mapping (uint256 => bool) public nullifierHashes;
    mapping (address => uint) public shares;

    event Deposit(uint256 nullifier);

    constructor(uint256 _deposit, uint8 rln_tree_levels, uint8 notes_tree_levels)
    {
        DEPOSIT = _deposit;
        participantsTree = new IncrementalQuinTree(rln_tree_levels, RLN_ZERO_VALUE);
        notesTree = new IncrementalQuinTree(notes_tree_levels, NOTES_ZERO_VALUE);

        rlnVerifier = new RLNVerifier();
        withdrawVerifier = new WithdrawVerifier();
    }

    function insertIdentity(uint256 _identityCommitment) public
        returns (uint256) {
        require(
            _identityCommitment != RLN_ZERO_VALUE,
            "RLN: identity commitment cannot be the zero-value"
        );

        return participantsTree.insertLeaf(_identityCommitment);
    }

    function getRoot() public view returns (uint256) {
        return notesTree.root();
    }

    function deposit(uint256[8] memory _proof, uint256 _commitment, bytes memory _hexified_commitment, uint256 _y, uint256 _root, uint256 _nullifier, uint256 _epoch, uint256 _rlnIdentifier) 
        public 
        payable 
        returns (uint256)
    {
        require(msg.value == DEPOSIT, "RLN: deposit not satisfied!");
        require(participantsTree.rootHistory(_root) == true, "RLN: no root");

        uint256[6] memory publicSignals =
            [_y, _root, _nullifier, hashSignal(_hexified_commitment), _epoch, _rlnIdentifier];         

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            unpackProof(_proof);

        require(
            rlnVerifier.verifyProof(a, b, c, publicSignals),
            "RLN: invalid proof"
        );   

        uint256 leaf = notesTree.insertLeaf(_commitment);
        emit Deposit(_nullifier);
        return leaf;
    }

    function withdraw(uint256[8] memory _proof, uint256 _root, uint256 _nullifierHash, address _recipient) 
        public 
    {

        require(!nullifierHashes[_nullifierHash], "Withdrawal: the note has been already spent");
        require(notesTree.rootHistory(_root) == true, "Withdrawal: no root");

        uint256[2] memory publicSignals = [_root, _nullifierHash];         

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            unpackProof(_proof);

        require(
            withdrawVerifier.verifyProof(a, b, c, publicSignals),
            "Withdrawal: invalid proof"
        );   

        nullifierHashes[_nullifierHash] = true;
        shares[_recipient] = shares[_recipient] + 1; 
    }

    function hashSignal(bytes memory _signal) internal pure returns (uint256) {
        return uint256(keccak256(_signal)) >> 8;
    }

    //TODO add slash function
    //TODO snark field checks

}