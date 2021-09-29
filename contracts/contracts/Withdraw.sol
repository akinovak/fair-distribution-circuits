//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import { IncrementalQuinTree } from "./IncrementalMerkleTree.sol";
// // import { SnarkConstants } from "./SnarkConstants.sol";

// contract Withdaw is IncrementalQuinTree {
//     // The scalar field
//     mapping (uint256 => bool) public nullifierHashes;
//     mapping (address => uint) public shares;

//     IncrementalQuinTree private tree;

//     uint256 public WITHDRAW_ZERO_VALUE = 
//         uint256(keccak256(abi.encodePacked('FAIR'))) % SNARK_SCALAR_FIELD;

//     constructor(uint8 _treeLevels)
//         IncrementalQuinTree(_treeLevels, WITHDRAW_ZERO_VALUE)
//     {
//     }

//     function insertNote(uint256 _commitment) external returns (uint256) {
//         // Ensure that the given identity commitment is not the zero value
//         require(
//             _commitment != WITHDRAW_ZERO_VALUE,
//             "Withdrawal: commitment cannot be the zero-value"
//         );

//         return tree.insertLeaf(_commitment);
//     }

//     //add proof as param
//     //maybe we should add relayer later
//     function withdraw(uint256 _root, uint256 _nullifierHash, address _recipient) external {
//         require(!nullifierHashes[_nullifierHash], "The note has been already spent");
//         require(tree.rootHistory[_root], "Withdrawal: root not seen");
//         //TODO verify proof

//         nullifierHashes[_nullifierHash] = true;
//         shares[_recipient] = shares[_recipient] + 1; 
//     }

// }