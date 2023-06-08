// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Juicebox Cards v1.2
/// @author @nnnnicholas

import {IERC1155, ERC1155, IERC165} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {IJBTiered721Delegate} from "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721Delegate.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {Config} from "src/Structs/Config.sol";

/*//////////////////////////////////////////////////////////////
                             ERRORS 
//////////////////////////////////////////////////////////////*/

error InsufficientFunds();

/*//////////////////////////////////////////////////////////////
                             CONTRACT 
 //////////////////////////////////////////////////////////////*/

contract JuiceboxCards is ERC1155, Ownable, AccessControl {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                 ACCESS
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DEV_MINTER_ROLE = keccak256("DEV_MINTER_ROLE");

    modifier onlyDevMinter() {
        require(
            hasRole(DEV_MINTER_ROLE, msg.sender),
            "Must have DEV_MINTER_ROLE"
        );
        _;
    }

    function renounceDevMinter() public {
        renounceRole(DEV_MINTER_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             EVENTS 
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the price of the NFT is set
    event PriceSet(uint256 _price);

    /// @dev Emitted when the JBProjects contract address is set
    event JBProjectsSet(address _JBProjects);

    /// @dev Emitted when the contract metadata URI is set
    event ContractUriSet(string _contractUri);

    /// @dev Emitted when the directory address is set
    event DirectorySet(address _directory);

    /// @dev Emited when the fee recipient project ID is set
    event FeeProjectSet(uint256 _feeProject);

    /// @dev Emitted when fees are withdrawn
    event WithdrewFees(uint256 _feeProject, uint256 _amount);

    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the JBProjects contract
    IERC721Metadata public jbProjects;

    /// @dev The address of the JBDirectory contract
    IJBDirectory public directory;

    /// @dev The project that receives fees
    uint256 public feeProject;

    /// @dev The price to buy a Card in wei
    uint256 public price;

    /// @dev The URI of the contract metadata
    string private contractUri;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Config memory _config) ERC1155("") {
        _setupRole(DEV_MINTER_ROLE, msg.sender);
        setJbProjects(_config.jbProjects); // Set the JBProjects contract that is the metadata source
        setFeeProject(_config.feeProject); // Set the project that receives fees
        setPrice(_config.price); // Set the Card price
        setDirectory(_config.directory); // Set the JBDirectory contract
        setContractUri(_config.contractUri); // Set the contract metadata URI
    }

    /*//////////////////////////////////////////////////////////////
                       EXTERNAL/PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints a Card to the caller
     * @param projectId The ID of the project card to mint
     */
    function mint(uint256 projectId) external payable {
        if (msg.value < price) {
            revert InsufficientFunds();
        }

        // Get the payment terminal the project currently prefers to accept ETH through.
        IJBPaymentTerminal _ethTerminal = directory.primaryTerminalOf(
            projectId,
            JBTokens.ETH
        );

        // Create the metadata for the payment
        bytes memory _payMetadata = abi.encode(
            bytes32(feeProject), // Referral project ID.
            bytes32(0),
            bytes4(0)
        );

        // Pay the project.
        _ethTerminal.pay{value: price}(
            projectId,
            price,
            JBTokens.ETH,
            msg.sender,
            0,
            false,
            "Juicebox Card minted",
            _payMetadata
        );

        // Mint the NFT.
        _mint(msg.sender, projectId, 1, bytes(""));
    }

    /**
     * @notice Transfers accumulated fees to the fee recipient project
     */
    function withdrawFees() external {
        uint256 balance = address(this).balance;

        // Get the payment terminal the project currently prefers to accept ETH through.
        IJBPaymentTerminal _ethTerminal = directory.primaryTerminalOf(
            feeProject,
            JBTokens.ETH
        );

        // Pay the project.
        _ethTerminal.addToBalanceOf{value: balance}(
            feeProject,
            balance,
            JBTokens.ETH,
            "Juicebox Card fees",
            bytes("")
        );

        emit WithdrewFees(feeProject, balance);
    }

    /**
     * @notice Returns the URI of the NFT
     * @dev Returns the corresponding URI on the JBProjects contract
     * @param projectId The ID of the project to get the NFT URI for
     */
    function uri(
        uint256 projectId
    ) public view virtual override returns (string memory) {
        return jbProjects.tokenURI(projectId);
    }

    /**
     * @notice Returns the contract URI
     */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Returns whether or not the contract supports an interface
     * @param interfaceId The ID of the interface to check
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            type(AccessControl).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the Card price
     * @param _price The Card price in wei
     */
    function setPrice(uint64 _price) public onlyOwner {
        price = uint256(_price);
        emit PriceSet(_price);
    }

    /**
     * @notice Sets the project that receives fees
     * @param _feeProject The address that receives mint fees
     */
    function setFeeProject(uint16 _feeProject) public onlyOwner {
        feeProject = uint256(_feeProject);
        emit FeeProjectSet(_feeProject);
    }

    /**
     * @notice Sets the address of the JBProjects contract from which to get the NFT URI
     * @param _JBProjects The address of the JBProjects contract
     */
    function setJbProjects(address _JBProjects) public onlyOwner {
        jbProjects = IERC721Metadata(_JBProjects);
        emit JBProjectsSet(_JBProjects);
    }

    /**
     * @notice Sets the address of the JBDirectory contract from which to get the payment terminal
     * @param _directory The address of the JBDirectory contract
     */
    function setDirectory(address _directory) public onlyOwner {
        directory = IJBDirectory(_directory);
        emit DirectorySet(_directory);
    }

    /**
     * @notice Sets the contract URI
     * @param _contractUri The URI of the contract metadata
     */
    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
        emit ContractUriSet(_contractUri);
    }

    /**
     * @notice Mints multiple NFTs to any addresses without fee
     * @param to The addresses to mint the NFTs to
     * @param projectIds The IDs of the projects to mint the NFTs for
     * @param amounts The amounts of each NFTs to mint
     */
    function devMint(
        address[] calldata to,
        uint256[] calldata projectIds,
        uint256[] calldata amounts
    ) external onlyDevMinter {
        require(
            to.length == projectIds.length &&
                projectIds.length == amounts.length,
            "Input arrays unequal length"
        );
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], projectIds[i], amounts[i], bytes(""));
        }
    }
}
