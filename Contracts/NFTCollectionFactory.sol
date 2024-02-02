// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BlastNFT.sol";
import "./Marketplace.sol";

contract NFTCollectionFactory is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _collectionIdCounter;
    mapping(address => bool) private _approvedCollections;
    mapping(address => address) private _collectionCreators;

    event CollectionCreated(
        address indexed collection,
        string name,
        string symbol,
        address indexed creator
    );

    modifier onlyApprovedCollection() {
        require(_approvedCollections[msg.sender], "Collection not approved");
        _;
    }

    function approveCollection(address collection) external {
        _approvedCollections[collection] = true;
    }

    function createCollectionWithMarketplace(
        string memory name,
        string memory symbol,
        address marketplace,
        uint256 initialPriceInBlast
    ) external returns (address) {
        BlastNFT blastNFT = new BlastNFT(name, symbol);

        // Set the centralized marketplace for the created BlastNFT contract
        blastNFT.setMarketplace(marketplace, initialPriceInBlast);

        // Approve the new contract
        _approvedCollections[address(blastNFT)] = true;

        // Record the creator of the collection
        _collectionCreators[address(blastNFT)] = msg.sender;

        emit CollectionCreated(address(blastNFT), name, symbol, msg.sender);

        // address of the blastNFT contract
        return address(blastNFT);
    }

    function getCollectionCreator(
        address collection
    ) external view returns (address) {
        return _collectionCreators[collection];
    }
}
