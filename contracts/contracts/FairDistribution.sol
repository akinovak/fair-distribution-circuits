//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { IncrementalQuinTree } from "./IncrementalMerkleTree.sol";
import { Verifier as SemaphoreVerifier } from "./SemaphoreVerifier.sol";
import { Verifier as WithdrawVerifier } from "./WithdrawVerifier.sol";
import "./Ownable.sol";
import { Constants } from "./Constants.sol";
import { Utils } from "./Utils.sol";

contract FairDistribution is Constants, Utils, Ownable {

    uint256 public immutable DEPOSIT;
    uint8 public immutable LIMIT;
    uint256 public CURRENT_EPOCH;


    IncrementalQuinTree public participantsTree;
    IncrementalQuinTree public notesTree;

    SemaphoreVerifier private semaphoreVerifier;
    WithdrawVerifier private withdrawVerifier;

    mapping (uint256 => uint) public numOfDeposits;
    mapping (uint256 => bool) public nullifierHashes;
    mapping (address => uint) public shares;

    // event Deposit(uint256 nullifier);

    constructor(uint256 _deposit, uint8 _limit, uint8 semaphore_tree_levels, uint8 notes_tree_levels, uint256 _inital_epoch)
        Ownable()
    {
        DEPOSIT = _deposit;
        LIMIT = _limit;
        CURRENT_EPOCH = _inital_epoch;

        participantsTree = new IncrementalQuinTree(semaphore_tree_levels, SEMAPHORE_ZERO_VALUE);
        notesTree = new IncrementalQuinTree(notes_tree_levels, NOTES_ZERO_VALUE);

        semaphoreVerifier = new SemaphoreVerifier();
        withdrawVerifier = new WithdrawVerifier();
    }

    function insertIdentity(uint256 _identityCommitment) public
        returns (uint256) {
        require(
            _identityCommitment != SEMAPHORE_ZERO_VALUE,
            "Semaphore: identity commitment cannot be the zero-value"
        );

        return participantsTree.insertLeaf(_identityCommitment);
    }

    function getRoot() public view returns (uint256) {
        return notesTree.root();
    }

    function setCurrentEpoch(uint256 _epoch) public onlyOwner {
        CURRENT_EPOCH = _epoch;
    }

    function deposit(uint256[8] memory _proof, uint256 _commitment, uint256 _root, uint256 _nullifiersHash) 
        public 
        payable 
        returns (uint256)
    {
        require(msg.value == DEPOSIT, "Deposit: deposit not satisfied!");
        require(numOfDeposits[_nullifiersHash] <= LIMIT, "Deposit: number of deposits for this epoch exceeded!");
        require(participantsTree.rootHistory(_root) == true, "Semaphore: no root");

        uint256[4] memory publicSignals =
            [_root, _nullifiersHash, _commitment, CURRENT_EPOCH];         

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) =
            unpackProof(_proof);

        require(
            semaphoreVerifier.verifyProof(a, b, c, publicSignals),
            "Semaphore: invalid proof"
        );   

        uint256 leaf = notesTree.insertLeaf(_commitment);
        return leaf;
    }

    function withdraw(uint256[8] memory _proof, uint256 _root, uint256 _nullifierHash, address _recipient) 
        public 
    {

        require(nullifierHashes[_nullifierHash], "Withdrawal: the note has been already spent");
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
    
    //TODO snark field checks

}