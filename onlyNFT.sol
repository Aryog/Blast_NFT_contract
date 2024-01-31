// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/utils/Counters.sol";

contract BlastNFT is ERC721, Ownable {
    using SafeMath for uint256;
    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    mapping(uint256 => bool) private _isNFTListed;
    mapping(uint256 => uint256) private _tokenPrices;
    mapping(address => uint256[]) private _listingToOwner;
    mapping(uint256 => string) private _tokenURIs;

    event NFTListed(uint256 tokenId, address seller, uint256 priceInBlast);
    event NFTPurchased(address buyer, uint256 tokenId, uint256 priceInBlast);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    function mintNFT(string memory ipfsHash, uint256 priceInBlast) external {
        uint256 tokenId = nextTokenId();
        _mint(msg.sender, tokenId);
        _setTokenURI(
            tokenId,
            string(abi.encodePacked(_baseTokenURI, ipfsHash))
        );
        _tokenPrices[tokenId] = priceInBlast;
        _listingToOwner[msg.sender].push(tokenId);
    }

    function listNFTForSale(
        uint256 tokenId,
        uint256 priceInBlast
    ) external {
        require(_isTokenOwner(tokenId, msg.sender), "You are not the owner");
        require(!_isNFTListed[tokenId], "NFT is already listed");

        _isNFTListed[tokenId] = true;

        emit NFTListed(tokenId, msg.sender, priceInBlast);
    }

    function purchaseNFT(uint256 tokenId) external payable {
        require(_isNFTListed[tokenId], "NFT is not listed for sale");
        require(
            !_isTokenOwner(tokenId, msg.sender),
            "You can't purchase your own NFT"
        );
        uint256 priceInBlast = _tokenPrices[tokenId];
        require(msg.value == priceInBlast, "Incorrect payment amount");

        address seller = ownerOf(tokenId);

        // Transfer Blast tokens to the seller (Implement the actual transfer logic)
        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        // Update ownership in the listing mapping
        _updateOwnership(tokenId, seller, msg.sender);

        // Mark the NFT as not listed
        _isNFTListed[tokenId] = false;

        emit NFTPurchased(msg.sender, tokenId, priceInBlast);
    }

    function setTokenPrice(uint256 tokenId, uint256 priceInBlast) external {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(_isTokenOwner(tokenId, msg.sender), "You are not the owner");
        _tokenPrices[tokenId] = priceInBlast;
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return _tokenPrices[tokenId];
    }

    function isNFTListed(uint256 tokenId) external view returns (bool) {
        return _isNFTListed[tokenId];
    }

    // Internal function to check if the caller is the owner of the token
    function _isTokenOwner(
        uint256 tokenId,
        address owner
    ) internal view returns (bool) {
        return ownerOf(tokenId) == owner;
    }

    function nextTokenId() public view returns (uint256) {
        return Counters.current(_tokenIdCounter) + 1;
    }

    // Internal function to update ownership in the listing mapping
    function _updateOwnership(
        uint256 tokenId,
        address oldOwner,
        address newOwner
    ) internal {
        uint256[] storage ownerList = _listingToOwner[oldOwner];
        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == tokenId) {
                ownerList[i] = ownerList[ownerList.length - 1];
                ownerList.pop();
                break;
            }
        }
       
