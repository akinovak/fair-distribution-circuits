//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import { IncrementalQuinTree } from "./IncrementalMerkleTree.sol";
// import { Ownable } from "./Ownable.sol";
// import { Verifier } from "./RLNVerifier.sol";

// contract RLN is Ownable, IncrementalQuinTree, Verifier {
//     uint256 public immutable DEPOSIT;

//     uint256 public RLN_ZERO_VALUE = 
//     uint256(keccak256(abi.encodePacked('RLN'))) % SNARK_SCALAR_FIELD;

//     constructor(uint256 _deposit, uint8 _treeLevels)
//         IncrementalQuinTree(_treeLevels, RLN_ZERO_VALUE)
//     {
//         DEPOSIT = _deposit;
//     }

//     function insertIdentity(uint256 _identityCommitment) public
//     returns (uint256) {
//         // Ensure that the given identity commitment is not the zero value
//         require(
//             _identityCommitment != RLN_ZERO_VALUE,
//             "RLN: identity commitment cannot be the zero-value"
//         );

//         return insertLeaf(_identityCommitment);
//     }

//     //Only owner should be able to call withdraw function so the user cannot take deposited money back until event is finished
//     function slash(
//         //proof
//         uint256 _root        
//         // address _reciever
// 	) onlyOwner external view {
//         require(rootHistory[_root], "RLN: root not seen");

//         //send money to reciever
// 	}

// }