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
            "Must have dev minter role"
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

    /// @dev Emitted when the fee recipient address is set
    event FeeRecipientSet(address _feeRecipient);

    /// @dev Emitted when the JBProjects contract address is set
    event MetadataSet(address _JBProjects);

    /// @dev Emitted when the contract metadata URI is set
    event ContractUriSet(string _contractUri);

    /// @dev Emitted when fees are withdrawn
    event WithdrewFees(address _feeRecipient, uint256 _amount);

    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the JBProjects contract
    IERC721Metadata public jbProjects;

    /// @dev The address of the JBDirectory contract
    IJBDirectory public directory;

    /// @dev The address that receives fees
    address payable public feeRecipient;

    /// @dev The price to buy a Card in wei
    uint256 public price;

    /// @dev The URI of the contract metadata
    string private contractUri;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Config memory _config) ERC1155("") {
        _setupRole(DEV_MINTER_ROLE, msg.sender);
        setMetadata(_config.jbProjects);
        setFeeRecipient(_config.feeRecipient);
        setPrice(_config.price);
        setContractUri(_config.contractUri);
        setDirectory(_config.directory);
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

        // Pay the project.
        _ethTerminal.pay{value: price}(
            projectId,
            price,
            JBTokens.ETH,
            msg.sender,
            0,
            false,
            "Juicebox Card minted",
            bytes("")
        );

        // Mint the NFT.
        _mint(msg.sender, projectId, 1, bytes(""));
    }

    /**
     * @notice Mints multiple Cards to the caller
     * @param projectId The ID of the project card to mint
     * @param amount The amount of NFTs to mint
     */
    function mintMany(uint256 projectId, uint256 amount) external payable {
        if (msg.value < price * amount) {
            revert InsufficientFunds();
        }

        // Get the payment terminal the project currently prefers to accept ETH through.
        IJBPaymentTerminal _ethTerminal = directory.primaryTerminalOf(
            projectId,
            JBTokens.ETH
        );

        // Pay the project.
        _ethTerminal.pay{value: price * amount}(
            projectId,
            price * amount,
            JBTokens.ETH,
            msg.sender,
            0,
            false,
            string.concat(amount.toString(), " Juicebox Cards minted"),
            bytes("")
        );

        // Mint the NFTs.
        _mint(msg.sender, projectId, amount, bytes(""));
    }

    /**
     * @notice Transfers accumulated fees to the fee recipient
     */
    function withdrawFees() external {
        uint256 balance = address(this).balance;
        Address.sendValue(feeRecipient, balance);
        emit WithdrewFees(feeRecipient, balance);
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
     * @notice Sets the price of the NFT
     * @param _price The price of the NFT in wei
     */
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit PriceSet(_price);
    }

    /**
     * @notice Sets the address that receives mint fees
     * @dev Ideally a JBProjectPayer contract whose receive() function forwards fees to a Juicebox Project
     * @param _feeRecipient The address that receives mint fees
     */
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        feeRecipient = payable(_feeRecipient);
        emit FeeRecipientSet(_feeRecipient);
    }

    /**
     * @notice Sets the address of the JBProjects contract from which to get the NFT URI
     * @param _JBProjects The address of the JBProjects contract
     */
    function setMetadata(address _JBProjects) public onlyOwner {
        jbProjects = IERC721Metadata(_JBProjects);
        emit MetadataSet(_JBProjects);
    }

    function setDirectory(address _directory) public onlyOwner {
        directory = IJBDirectory(_directory);
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
            "Input arrays must have the same length"
        );
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], projectIds[i], amounts[i], bytes(""));
        }
    }
}
