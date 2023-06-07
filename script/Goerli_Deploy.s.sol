// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {JuiceboxCards} from "src/JuiceboxCards.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    // Goerli constructor args
    address public directory = 0x8E05bcD2812E1449f0EC3aE24E2C395F533d9A99;
    address public projects = 0x21263a042aFE4bAE34F08Bb318056C181bD96D3b;
    address payable public projectPayer =
        payable(0x0e44297757856fc9236A130D11B0547d42Ce27d8);
    uint256 public priceInWei = 0;
    string public contractUri = "";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri, directory);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_PRIVATE_KEY");
        // Deploy Juicebox1155
        vm.startBroadcast(deployerPrivateKey);
        JuiceboxCards juiceboxCards = new JuiceboxCards(config);
        vm.stopBroadcast();
    }
}
