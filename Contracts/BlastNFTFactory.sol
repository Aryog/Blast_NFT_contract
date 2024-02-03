// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BlastNFT.sol";

contract NFTCollectionFactory is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _collectionIdCounter;
    address private _owner;
    // Address of the marketplace contract can be set later by contract Owner
    address private _marketplace;
    mapping(address => bool) private _approvedCollections;
    // user to collection contract address map
    mapping(address => address[]) private _collectionPerCreator;
    mapping(address => uint256) private _collectionIds;

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

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function createCollection(
        string memory name,
        string memory symbol
    ) external returns (address) {
        BlastNFT blastNFT = new BlastNFT(name, symbol, _marketplace);

        // Assign a unique collection id
        uint256 collectionId = Counters.current(_collectionIdCounter);
        _collectionIds[address(blastNFT)] = collectionId;
        Counters.increment(_collectionIdCounter);

        // Approve the new contract
        _approvedCollections[address(blastNFT)] = true;

        // Record the collection of the creator
        _collectionPerCreator[msg.sender].push(address(blastNFT));

        emit CollectionCreated(address(blastNFT), name, symbol, msg.sender);

        // address of the blastNFT contract
        return address(blastNFT);
    }

    function getCreatorCollections() external view returns (address[] memory) {
        return _collectionPerCreator[msg.sender];
    }

    function isCollectionCreated(
        address collection
    ) external view returns (bool) {
        // Check if the given collection contract address is part of the collections created by the creator
        return
            _approvedCollections[collection] && _collectionIds[collection] > 0;
    }

    // Factory contract owner need to set marketplace before adding the collections
    function setMarketplace(address marketplace) external onlyOwner {
        _marketplace = marketplace;
    }
}
