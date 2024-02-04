// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/utils/Counters.sol";
import "./BlastNFT.sol";
import "./BlastNFTFactory.sol";

// For factory pass it on the constructor
contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    address public owner;
    BlastNFTFactory public factory;

    mapping(address => mapping(uint256 => uint256)) private _tokenPrices;
    mapping(address => mapping(uint256 => bool)) private _isNFTListed;
    Counters.Counter private _tokenIdCounter;

    event NFTListed(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    event NFTPurchased(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed buyer
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _factory) {
        owner = msg.sender;
        factory = BlastNFTFactory(_factory);
    }

    function toggleNFTForSale(
        address collection,
        uint256 tokenId,
        uint256 priceInBlast
    ) external onlyOwner {
        require(
            factory.isCollectionCreated(collection),
            "Collection not created by the factory"
        );
        require(
            BlastNFT(collection).ownerOf(tokenId) == msg.sender,
            "You are not the owner of the NFT"
        );
        if (_isNFTListed[collection][tokenId]) {
            // NFT is already listed, remove from sale
            _removeFromSale(collection, tokenId);
        } else {
            // NFT is not listed, put on sale
            _listForSale(collection, tokenId, priceInBlast);
        }
    }

    // User should have the collection address of particular nft
    function purchaseNFT(
        address collection,
        uint256 tokenId
    ) external payable nonReentrant {
        require(
            _tokenPrices[collection][tokenId] > 0,
            "NFT not listed for sale"
        );
        uint256 priceInBlast = _tokenPrices[collection][tokenId];

        require(msg.value >= priceInBlast, "Insufficient funds to purchase");

        // Transfer funds to the seller
        address seller = BlastNFT(collection).ownerOf(tokenId);
        // Ensure that the buyer is not the current owner of the token
        require(
            seller != msg.sender,
            "Buyer is the current owner of the token"
        );

        // Check if the buyer is approved or the owner
        require(
            BlastNFT(collection).getApproved(tokenId) == address(this),
            "NFT must be approved to market"
        );

        payable(seller).transfer(priceInBlast);

        // Transfer the NFT to the buyer
        BlastNFT(collection).transferFrom(seller, msg.sender, tokenId);

        // Remove from sale
        _removeFromSale(collection, tokenId);

        emit NFTPurchased(collection, tokenId, msg.sender);
    }

    function calculatePrincipalAmount(
        uint256 targetYield,
        uint256 lockupPeriodInDays
    ) internal pure returns (uint256) {
        // TODO: calculation logic here for yeild generating deposit
    }

    function _removeFromSale(address collection, uint256 tokenId) internal {
        require(
            _isNFTListed[collection][tokenId],
            "NFT is not listed for sale"
        );

        // Remove the NFT from sale
        _isNFTListed[collection][tokenId] = false;

        // Optionally, you can also reset the price
        _tokenPrices[collection][tokenId] = 0;
    }

    function _listForSale(
        address collection,
        uint256 tokenId,
        uint256 priceInBlast
    ) internal {
        // Mark the NFT as listed
        _isNFTListed[collection][tokenId] = true;
        // Set the price in the _tokenPrices mapping
        _tokenPrices[collection][tokenId] = priceInBlast;

        // Emit an event to indicate that the NFT is listed for sale
        emit NFTListed(collection, tokenId, msg.sender, priceInBlast);
    }
}
