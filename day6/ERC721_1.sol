// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 每次发一个NFT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyNFT2", "MNFT2") {}

// mint:  tokenURI: https://ipfs.io/ipfs/bafkreiek2fnuf3bvsythsdjjebfu6f6cll7oj2lm5fhn347ckbyjzix77m
/**
{
    "name": "NFT 5",
    "description": "This is the 5 NFT in the collection.",
    "image": "ipfs://bafkreiefqkxxk4zzmo5phrgjop7i7pytd4m642uurysutx5pohicvbobsq"
}
 */
    function mintNFT(
        address recipient,
        string memory tokenURI
    ) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
}