// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//Juicebox1155
import "forge-std/Test.sol";
import {JuiceboxCards, Config, InsufficientFunds, IERC1155} from "../src/JuiceboxCards.sol";
import {ERC1155Receiver, IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// JB
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {JBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/JBProjects.sol";
// import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import {IJBPayoutRedemptionPaymentTerminal3_1} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal3_1.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";

contract JuiceboxCardsTest is Test, ERC1155Receiver {
    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    uint256 constant FORK_BLOCK_NUMBER = 16942000; // All tests executed at this block
    string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    // uint256 forkId = vm.createSelectFork(vm.envString(MAINNET_RPC_URL)); // Fork latest block
    uint256 forkId =
        vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER); // Fork specific block

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
    address sender = makeAddr("420");

    // Get count of deployed JB Projects
    uint jbProjectsCount = JBProjects(JBPROJECTS).count();

    // Config
    Config public config =
        Config(
            JBPROJECTS,
            REVENUE_RECIPIENT,
            PRICE_IN_WEI,
            CONTRACT_URI,
            address(JBDIRECTORY)
        );
    // Deploy Juicebox1155
    JuiceboxCards juiceboxCards = new JuiceboxCards(config);

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    // Test that you can mint an NFT
    function testMintOne(uint value, uint y) public {
        value = bound(value, PRICE_IN_WEI, 100 ether); // Assume that value is is greater than the price (0.01 ETH) and less than 100 ETH
        y = bound(y, 1, jbProjectsCount); // Assume that the project ID is greater than 0 and less than the total supply of JBProjects
        vm.deal(address(420), value); // Send adderss 420 * ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        uint balanceBefore = address(juiceboxCards).balance; // Get balance of the NFT contract before minting
        juiceboxCards.mint{value: value}(y); // Mint an NFT
        uint balanceAfter = address(juiceboxCards).balance; // Get balance of the NFT contract after minting
        vm.stopPrank();
        assertEq(balanceBefore + value, balanceAfter); // Compare the two balances
    }

    // Test that the mint function reverts if the value sent is less than the price
    function testMintInsufficientFunds(uint x) public {
        x = bound(x, 1, PRICE_IN_WEI); // Assume thaht x is greater than zero but less than price of 1 NFT
        vm.deal(address(420), x * PRICE_IN_WEI); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        vm.expectRevert(InsufficientFunds.selector);
        juiceboxCards.mint{value: PRICE_IN_WEI - x}(1); // Mint an NFT
        vm.stopPrank();
    }

    // Test that user can mintMany
    function testMintMany(uint x, uint y) public {
        x = bound(x, 1, 100); // Assume that the number of NFTs to mint is 0 < x < 100
        y = bound(y, 1, jbProjectsCount); // Assume that the project ID to mint is less than total supply of JBProjects
        vm.deal(address(420), 10 ether); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        uint balanceBefore = address(juiceboxCards).balance; // Get balance of the NFT contract before minting
        juiceboxCards.mintMany{value: x * PRICE_IN_WEI}(y, x); // Mint many NFTs
        uint balanceAfter = address(juiceboxCards).balance; // Get balance of the NFT contract after minting
        vm.stopPrank();
        assertEq(balanceBefore + x * PRICE_IN_WEI, balanceAfter); // Compare the two balances
        assertEq(juiceboxCards.balanceOf(address(420), y), x); // Check that the user has x NFTs of project y
    }

    // Test that the mintMany function reverts if the user does not send enough funds
    function testMintManyInsufficientFunds(uint x, uint y) public {
        x = bound(x, 1, PRICE_IN_WEI); // Assume that x is greater than zero but less than or equal to price of 1 NFT
        vm.deal(address(420), x * PRICE_IN_WEI); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        vm.expectRevert(InsufficientFunds.selector);
        juiceboxCards.mintMany{value: x * PRICE_IN_WEI - 1}(y, x); // Mint many NFTs
        vm.stopPrank();
    }

    // Test that the uri returns expeted value
    function testUri() public {
        testMintOne(1, 1); // Mint NFT for project 1, giving the minter 1 eth budget
        string memory uriFromJBProjects = JBProjects(JBPROJECTS).tokenURI(1);
        string memory uriFromContract = juiceboxCards.uri(1);
    }

    // Test that the withdraw function works to an EOA
    function testWithdraw() public {
        juiceboxCards.mint{value: PRICE_IN_WEI * 10}(10); // Mint an NFT
        uint contractBalance = address(juiceboxCards).balance; // Get balance of the project after minting
        uint revenueRecipientBalance = address(REVENUE_RECIPIENT).balance; // Get balance of the revenue recipient before withdrawing
        juiceboxCards.withdrawFees(); // Withdraw the funds
        uint revenueRecipientBalanceAfter = address(REVENUE_RECIPIENT).balance; // Get balance of the revenue recipient after withdrawing
        assertEq(revenueRecipientBalanceAfter, PRICE_IN_WEI * 10); // Check that funds have moved to the revenue recipient
        assertEq(address(juiceboxCards).balance, 0); // Check that the contract balance is 0
    }

    // Test that contractUri is correctly set in constructor
    function testContractUriConstructor() public {
        string memory contractUri = juiceboxCards.contractURI();
        assertEq(contractUri, CONTRACT_URI);
    }

    // Test that contractUri is correctly set in setContractUri
    function testSetContractUri() public {
        juiceboxCards.setContractUri("abc");
        string memory contractUri = juiceboxCards.contractURI();
        assertEq(contractUri, "abc");
    }

    function testOnlyOwnerFunctions() public {
        vm.startPrank(address(420));

        // Set price
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setPrice(0);

        // Set revenue recipient
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setFeeRecipient(address(420));

        // Set contract URI
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setContractUri("abc");

        // Set metadata URI
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setMetadata(address(0));

        vm.stopPrank();
    }

    // Test that the supportsInterface function returns true for ERC1155 and AccessControl
    function testSupportsInterface() public {
        assertEq(
            juiceboxCards.supportsInterface(type(IERC1155).interfaceId),
            true
        );

        assertEq(
            juiceboxCards.supportsInterface(type(AccessControl).interfaceId),
            true
        );
    }

    /*//////////////////////////////////////////////////////////////
                             TEST UTILITIES
    //////////////////////////////////////////////////////////////*/

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
