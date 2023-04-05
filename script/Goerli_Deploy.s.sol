// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {JuiceboxProjectCards} from "src/JuiceboxProjectCards.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    // Goerli constructor args
    address public projects = 0x21263a042aFE4bAE34F08Bb318056C181bD96D3b;
    address payable public projectPayer =
        payable(0x0e44297757856fc9236A130D11B0547d42Ce27d8);
    uint256 public priceInWei = 0;
    string public contractUri = "";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_PRIVATE_KEY");
        // Deploy Juicebox1155
        vm.startBroadcast(deployerPrivateKey);
        JuiceboxProjectCards juiceboxProjectCards = new JuiceboxProjectCards(config);
        vm.stopBroadcast();
    }
}
