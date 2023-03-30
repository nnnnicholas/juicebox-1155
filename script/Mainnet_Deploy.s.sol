// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {Juicebox1155} from "src/Juicebox1155.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    // Mainnet constructor args
    address public projects = 0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    address payable public projectPayer =
        payable(0x277eeD88690577807285a4F54a7384e597db8e90);
    uint256 public priceInWei = 0;
    string public contractUri = "";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        // Deploy Juicebox1155
        vm.startBroadcast(deployerPrivateKey);
        Juicebox1155 juicebox1155 = new Juicebox1155(config);
        vm.stopBroadcast();
    }
}
