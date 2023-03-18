// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC1155, ERC1155, IERC165} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IJBProjectPayer} from "@jbx-protocol/juice-contracts-v3/contracts/JBETHERC20ProjectPayer.sol";
import {IJBDirectory} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*//////////////////////////////////////////////////////////////
                             STRUCTS
//////////////////////////////////////////////////////////////*/

struct Config {
    address _projects; // The JBProjects contract
    address _revenueRecipient; // The address that mint revenues are forwarded to
    uint256 _price; // The price of the NFT in wei
    string _contractUri; // The URI of the contract metadata
}

/*//////////////////////////////////////////////////////////////
                             ERRORS 
//////////////////////////////////////////////////////////////*/

error InsufficientFunds();

/*//////////////////////////////////////////////////////////////
                             CONTRACT 
 //////////////////////////////////////////////////////////////*/

contract Juicebox1155 is ERC1155, Ownable {
    /*//////////////////////////////////////////////////////////////
                             EVENTS 
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the price of the NFT is set
    event PriceSet(uint256 _price);

    /// @dev Emitted when the address that receives tokens from the Juicebox project that collects revenues is set
    event RevenueRecipientSet(address _revenueRecipient);

    /// @dev Emitted when the address of the JBProjects contract is set
    event MetadataSet(address _JBProjects);

    /// @dev Emitted when the URI of the contract metadata is set
    event ContractUriSet(string _contractUri);

    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The address of the JBProjects contract
    IERC721Metadata public projects;

    /// @dev The address that receives tokens from the Juicebox project that collects revenues
    address public revenueRecipient;

    /// @dev The price of the NFT in wei
    uint256 public price;

    /// @dev The URI of the contract metadata
    string private contractUri;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Config memory _config) ERC1155("") {
        setMetadata(_config._projects); // Set the address of the JBProjects contract as the Metadata resolver
        setRevenueRecipient(_config._revenueRecipient); // Set the address that mint revenues are forwarded to
        setPrice(_config._price); // Set the price of the NFT
        if (bytes(contractUri).length > 0) {
            setContractUri(_config._contractUri); // Set the URI of the contract metadata if it is not empty
        }
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints an NFT
     * @param projectId The ID of the project to mint the NFT for
     */
    function mint(uint256 projectId) external payable {
        if (msg.value < price) {
            revert InsufficientFunds();
        }
        _mint(msg.sender, projectId, 1, bytes("")); // Mint the NFT
        (bool success, ) = address(revenueRecipient).call{value: msg.value}(""); // Send the revenue to the revenue recipient
    }

    /**
     * @notice Returns the URI of the NFT
     * @dev Returns the corresponding URI on the projects contract
     * @param projectId The ID of the project to get the NFT URI for
     */
    function uri(
        uint256 projectId
    ) public view virtual override returns (string memory) {
        return projects.tokenURI(projectId);
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
    ) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
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
     * @notice Sets the address that receives mint revenues
     * @dev Ideally a JBProjectPayer contract whose receive() function forwards revenues to a Juicebox Project
     * @param _revenueRecipient The address that receives mint revenues
     */
    function setRevenueRecipient(address _revenueRecipient) public onlyOwner {
        revenueRecipient = payable(_revenueRecipient);
        emit RevenueRecipientSet(_revenueRecipient);
    }

    /**
     * @notice Sets the address of the JBProjects contract from which to get the NFT URI
     * @param _JBProjects The address of the JBProjects contract
     */
    function setMetadata(address _JBProjects) public onlyOwner {
        projects = IERC721Metadata(_JBProjects);
        emit MetadataSet(_JBProjects);
    }

    /**
     * @notice Sets the contract URI
     * @param _contractUri The URI of the contract metadata
     */
    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
        emit ContractUriSet(_contractUri);
    }
}
