// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlastNFT is ERC721, Ownable {
    using SafeMath for uint256;

    // IPFS base URI for storing images
    string private _baseTokenURI;

    // Mapping from token ID to price in Blast tokens
    mapping(uint256 => uint256) private _tokenPrices;

    // Address of the Blast token contract
    address private _blastToken;

    // Event for successful NFT purchase
    event NFTPurchased(address buyer, uint256 tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address blastToken
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _blastToken = blastToken;
    }

    // Mint new NFT with the image stored in IPFS
    function mintNFT(
        string memory ipfsHash,
        uint256 priceInBlast
    ) external onlyOwner {
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(
            tokenId,
            string(abi.encodePacked(_baseTokenURI, ipfsHash))
        );
        _tokenPrices[tokenId] = priceInBlast;
    }

    // Buy NFT using Blast tokens
    function purchaseNFT(uint256 tokenId) external {
        require(_exists(tokenId), "NFT does not exist");
        require(_tokenPrices[tokenId] > 0, "NFT not for sale");

        // Perform Blast token transfer logic here, deducting the priceInBlast from the buyer

        // Mint the NFT to the buyer
        _safeMint(msg.sender, tokenId);

        // Emit purchase event
        emit NFTPurchased(msg.sender, tokenId);
    }

    // Set the base URI for token metadata
    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    // Set the price for an existing NFT
    function setTokenPrice(
        uint256 tokenId,
        uint256 priceInBlast
    ) external onlyOwner {
        require(_exists(tokenId), "NFT does not exist");
        _tokenPrices[tokenId] = priceInBlast;
    }

    // Get the price of an NFT in Blast tokens
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return _tokenPrices[tokenId];
    }
}
