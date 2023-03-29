// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Juicebox1155} from "src/Juicebox1155.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    // Goerli constructor args
    address public projects = 0x8E05bcD2812E1449f0EC3aE24E2C395F533d9A99;
    address payable public projectPayer =
        payable(0x348150e9C432b437AAd7081039EF2DaF0F3189A2);
    uint256 public priceInWei = 0;
    string public contractUri = "";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_PRIVATE_KEY");
        // Deploy Juicebox1155
        vm.startBroadcast(deployerPrivateKey);
        Juicebox1155 juicebox1155 = new Juicebox1155(config);
        vm.stopBroadcast();
    }
}
