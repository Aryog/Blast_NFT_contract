// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/utils/Counters.sol";

interface IBlast {
    // function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function configureAutomaticYield() external;

    function configureClaimableGas() external;

    function claimAllGas(
        address contractAddress,
        address recipientOfGas
    ) external returns (uint256);
}

contract BlastNFT is ERC721, Ownable {
    using SafeMath for uint256;
    address private _COwner;
    Counters.Counter private _tokenIdCounter;
    IBlast public constant BLAST =
        IBlast(0x4300000000000000000000000000000000000002);
    mapping(uint256 => bool) private _isNFTListed;
    mapping(uint256 => uint256) private _tokenPrices;
    mapping(address => uint256[]) private _listingToOwner;
    mapping(uint256 => string) private _tokenURIs;

    struct Lockup {
        uint256 tokenId;
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => Lockup[]) private lockups;

    event NFTListed(uint256 tokenId, address seller, uint256 priceInBlast);
    event NFTPurchased(address buyer, uint256 tokenId, uint256 priceInBlast);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _COwner = msg.sender;
        BLAST.configureAutomaticYield();
        BLAST.configureClaimableGas();
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    // Helper function to construct the metadata URI
    function getMetadataURI(
        string memory ipfsHash
    ) internal pure returns (string memory) {
        // Example: Assuming you use IPFS
        return string(abi.encodePacked("https://ipfs.io/ipfs/", ipfsHash));
        // return string(abi.encodePacked(_baseTokenURI, ipfsHash));
    }

    function mintNFT(string memory ipfsHash, uint256 priceInBlast) external {
        uint256 tokenId = nextTokenId();
        _mint(msg.sender, tokenId);
        string memory tokenURI = getMetadataURI(ipfsHash);
        _setTokenURI(tokenId, tokenURI);

        _tokenPrices[tokenId] = priceInBlast;
        _listingToOwner[msg.sender].push(tokenId);
    }

    function listNFTForSale(uint256 tokenId, uint256 priceInBlast) external {
        require(_isTokenOwner(tokenId, msg.sender), "You are not the owner");
        require(!_isNFTListed[tokenId], "NFT is already listed");

        _isNFTListed[tokenId] = true;

        emit NFTListed(tokenId, msg.sender, priceInBlast);
    }

    function purchaseNFT(
        uint256 tokenId,
        uint256 lockupPeriodInDays
    ) external payable {
        require(_isNFTListed[tokenId], "NFT is not listed for sale");
        require(
            !_isTokenOwner(tokenId, msg.sender),
            "You can't purchase your own NFT"
        );

        uint256 priceInBlast = _tokenPrices[tokenId];

        // Calculate the required principal amount based on the target yield and lockup period
        uint256 requiredPrincipal = calculatePrincipalAmount(
            priceInBlast,
            lockupPeriodInDays
        );

        // Check if the sent amount is equal to or greater than the required principal
        require(
            msg.value >= requiredPrincipal,
            "Insufficient funds to purchase the NFT"
        );

        address seller = ownerOf(tokenId);

        // Transfer Blast tokens to the seller (Implement the actual transfer logic)
        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        // Update ownership in the listing mapping
        _updateOwnership(tokenId, seller, msg.sender);

        // Mark the NFT as not listed
        _isNFTListed[tokenId] = false;

        // Refund any excess funds sent by the buyer
        if (msg.value > requiredPrincipal) {
            payable(msg.sender).transfer(msg.value - requiredPrincipal);
        }

        Lockup memory newLockup = Lockup({
            tokenId: tokenId,
            amount: requiredPrincipal,
            releaseTime: block.timestamp + lockupPeriodInDays * 1 days
        });

        lockups[msg.sender].push(newLockup);
        emit NFTPurchased(msg.sender, tokenId, priceInBlast);
    }

    function calculatePrincipalAmount(
        uint256 targetYield,
        uint256 lockupPeriodInDays
    ) internal pure returns (uint256) {
        uint256 annualInterestRate = 4; // 4% annual interest
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
        payable(msg.sender).transfer(lockup.amount);

        // Remove the completed lockup from the array
        if (lockups[msg.sender].length > 1) {
            lockups[msg.sender][lockupIndex] = lockups[msg.sender][
                lockups[msg.sender].length - 1
            ];
        }
        lockups[msg.sender].pop();
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

    function getAllLockups() external view returns (Lockup[] memory) {
        return lockups[msg.sender];
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

    // Function to claim gas for the contract (onlyOwner)
    function claimMyContractsGas() external onlyCOwner {
        BLAST.claimAllGas(address(this), msg.sender);
    }

    // Modifier to check if the caller is the owner
    modifier onlyCOwner() {
        require(msg.sender == _COwner, "Only the owner can call this function");
        _;
    }
}
