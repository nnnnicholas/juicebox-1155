// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Config {
    address jbProjects; // The JBProjects contract
    address payable feeRecipient; // The address that mint fee is forwarded to
    uint256 price; // The price of the NFT in wei
    string contractUri; // The URI of the contract metadata
    address directory; // New field for the directory
}