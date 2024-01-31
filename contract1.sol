// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlastNFT is ERC721, Ownable {
    using SafeMath for uint256;

    // IPFS base URI for storing images
    string private _baseTokenURI;

    // Mapping to store NFT listing status
    mapping(uint256 => bool) private _isNFTListed;

    // Mapping from token ID to price in Blast tokens
    mapping(uint256 => uint256) private _tokenPrices;

    // Mapping from token ID to address of the owner who listed it
    mapping(address => uint256[]) private _listingToOwner;

    // Event for NFT listing
    event NFTListed(uint256 tokenId, address seller, uint256 priceInBlast);

    // Event for NFT purchase
    event NFTPurchased(address buyer, uint256 tokenId, uint256 priceInBlast);

    // Constructor
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
    function mintNFT(string memory ipfsHash, uint256 priceInBlast) external {
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(
            tokenId,
            string(abi.encodePacked(_baseTokenURI, ipfsHash))
        );
        _tokenPrices[tokenId] = priceInBlast;
        _isNFTListed[tokenId] = false;
        _listingToOwner[owner].push(tokenId);
    }

    // Function to list an NFT for sale
    function listNFTForSale(uint256 tokenId, uint256 priceInBlast) external {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(!_isNFTListed[tokenId], "NFT is already listed");

        _isNFTListed[tokenId] = true;

        // Emit listing event
        emit NFTListed(tokenId, msg.sender, priceInBlast);
    }

    // Function to purchase an NFT
    function purchaseNFT(uint256 tokenId) external payable {
        require(_exists(tokenId), "NFT does not exist");
        require(_isNFTListed[tokenId], "NFT is not listed for sale");
        require(
            ownerOf(tokenId) != msg.sender,
            "You can't purchase your own NFT."
        );
        uint256 priceInBlast = _tokenPrices[tokenId];
        require(msg.value == priceInBlast, "Incorrect payment amount");

        address seller = ownerOf(tokenId);

        // Transfer Blast tokens to the seller
        // (Implement the actual transfer logic according to your token contract)

        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        // Transfer the ownership of the tokenId
        _listingToOwner[owner].pop(tokenId);
        _listingToOwner[msg.sender].push(tokenId);
        // Mark the NFT as not listed
        _isNFTListed[tokenId] = false;

        // Emit purchase event
        emit NFTPurchased(msg.sender, tokenId, priceInBlast);
    }

    // Function to check if an NFT is listed
    function isNFTListed(uint256 tokenId) external view returns (bool) {
        return _isNFTListed[tokenId];
    }

    // Set the price for an existing NFT
    function setTokenPrice(
        uint256 tokenId,
        uint256 priceInBlast
    ) external payable {
        require(_exists(tokenId), "NFT does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not  the owner of this NFT."
        );
        _tokenPrices[tokenId] = priceInBlast;
    }

    // Get the price of an NFT in Blast tokens
    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return _tokenPrices[tokenId];
    }
}
