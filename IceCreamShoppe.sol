// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title IceCreamShoppeUpgradeable
 * @dev UUPS Upgradeable ERC-1155 with royalties and batch-minting utility.
 */
contract IceCreamShoppeUpgradeable is
Initializable,
ERC1155Upgradeable,
OwnableUpgradeable,
ERC1155PausableUpgradeable,
ERC1155BurnableUpgradeable,
ERC1155SupplyUpgradeable,
ERC2981Upgradeable,
UUPSUpgradeable
{
    string private _contractCID;
    string private _baseCID;
    uint96 public constant ROYALTY_PERCENTAGE = 500; // 5%

    string public name;
    string public symbol;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // Secures implementation from being initialized directly
    }

    /**
     * @dev Replaces the constructor. Must be called through the proxy once.
     */
    function initialize(
        address initialOwner,
        string memory initialContractCID,
        string memory initialBaseCID
    ) public initializer {
        __ERC1155_init("");
        __Ownable_init(initialOwner);
        __ERC1155Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        name = "Ice Cream Shoppe";
        symbol = "ICS";
        _contractCID = initialContractCID;
        _baseCID = initialBaseCID;
        _setDefaultRoyalty(initialOwner, ROYALTY_PERCENTAGE);
    }

    // --- UUPS Required Authorization ---
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- URI LOGIC ---
    function contractURI() public view returns (string memory) {
        return string.concat("ipfs://", _contractCID);
    }

    function setContractCID(string memory newContractCID) public onlyOwner {
        _contractCID = newContractCID;
    }

    function uri(uint256 /* id */) public view override returns (string memory) {
        // Automatically builds: ipfs://<CID>/{id}.json
        return string.concat("ipfs://", _baseCID, "/{id}.json");
    }

    function setBaseCID(string memory newBaseCID) public onlyOwner {
        _baseCID = newBaseCID;
    }

    // --- MINTING LOGIC ---
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function mintToMultipleWallets(address[] calldata accounts, uint256 id, uint256 amount, bytes calldata data) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amount, data);
        }
    }

    // --- UTILITIES ---
    function updateRoyaltyVault(address newVault) public onlyOwner {
        require(newVault != address(0), "Cannot send to zero address");
        _setDefaultRoyalty(newVault, ROYALTY_PERCENTAGE);
    }

    function pause() public onlyOwner { _pause(); }
    function unpause() public onlyOwner { _unpause(); }

    // --- REQUIRED OVERRIDES ---
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, ERC2981Upgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
    internal
    override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);
    }
}
