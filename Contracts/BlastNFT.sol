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
    // For the amount holders
    mapping(address => uint256) private _contributions;

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
        _contributions[msg.sender] += msg.value;
        // Implement additional logic if needed
    }

    // Transfer funds from the collection to the recipient
    function transferFromCollection(
        address recipient,
        uint256 amount
    ) external {
        // Transfer the funds while withdrawing from marketplace.sol
        // After the completion of the lockup period
        // Transfer to the recipient with the amount that was received by receiveFunds() function
        // Check if the sender has made a contribution
        uint256 contribution = _contributions[recipient];
        require(contribution > 0, "No contribution found for the recipient");
        // Transfer the contributed amount in Ether from the collection to the recipient
        require(
            address(this).balance >= contribution,
            "Insufficient funds in the collection"
        );
        require(address(this).balance >= amount, "No balance available");
        recipient.transfer(amount);
        _contributions[msg.sender] -= msg.value;
    }
}
