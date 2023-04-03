// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//Juicebox1155
import "forge-std/Test.sol";
import {JuiceboxProjectCards, Config} from "../src/JuiceboxProjectCards.sol";
import {ERC1155Receiver, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

// JB
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal3_1} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal3_1.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";

contract JuiceboxProjectCardsTest is Test, ERC1155Receiver {
    // SETUP
    uint256 constant FORK_BLOCK_NUMBER = 16942000; // All tests executed at this block
    string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    uint256 forkId =
        vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER);

    // Mainnet constructor args
    IJBDirectory constant JBDIRECTORY =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea); // JBDirectory V3
    address public constant JBPROJECTS =
        0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    address payable constant REVENUE_RECIPIENT = payable(address(720));
    // address payable constant JBPROJECTPAYER =
    // payable(0xD37b2FE8748f4795a465c9B851ce8066426A427F); // JBProject 465 Project Payer
    // uint256 public constant METADATA_PROJECT_ID = 465;
    uint256 public constant PRICE_IN_WEI = 0.01 ether;
    string public constant CONTRACT_URI = "xyz";

    // Config
    Config public config =
        Config(JBPROJECTS, REVENUE_RECIPIENT, PRICE_IN_WEI, CONTRACT_URI);
    // Deploy Juicebox1155
    JuiceboxProjectCards juiceboxProjectCards =
        new JuiceboxProjectCards(config);

    // Test that you can mint an NFT
    function testMint(uint x) public {
        vm.assume(x < 100 ether); // Assume that the value is less than 100 ETH
        vm.assume(x > PRICE_IN_WEI); // Assume that the value is greater than the price (0.01 ETH
        vm.deal(address(420), x); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        uint balanceBefore = address(juiceboxProjectCards).balance; // Get balance of the NFT contract before minting
        juiceboxProjectCards.mint{value: x}(1); // Mint an NFT
        uint balanceAfter = address(juiceboxProjectCards).balance; // Get balance of the NFT contract after minting
        vm.stopPrank();
        assertEq(balanceBefore + x, balanceAfter); // Compare the two balances
    }

    // Test that user can mintMany
    function testMintMany(uint x, uint y) public {
        vm.assume(x > 0 && x < 100); // Assume that the number of NFTs to mint is 0 < x < 100
        vm.assume(y > 0 && y < 300); // Assume that the project ID to mint is less than 400
        vm.deal(address(420), 10 ether); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        uint balanceBefore = address(juiceboxProjectCards).balance; // Get balance of the NFT contract before minting
        juiceboxProjectCards.mintMany{value: x * PRICE_IN_WEI}(y, x); // Mint many NFTs
        uint balanceAfter = address(juiceboxProjectCards).balance; // Get balance of the NFT contract after minting
        vm.stopPrank();
        assertEq(balanceBefore + x * PRICE_IN_WEI, balanceAfter); // Compare the two balances
        assertEq(juiceboxProjectCards.balanceOf(address(420), y), x); // Check that the user has x NFTs of project y
    }

    // Test that the withdraw function works to an EOA
    function testWithdraw() public {
        juiceboxProjectCards.mint{value: PRICE_IN_WEI}(1); // Mint an NFT
        uint contractBalance = address(juiceboxProjectCards).balance; // Get balance of the project after minting
        uint revenueRecipientBalance = address(REVENUE_RECIPIENT).balance; // Get balance of the revenue recipient before withdrawing
        juiceboxProjectCards.withdraw(); // Withdraw the funds
        uint revenueRecipientBalanceAfter = address(REVENUE_RECIPIENT).balance; // Get balance of the revenue recipient after withdrawing
        assertEq(revenueRecipientBalanceAfter, PRICE_IN_WEI); // Check that funds have moved to the revenue recipient
        assertEq(address(juiceboxProjectCards).balance, 0); // Check that the contract balance is 0
    }

    // Test that contractUri is correctly set in constructor
    function testContractUri() public {
        string memory contractUri = juiceboxProjectCards.contractURI();
        assertEq(contractUri, CONTRACT_URI);
    }

    // Test that contractUri is correctly set in setContractUri
    function testSetContractUri() public {
        juiceboxProjectCards.setContractUri("abc");
        string memory contractUri = juiceboxProjectCards.contractURI();
        assertEq(contractUri, "abc");
    }

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
