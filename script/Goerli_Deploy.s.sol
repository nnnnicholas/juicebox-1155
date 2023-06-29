// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {JuiceboxCards} from "src/JuiceboxCards.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    address jbProjects = 0x21263a042aFE4bAE34F08Bb318056C181bD96D3b;
    uint16 tipProject = 465;
    uint64 price = 0.01 ether;
    address public directory = 0x8E05bcD2812E1449f0EC3aE24E2C395F533d9A99;
    string contractUri =
        "ipfs://Qmf738Z8cXJ6n4aLszJcs3MgBTQqrp9ZVNkhWvVUueM5Gy";

    Config config =
        Config(jbProjects, tipProject, price, directory, contractUri);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        JuiceboxCards juiceboxCards = new JuiceboxCards(config);
        vm.stopBroadcast();
    }
}