// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IBlast.sol";
import "./Marketplace.sol";

contract BlastNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IBlast public constant BLAST =
        IBlast(0x4300000000000000000000000000000000000002);

    // Mapping to track the collection ownership of each token
    mapping(uint256 => address) private _tokenCollection;
    // Address of the linked Marketplace contract
    address private _marketplace;
    address private _collectionOwner;
    mapping(uint256 => string) private _tokenURIs;

    event NFTMinted(uint256 tokenId, address owner, string tokenURI);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _collectionOwner = msg.sender;
    }

    modifier onlyCollectionOwner() {
        require(
            _collectionOwner == msg.sender,
            "You are not the owner of the collection"
        );
        _;
    }

    function setMarketplace(
        address marketplace,
        uint256 initialPriceInBlast
    ) external onlyOwner {
        require(marketplace != address(0), "Invalid marketplace address");
        _marketplace = marketplace;

        // Configure automatic yield and claimable gas in the Marketplace contract
        // Collection specific automatic yield and claimable gas
        BLAST.configureAutomaticYield();
        BLAST.configureClaimableGas();
    }

    function mintNFT(
        address collection,
        string memory tokenURI
    ) external onlyCollectionOwner {
        require(_marketplace != address(0), "Marketplace not set");

        uint256 tokenId = nextTokenId();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        // Set the collection ownership for the minted token may require in future
        _tokenCollection[tokenId] = collection;

        // Approve the marketplace to handle the minted token
        approve(_marketplace, tokenId);

        emit NFTMinted(tokenId, msg.sender, tokenURI);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    function getTokenCollection(
        uint256 tokenId
    ) external view returns (address) {
        return _tokenCollection[tokenId];
    }

    function nextTokenId() public view returns (uint256) {
        return Counters.current(_tokenIdCounter) + 1;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _setTokenURI(tokenId, tokenURI);
    }

    function nextTokenId() public view returns (uint256) {
        return Counters.current(_tokenIdCounter) + 1;
    }

    function receiveFunds() external payable {
        // Implement logic to handle received funds in the collection contract
        // This function can be customized based on your requirements
        // For example, you might want to keep track of the buyer's address and the amount received.
    }

    // Transfer funds from the collection to the recipient
    function transferFromCollection(
        address recipient,
        uint256 amount
    ) external onlyOwner {
        // Assuming you have a specific ERC20 token for your collection
        // Adjust this based on your actual token implementation
        IERC20 yourCollectionToken = IERC20(yourCollectionTokenAddress);

        // Transfer funds to the recipient
        yourCollectionToken.transfer(recipient, amount);
    }
}
