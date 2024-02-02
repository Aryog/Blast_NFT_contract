// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping(address => bool) private _approvedCollections;
    mapping(address => mapping(uint256 => uint256)) private _tokenPrices;
    mapping(address => mapping(uint256 => bool)) private _isNFTListed;
    Counters.Counter private _tokenIdCounter;

    struct Lockup {
        address collection;
        uint256 tokenId;
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => Lockup[]) private lockups;

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

    modifier onlyApprovedCollection() {
        require(_approvedCollections[msg.sender], "Collection not approved");
        _;
    }

    function approveCollection(address collection) external onlyOwner {
        _approvedCollections[collection] = true;
    }

    // collection is the BlasNFT contract address
    function toggleNFTForSale(
        address collection,
        uint256 tokenId,
        uint256 priceInBlast
    ) external onlyApprovedCollection {
        require(
            _isTokenOwner(collection, tokenId, msg.sender),
            "You are not the owner"
        );

        if (_isNFTListed[collection][tokenId]) {
            // NFT is already listed, remove from sale
            _removeFromSale(collection, tokenId);
        } else {
            // NFT is not listed, put on sale
            _listForSale(collection, tokenId, priceInBlast);
        }
    }

    function purchaseNFT(
        address collection,
        uint256 tokenId,
        uint256 lockupPeriodInDays
    ) external payable nonReentrant {
        require(
            _tokenPrices[collection][tokenId] > 0,
            "NFT not listed for sale"
        );
        uint256 priceInBlast = _tokenPrices[collection][tokenId];

        uint256 requiredPrincipal = calculatePrincipalAmount(
            priceInBlast,
            lockupPeriodInDays
        );

        require(
            msg.value >= requiredPrincipal,
            "Insufficient funds to purchase the NFT"
        );

        Lockup memory newLockup = Lockup({
            collection: collection,
            tokenId: tokenId,
            amount: requiredPrincipal,
            releaseTime: block.timestamp + lockupPeriodInDays * 1 days
        });

        lockups[msg.sender].push(newLockup);

        address seller = IERC721(collection).ownerOf(tokenId);

        IERC721(collection).transferFrom(seller, msg.sender, tokenId);

        _approvedCollections[msg.sender] = false;
        _approvedCollections[seller] = true;

        _tokenPrices[collection][tokenId] = 0;

        // Send funds to the collection contract
        // Assuming your collection contract has a receiveFunds function
        // Modify this part based on your contract's actual function to receive funds
        (bool success, ) = address(collection).call{value: priceInBlast}("");
        require(success, "Failed to send funds to the collection contract");

        if (msg.value > requiredPrincipal) {
            payable(msg.sender).transfer(msg.value - requiredPrincipal);
        }

        emit NFTPurchased(collection, tokenId, msg.sender);
    }

    function calculatePrincipalAmount(
        uint256 targetYield,
        uint256 lockupPeriodInDays
    ) internal pure returns (uint256) {
        uint256 annualInterestRate = 4;
        uint256 principalAmount = (targetYield * 365 * 100) /
            (annualInterestRate * lockupPeriodInDays);
        return principalAmount;
    }

    // User need to call for the lockedup funds
    function withdrawLockedUpFunds(uint256 lockupIndex) external {
        require(
            lockupIndex < lockups[msg.sender].length,
            "Invalid lockup index"
        );
        Lockup storage lockup = lockups[msg.sender][lockupIndex];
        require(
            block.timestamp >= lockup.releaseTime,
            "Lock-up period not yet expired"
        );

        // Transfer the locked-up funds back to the user
        IBlast(lockup.collection).transferFromCollection(
            msg.sender,
            lockup.amount
        );

        // Remove the completed lockup from the array
        if (lockups[msg.sender].length > 1) {
            lockups[msg.sender][lockupIndex] = lockups[msg.sender][
                lockups[msg.sender].length - 1
            ];
        }
        lockups[msg.sender].pop();
    }

    // Get the lockup index based on the user and lockup details
    function getLockupIndex(
        address user,
        uint256 tokenId,
        uint256 releaseTime
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < lockups[user].length; i++) {
            if (
                lockups[user][i].tokenId == tokenId &&
                lockups[user][i].releaseTime == releaseTime
            ) {
                return i;
            }
        }
        return type(uint256).max; // Lockup not found, return a large value as an indicator
    }

    function _isTokenOwner(
        address collection,
        uint256 tokenId,
        address potentialOwner
    ) internal view returns (bool) {
        return IERC721(collection).ownerOf(tokenId) == potentialOwner;
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
