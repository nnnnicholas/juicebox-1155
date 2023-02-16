// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {Juicebox1155, JBProjects} from "../src/Juicebox1155.sol";
import {ERC1155Receiver, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Juicebox1155Test is Test, ERC1155Receiver {
    Juicebox1155 j =
        new Juicebox1155(
            JBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3)
        );

    function setUp() public {}

    function testUri() public {
        j.mint(1);
        string memory x = j.uri(1);

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
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
