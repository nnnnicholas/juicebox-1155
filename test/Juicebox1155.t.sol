// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//Juicebox1155
import "forge-std/Test.sol";
import {Juicebox1155, Config} from "../src/Juicebox1155.sol";
import {ERC1155Receiver, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

// JB
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal3_1} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal3_1.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";

contract Juicebox1155Test is Test, ERC1155Receiver {
    // SETUP
    uint256 constant FORK_BLOCK_NUMBER = 16942000; // All tests executed at this block
    string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    uint256 forkId =
        vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER);

    // Mainnet constructor args
    IJBDirectory directory =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    address public projects = 0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    address payable public projectPayer =
        payable(0x277eeD88690577807285a4F54a7384e597db8e90);
    uint256 public priceInWei = 0.01 ether;
    string public contractUri = "";

    // Config
    Config public config =
        Config(projects, projectPayer, priceInWei, contractUri);
    // Deploy Juicebox1155
    Juicebox1155 juicebox1155 = new Juicebox1155(config);

    // Test that you can mint an NFT
    // TODO

    // Test that ETH is correctly forwarded to the receiver if its a JB project payer
    function testProjectPayer() public {
        uint256 _projectId = 1;
        uint256 balanceBefore;

        // Get the projects

        // Get balance of the project before minting
        juicebox1155.mint{value: 0.01 ether}(1); // Mint an NFT
        // Get balance of the project after minting
        // uint256 balanceAfter;

        // Check that the balance of the project increased
        // // assertTrue(
        // //     balanceBefore + priceInWei == balanceAfter,
        // //     "Project balance did not increase. Check ProjectPayer."
        // );
    }

    // Test that URI is correct
    // TODO

    // Test that contractUri works
    // TODO

    // Lets external addresses mint an NFT whose metadata that matches the metadata that JBProjects returns and sends eth to juicebox
    // Does not let anyone mint without paying

    // function testUri() public {
    //     j.mint(1);
    //     string memory x = j.uri(1);

    //     string[] memory inputs = new string[](3);
    //     inputs[0] = "node";
    //     inputs[1] = "./open.js";
    //     inputs[2] = x;
    //     // bytes memory res = vm.ffi(inputs);
    //     vm.ffi(inputs);
    // }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(0xf23a6e61);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(0xf23a6e61);
    }
}
