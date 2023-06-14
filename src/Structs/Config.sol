// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Config {
    address jbProjects; // 160 bits  // The JBProjects contract
    uint16 tipProject;  // 16 bits   // The project ID of the metadata project
    uint64 price;       // 64 bits   // The price of the NFT in wei
    address directory;  // 160 bits  // The directory contract
    string contractUri; // 256+ bits // The URI of the contract metadata
}