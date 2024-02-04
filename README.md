# BlastNFT - NFT Minting and Marketplace

**Note: This project is currently under construction and will be available soon.**

## Overview

This project consists of smart contracts for creating and managing NFTs using the BlastNFTFactory and Marketplace contracts.

### Steps for running the contract on Remix

1. Deploy the `BlastNFTFactory.sol` contract.
2. Deploy the `Marketplace.sol` contract using the address of the factory contract.
3. Set the marketplace address inside the factory contract.
4. Call the `createCollection` function in the factory contract to create a new NFT collection.
5. After creating a collection, the owner can mint NFTs using the `mintNFT` function.
6. You can repeat the process to create more collections and mint additional NFTs.

## Instructions

- Ensure that Remix IDE (https://remix.ethereum.org/) is set up and connected to the desired Ethereum network (e.g., JavaScript VM, Injected Web3, etc.).
- Deploy the contracts in the following order:
    - Deploy `BlastNFTFactory.sol`.
    - Deploy `Marketplace.sol` using the address of the deployed factory contract.
- Set the marketplace address inside the factory contract using the `setMarketplace` function.
- Create a new NFT collection by calling the `createCollection` function in the factory contract.
- Mint NFTs within a collection using the `mintNFT` function. Only the owner of the collection can mint NFTs.
- Repeat the process to create additional collections and mint more NFTs.