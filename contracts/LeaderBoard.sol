// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/abstracts/Reencrypt.sol";
import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract EncLeaderBoard is Reencrypt, Ownable2Step {
    //uint32 private _score;
    //uint32 private _highestScore=0;

    // A mapping from address to an encrypted score.
    // mapping(address => euint32) internal scores;
    struct ScoreIndex {
        uint index;
        bool isValue;
    }

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    // mapping(address => mapping(address => euint32)) internal allowances;
    constructor() Ownable(msg.sender) {}
    euint16[512] scores;
    uint scoreCount = 0;
    mapping(address => ScoreIndex) indexes;

    function add_score() public {
        if (indexes[msg.sender].isValue) {
            scores[indexes[msg.sender].index] = TFHE.add(scores[indexes[msg.sender].index], TFHE.randEuint8());
        } else {
            indexes[msg.sender].isValue = true;
            indexes[msg.sender].index = scoreCount;
            scores[indexes[msg.sender].index] = TFHE.asEuint16(TFHE.randEuint8());
            scoreCount += 1;
        }
    }

    function user_score(address addr) public view returns (uint16) {
        return TFHE.decrypt(scores[indexes[addr].index]);
    }

    function user_ranking(address addr) public view returns (uint16) {
        require(indexes[addr].isValue);
        uint userScoreIdx = indexes[addr].index;

        euint16 userScore = scores[userScoreIdx];
        euint16 usersHigherThanUser = TFHE.asEuint16(0);
        euint16 one = TFHE.asEuint16(1);
        for (uint i = 0; i < scoreCount; i++) {
            if (i != userScoreIdx) {
                ebool isHigher = TFHE.gt(scores[i], userScore);
                usersHigherThanUser = TFHE.cmux(isHigher, TFHE.add(usersHigherThanUser, one), usersHigherThanUser);
            }
        }
        return TFHE.decrypt(usersHigherThanUser);
    }
}
