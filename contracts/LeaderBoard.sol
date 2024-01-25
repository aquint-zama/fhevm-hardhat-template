// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/abstracts/Reencrypt.sol";
import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract ConfidentialERC20 is Reencrypt, Ownable2Step {
    event Transfer(address indexed from, address indexed to);
    event Approval(address indexed owner, address indexed spender);
    event Mint(address indexed to, uint32 amount);

    uint32 private _score;
    uint8 public constant decimals = 0;

    // A mapping from address to an encrypted score.
    mapping(address => euint32) internal scores;

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    // mapping(address => mapping(address => euint32)) internal allowances;

    constructor() Ownable(msg.sender) {}

    // Sets the balance of the owner to the given encrypted balance.
    function addPoints(uint32 nbPoints) public virtual onlyOwner {
        scores[owner()] = TFHE.add(scores[owner()], nbPoints);
    }

    // Returns the balance of the caller encrypted under the provided public key.
    function getScore(
        address wallet,
        bytes32 publicKey,
        bytes calldata signature
    ) public view virtual onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        if (wallet == msg.sender) {
            return TFHE.reencrypt(scores[wallet], publicKey, 0);
        }
        return TFHE.reencrypt(TFHE.asEuint32(0), publicKey, 0);
    }
}
