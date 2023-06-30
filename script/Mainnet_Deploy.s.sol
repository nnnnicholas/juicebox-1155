// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {JuiceboxCards} from "src/JuiceboxCards.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Config} from "src/Structs/Config.sol";

contract DeployScript is Script {
    address jbProjects = 0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    uint16 tipProject = 465;
    uint64 price = 0.01 ether;
    address directory = 0x65572FB928b46f9aDB7cfe5A4c41226F636161ea;
    string contractUri =
        "ipfs://Qmf738Z8cXJ6n4aLszJcs3MgBTQqrp9ZVNkhWvVUueM5Gy";

    Config config =
        Config(jbProjects, tipProject, price, directory, contractUri);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        JuiceboxCards juiceboxCards = new JuiceboxCards(config);
        vm.stopBroadcast();
    }
}
