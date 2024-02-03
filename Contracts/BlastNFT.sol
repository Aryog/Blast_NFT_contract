// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlastNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // Address of the linked Marketplace contract
    address private _marketplace;
    mapping(uint256 => address) private _tokenCollection;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => string) private _tokenNames;

    event NFTMinted(
        uint256 tokenId,
        address owner,
        string tokenURI,
        string tokenName
    );

    modifier onlyCollectionOwner() {
        require(
            _collectionOwner == msg.sender,
            "You are not the owner of this collection"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address marketplace
    ) ERC721(name, symbol) {
        _collectionOwner = msg.sender;
        _marketplace = marketplace;
    }

    function mintNFT(
        string memory tokenURI,
        string memory tokenName
    ) external onlyCollectionOwner {
        require(_marketplace != address(0), "Marketplace not set");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenCollection[tokenId] = msg.sender;
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenName(tokenId, tokenName);

        // Set the collection ownership for the minted token may require in the future
        _tokenCollection[tokenId] = msg.sender;

        // Approve the marketplace to handle the minted token
        approve(_marketplace, tokenId);

        emit NFTMinted(tokenId, msg.sender, tokenURI, tokenName);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    function _setTokenName(
        uint256 tokenId,
        string memory name
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: Name set of nonexistent token"
        );
        _tokenNames[tokenId] = name;
    }

    function getCollectionNFTs() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_tokenIdCounter.current());

        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            result[i] = i;
        }

        return result;
    }

    function getTokenLen() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getURIAndName(
        uint256 tokenId
    ) public view returns (string memory, string memory) {
        return (_tokenURIs[tokenId], _tokenNames[tokenId]);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function getTokenName(uint256 tokenId) public view returns (string memory) {
        return _tokenNames[tokenId];
    }
}
