//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Constants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public RLN_ZERO_VALUE = uint256(keccak256(abi.encodePacked('RLN'))) % SNARK_SCALAR_FIELD;
    uint256 public NOTES_ZERO_VALUE = uint256(keccak256(abi.encodePacked('FAIR'))) % SNARK_SCALAR_FIELD;
    
}