// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {JuiceboxCards} from "src/JuiceboxCards.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    address public directory =
        address(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    address public projects = 0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    address payable public projectPayer =
        payable(0xD37b2FE8748f4795a465c9B851ce8066426A427F);
    uint256 public priceInWei = 0.01 ether;
    string public contractUri =
        "ipfs://QmYGEhsCwMdmcZSmhEvpJXvSM4Jgvj4WyRgdwH53ZHtUar";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri, directory);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        // Deploy Juicebox1155
        vm.startBroadcast(deployerPrivateKey);
        JuiceboxCards juiceboxCards = new JuiceboxCards(config);
        vm.stopBroadcast();
    }
}
