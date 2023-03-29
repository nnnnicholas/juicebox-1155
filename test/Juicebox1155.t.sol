// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {Juicebox1155, Config} from "../src/Juicebox1155.sol";
import {ERC1155Receiver, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

// contract Juicebox1155Test is Test, ERC1155Receiver {
    // Config config =
    //     Config({
    //         _revenueRecipient: address(0x0),
    //         _projects: address(0x0),
    //         _price: 0.01 ether,
    //         _contractUri: ""
    //     });


    //  Setup vars
    // uint256 constant FORK_BLOCK_NUMBER = 16848000; // All tests executed at this block
    // string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    // uint256 forkId = vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER);
    // Juicebox1155 j = new Juicebox1155(config);

    // function setUp() public {}

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

    // function supportsInterface(
    //     bytes4 interfaceId
    // ) public view virtual override(ERC1155Receiver) returns (bool) {
    //     return
    //         interfaceId == type(IERC1155Receiver).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }

    // function onERC1155Received(
    //     address operator,
    //     address from,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // ) external returns (bytes4) {
    //     return bytes4(0xf23a6e61);
    // }

    // function onERC1155BatchReceived(
    //     address operator,
    //     address from,
    //     uint256[] calldata ids,
    //     uint256[] calldata values,
    //     bytes calldata data
    // ) external returns (bytes4) {
    //     return bytes4(0xf23a6e61);
    // }
// }
