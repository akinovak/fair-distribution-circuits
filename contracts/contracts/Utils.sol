//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Utils {
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