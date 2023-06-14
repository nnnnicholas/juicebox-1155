// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//Juicebox1155
import "forge-std/Test.sol";
import {JuiceboxCards, Config, IERC1155} from "../src/JuiceboxCards.sol";
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
import {JBSingleTokenPaymentTerminalStore3_1} from "@jbx-protocol/juice-contracts-v3/contracts/JBSingleTokenPaymentTerminalStore3_1.sol";
import {IJBSingleTokenPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBSingleTokenPaymentTerminal.sol";

contract JuiceboxCardsTest is Test, ERC1155Receiver {
    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    uint256 constant FORK_BLOCK_NUMBER = 17437454; // All tests executed at this block
    string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    // uint256 forkId = vm.createSelectFork(vm.envString(MAINNET_RPC_URL)); // Fork latest block
    uint256 forkId =
        vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER); // Fork specific block

    // Mainnet constructor args
    IJBDirectory constant JBDIRECTORY =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea); // JBDirectory V3
    address public constant JBPROJECTS =
        0xD8B4359143eda5B2d763E127Ed27c77addBc47d3;
    // JBSingleTokenPaymentTerminalStore3_1
    //     public constant JBSINGLETOKENPAYMENTTERMINALSTORE3_1 =
    //     JBSingleTokenPaymentTerminalStore3_1(
    //         0x77b0A81AeB61d08C0b23c739969d22c5C9950336
    //     );
    // IJBSingleTokenPaymentTerminal public constant JBPAYMENTTERMINAL =
    //     IJBSingleTokenPaymentTerminal(
    //         0xFA391De95Fcbcd3157268B91d8c7af083E607A5C
    //     );
    // address payable constant REVENUE_RECIPIENT = payable(address(720));
    // address payable constant JBPROJECTPAYER =
    // payable(0xD37b2FE8748f4795a465c9B851ce8066426A427F); // JBProject 465 Project Payer
    uint16 public constant TIP_PROJECT = 465;
    uint64 public constant PRICE_IN_WEI = 0.01 ether;
    string public constant CONTRACT_URI = "xyz";
    address sender = makeAddr("420");

    // Get count of deployed JB Projects
    uint jbProjectsCount = JBProjects(JBPROJECTS).count();

    // Config
    Config public config =
        Config(
            JBPROJECTS,
            TIP_PROJECT,
            PRICE_IN_WEI,
            address(JBDIRECTORY),
            CONTRACT_URI
        );
    // Deploy Juicebox1155
    JuiceboxCards juiceboxCards = new JuiceboxCards(config);

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    // Test to establish average gas cost for minting 1 NFT across cases
    function testMintGasPayNoTip() public {
        juiceboxCards.mint{value: PRICE_IN_WEI}(1, msg.sender, msg.sender);
    }

    function testMintGasPayWithTip() public {
        juiceboxCards.mint{value: PRICE_IN_WEI + 1000}(
            1,
            msg.sender,
            msg.sender
        );
    }

    function testMintGasAddToBalanceNoTip() public {
        juiceboxCards.mint{value: PRICE_IN_WEI}(350, msg.sender, msg.sender);
    }

    function testMintGasAddToBalanceWithTip() public {
        juiceboxCards.mint{value: PRICE_IN_WEI + 1000}(
            350,
            msg.sender,
            msg.sender
        );
    }

    // Exhaustively test that you can mint an NFT
    /// forge-config: default.fuzz.runs = 10000
    function testMintOne(uint value, uint id) public {
        // Set vars
        value = bound(value, PRICE_IN_WEI, 10 ether); // Assume that value is is greater than the price (0.01 ETH) and less than 100 ETH
        id = bound(id, 1, jbProjectsCount); // Assume that the project ID is greater than 0 and less than the total supply of JBProjects
        vm.assume(id != 297 && id != 350); // Projects with known issues, not expected to work. 297 has mismatched payment terminal, 350 is paused.
        vm.assume(
            address(JBDIRECTORY.primaryTerminalOf(id, JBTokens.ETH)) !=
                address(0)
        ); // Assume that the project has a primary terminal on Directory

        // Setup minter wallet
        vm.deal(address(420), value + 0.1 ether); // Send address 420 * ETH
        vm.startPrank(address(420)); // Set the prank address to 420

        // Get terminals
        IJBPaymentTerminal projectTerminal = JBDIRECTORY.primaryTerminalOf(
            id,
            JBTokens.ETH
        );
        IJBPaymentTerminal tipTerminal = JBDIRECTORY.primaryTerminalOf(
            TIP_PROJECT,
            JBTokens.ETH
        );

        // Get BEFORE values
        uint projectBalanceBefore = IJBPayoutRedemptionPaymentTerminal3_1(
            address(projectTerminal)
        ).store().balanceOf(
                IJBSingleTokenPaymentTerminal(address(projectTerminal)),
                id
            ); // Get balance of the project before minting
        uint tipProjectBalanceBefore = IJBPayoutRedemptionPaymentTerminal3_1(
            address(tipTerminal)
        ).store().balanceOf(
                IJBSingleTokenPaymentTerminal(address(tipTerminal)),
                TIP_PROJECT
            ); // Get balance of the tip project before minting

        // Mint an NFT
        juiceboxCards.mint{value: value}(id, address(420), address(420));

        // Get AFTER values
        uint projectBalanceAfter = IJBPayoutRedemptionPaymentTerminal3_1(
            address(projectTerminal)
        ).store().balanceOf(
                IJBSingleTokenPaymentTerminal(address(projectTerminal)),
                id
            ); // Get balance of the project after minting
        uint tipProjectBalanceAfter = IJBPayoutRedemptionPaymentTerminal3_1(
            address(tipTerminal)
        ).store().balanceOf(
                IJBSingleTokenPaymentTerminal(address(tipTerminal)),
                TIP_PROJECT
            ); // Get balance of the fee project after minting

        // Assertions
        assertEq(juiceboxCards.balanceOf(address(420), id), 1); // Check that the user has one NFT
        if (id != TIP_PROJECT) {
            assertEq(
                projectBalanceBefore + PRICE_IN_WEI,
                projectBalanceAfter,
                "Unexpected project balance"
            ); // Check that the project received the funds
            assertEq(
                tipProjectBalanceBefore + value - PRICE_IN_WEI,
                tipProjectBalanceAfter,
                "Unexpected tip project balance"
            ); // Check that the fees were paid to the project
        } else {
            assertEq(
                projectBalanceBefore + value,
                projectBalanceAfter,
                "Unexpected balance when minting tip project Card"
            ); // Check that the project received the funds
        }

        vm.stopPrank();
    }

    // Test that the mint function reverts if the value sent is less than the price
    function testMintInsufficientFunds() public {
        vm.deal(address(420), 1 ether); // Send 420 x ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        vm.expectRevert(JuiceboxCards.InsufficientFunds.selector);
        juiceboxCards.mint{value: 1}(1, address(420), address(420)); // Mint an NFT
        vm.stopPrank();
    }

    // Test that the mint function falls back to `addToBalance` if the project cannot be paid with `pay`
    function testMintAddToBalance() public {
        uint knownUnpayableProject = 350; // Cannot pay this project
        vm.deal(address(420), 1 ether); // Send 420 1 ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        juiceboxCards.mint{value: PRICE_IN_WEI}(
            knownUnpayableProject,
            address(420),
            address(420)
        ); // Mint an NFT
        vm.stopPrank();
    }

    // Test that the mint function reverts if the project cannot be paid with `pay` or `addToBalance`
    function testMintCannotPay() public {
        uint knownUnpayableProject = 297; // Cannot pay or add to balance this project
        vm.deal(address(420), 1 ether); // Send 420 1 ETH
        vm.startPrank(address(420)); // Set the prank address to 420
        vm.expectRevert(
            abi.encodeWithSelector(
                JuiceboxCards.CannotPay.selector,
                knownUnpayableProject
            )
        );
        juiceboxCards.mint{value: PRICE_IN_WEI}(
            knownUnpayableProject,
            address(420),
            address(420)
        ); // Mint an NFT
        vm.stopPrank();
    }

    // Test that the uri returns expeted value
    function testUri() public {
        testMintOne(1, 1); // Mint NFT for project 1, giving the minter 1 eth budget
        string memory uriFromJBProjects = JBProjects(JBPROJECTS).tokenURI(1);
        string memory uriFromContract = juiceboxCards.uri(1);
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
        juiceboxCards.setTipProject(11);

        // Set contract URI
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setContractUri("abc");

        // Set metadata URI
        vm.expectRevert("Ownable: caller is not the owner");
        juiceboxCards.setJBProjects(address(0));

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

    // Test that the supportsInterface function returns false for an unsupported interface
    function testSupportsInterfaceFails() public {
        // Choose a random interface ID that your contract doesn't support.
        // For example, the EIP-721 interface ID.
        bytes4 unsupportedInterfaceId = 0x80ac58cd;

        assertEq(
            juiceboxCards.supportsInterface(unsupportedInterfaceId),
            false
        );
    }

    /// Test that the developer can mint, then loses the ability after renouncing the role
    function testDevMintRole() public {
        address devAddress = address(this); // The address of the dev

        // Set up dev mint arrays
        address[] memory to = new address[](1);
        to[0] = address(420); // The address to mint to

        uint256[] memory projectIds = new uint256[](1);
        projectIds[0] = 1; // The project id

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1; // The amount to mint

        // Make sure the dev has the mint role
        assertEq(
            juiceboxCards.hasRole(juiceboxCards.DEV_MINTER_ROLE(), devAddress),
            true
        );

        // Mint from the dev address
        juiceboxCards.devMint(to, projectIds, amounts);

        // Check that the minting worked
        assertEq(juiceboxCards.balanceOf(to[0], projectIds[0]), amounts[0]);

        // Expect a revert when minting with unequal length arrays
        vm.expectRevert(JuiceboxCards.UnequalLengthArrays.selector);

        // Check that unequal length arrays revert
        juiceboxCards.devMint(to, projectIds, new uint256[](2));

        // Expect a revert when minting with unequal length arrays
        vm.expectRevert(JuiceboxCards.UnequalLengthArrays.selector);

        // Check that unequal length arrays revert
        juiceboxCards.devMint(to, new uint256[](2), amounts);

        // Now, renounce the role
        juiceboxCards.renounceRole(juiceboxCards.DEV_MINTER_ROLE(), devAddress);

        // Check that the dev no longer has the mint role
        assertEq(
            juiceboxCards.hasRole(juiceboxCards.DEV_MINTER_ROLE(), devAddress),
            false
        );

        // Expect a revert when minting now
        vm.expectRevert(JuiceboxCards.NotDevMinter.selector);

        // Attempt to mint from the dev address
        juiceboxCards.devMint(to, projectIds, amounts);
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
    ) external pure returns (bytes4) {
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
