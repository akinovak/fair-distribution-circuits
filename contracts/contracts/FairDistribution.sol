//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { IncrementalQuinTree } from "./IncrementalMerkleTree.sol";
import { RLNVerifier } from "./RLNVerifier.sol";
import { WithdrawVerifier } from "./WithdrawVerifier.sol";
import { Constants } from "./Constants.sol";

contract FairDistribution is RLNVerifier, WithdrawVerifier, Constants {

    uint256 public immutable DEPOSIT;

    IncrementalQuinTree private participantsTree;
    IncrementalQuinTree private notesTree;

    mapping (uint256 => bool) public nullifierHashes;
    mapping (address => uint) public shares;

    event Deposit(uint256 nullifier);

    constructor(uint256 _deposit, uint8 rln_tree_levels, uint8 notes_tree_levels)
    {
        DEPOSIT = _deposit;
        participantsTree = new IncrementalQuinTree(rln_tree_levels, RLN_ZERO_VALUE);
        notesTree = new IncrementalQuinTree(notes_tree_levels, NOTES_ZERO_VALUE);
    }

    function insertIdentity(uint256 _identityCommitment) public
        returns (uint256) {
        // Ensure that the given identity commitment is not the zero value
        require(
            _identityCommitment != RLN_ZERO_VALUE,
            "RLN: identity commitment cannot be the zero-value"
        );

        return participantsTree.insertLeaf(_identityCommitment);
    }

    modifier isValidRlnProof(uint256[8] memory _proof, uint256 _commitment, uint256 _y, uint256 _root, uint256 _nullifier, uint256 _epoch, uint256 _rlnIdentifier) {
        uint256[6] memory publicSignals =
            [_y, _root, _nullifier, _commitment, _epoch, _rlnIdentifier];         

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            unpackProof(_proof);

        require(
            verifyProofRLN(a, b, c, publicSignals),
            "RLN: invalid proof"
        );   

        _;
    }

    modifier doesRootExists(mapping (uint256 => bool) storage rootHistory, uint256 _root) {
        require(rootHistory[_root], "Root not seen");
        _;
    }

    modifier isDepositSatisfied() {
        require(msg.value == DEPOSIT, "RLN: deposit not satisfied!");
        _;
    }

    modifier isValidWithdrawProof(uint256[8] memory _proof, uint256 _root, uint256 _nullifierHash) {
        require(!nullifierHashes[_nullifierHash], "Withdrawal: the note has been already spent");
        require(notesTree.rootHistory[_root] == true, "Withdrawal: no root");

        uint256[2] memory publicSignals = [ _root, _nullifierHash];         

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            unpackProof(_proof);

        require(
            verifyProofWithdraw(a, b, c, publicSignals),
            "Withdrawal: invalid proof"
        );   

        _;
    }

    function deposit(uint256[8] memory _proof, uint256 _commitment, uint256 _y, uint256 _root, uint256 _nullifier, uint256 _epoch, uint256 _rlnIdentifier) 
        public 
        isDepositSatisfied()
        doesRootExists(participantsTree.rootHistory, _root)
        isValidRlnProof(_proof, _commitment, _y, _root, _nullifier, _epoch, _rlnIdentifier)
        returns (uint256)
    {
        return notesTree.insertLeaf(_commitment);
        emit Deposit(_nullifier);
    }

    function withdraw(uint256 _root, uint256 _nullifierHash, address _recipient) 
        isValidWithdrawProof(_root, _nullifierHash)
        external 
    {
        nullifierHashes[_nullifierHash] = true;
        shares[_recipient] = shares[_recipient] + 1; 
    }

    //TODO add slash function

    function packProof (
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c
    ) public pure returns (uint256[8] memory) {

        return [
            _a[0],
            _a[1], 
            _b[0][0],
            _b[0][1],
            _b[1][0],
            _b[1][1],
            _c[0],
            _c[1]
        ];
    }

    function unpackProof(
        uint256[8] memory _proof
    ) public pure returns (
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory
    ) {

        return (
            [_proof[0], _proof[1]],
            [
                [_proof[2], _proof[3]],
                [_proof[4], _proof[5]]
            ],
            [_proof[6], _proof[7]]
        );
    }

}