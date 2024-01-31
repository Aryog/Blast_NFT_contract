// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlastNFT is ERC721, Ownable {
    using SafeMath for uint256;

    string private _baseTokenURI;
    address private _blastSepoliaNetwork =
        0x4200000000000000000000000000000000000024;

    mapping(uint256 => bool) private _isNFTListed;
    mapping(uint256 => uint256) private _tokenPrices;
    mapping(address => uint256[]) private _listingToOwner;

    event NFTListed(uint256 tokenId, address seller, uint256 priceInBlast);
    event NFTPurchased(address buyer, uint256 tokenId, uint256 priceInBlast);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address blastSepoliaNetwork
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _blastSepoliaNetwork = blastSepoliaNetwork;
    }

    function mintNFT(string memory ipfsHash, uint256 priceInBlast) external {
        require(
            msg.sender == _blastSepoliaNetwork,
            "Only Blast Sepolia network can mint NFTs"
        );
        uint256 tokenId = totalSupply() + 1;
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
    ) external onlyBlastSepolia {
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
        require(
            msg.sender == _blastSepoliaNetwork,
            "Only Blast Sepolia network can purchase NFTs"
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
        require(_exists(tokenId), "NFT does not exist");
        require(_isTokenOwner(tokenId, msg.sender), "You are not the owner");
        _tokenPrices[tokenId] = priceInBlast;
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
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
        _listingToOwner[newOwner].push(tokenId);
    }

    modifier onlyBlastSepolia() {
        require(
            msg.sender == _blastSepoliaNetwork,
            "Only Blast Sepolia network can call this function"
        );
        _;
    }
}
