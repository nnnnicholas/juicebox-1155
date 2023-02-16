// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {JBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/JBProjects.sol";

contract Juciebox1155 is ERC1155 {
    JBProjects public resolver;

    constructor(JBProjects _resolver) ERC1155(""){
        resolver = _resolver;
    }

    function mint(uint256 projectId) external {
        _mint(msg.sender, projectId, 1, bytes(""));
    }

    function uri(uint256 projectId) public view virtual override returns (string memory) {
        return resolver.tokenURI( projectId);
    }
}
