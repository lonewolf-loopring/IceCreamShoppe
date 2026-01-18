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
 * @title IceCreamShoppeV2
 * @dev UUPS Upgradeable ERC-1155 with surgical per-token CID management.
 */
contract IceCreamShoppeV2 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    // --- STORAGE (Maintain same order as V1 to avoid collisions) ---
    mapping(uint256 => string) private _tokenCIDs; 
    string private _contractCID;
    string private _baseCID; // Kept in storage to maintain alignment, even if unused
    uint96 public constant ROYALTY_PERCENTAGE = 500; // 5%
    string public name;
    string public symbol;

    // Reserved slots for future upgrades (like shiny borders/toppings)
    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // No need to re-call initialize if already deployed, but kept for new proxies
    function initialize(
        address initialOwner,
        string memory initialContractCID
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
        _setDefaultRoyalty(initialOwner, ROYALTY_PERCENTAGE);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- URI LOGIC (Visibility Fixed) ---
    
    // Returns the collection-level JSON
    function contractURI() public view returns (string memory) {
        return string.concat("ipfs://", _contractCID);
    }

    // Returns the specific JSON for an ID (e.g. ipfs://Qm...CID)
    function uri(uint256 id) public view override returns (string memory) {
        string memory cid = _tokenCIDs[id];
        require(bytes(cid).length > 0, "URI not set for this ID");
        return string.concat("ipfs://", cid);
    }

    // --- ADMIN ACTIONS ---

    function setTokenURI(uint256 id, string memory newCID) public onlyOwner {
        _tokenCIDs[id] = newCID;
        emit URI(string.concat("ipfs://", newCID), id);
    }

    function setContractCID(string memory newContractCID) public onlyOwner {
        _contractCID = newContractCID;
    }

    // --- MINTING ---

    /**
     * @dev Surgical mint: Assigns a CID and mints tokens in one transaction.
     */
    function mintWithURI(
        address account, 
        uint256 id, 
        uint256 amount, 
        string memory cid, 
        bytes memory data
    ) public onlyOwner {
        _tokenCIDs[id] = cid;
        _mint(account, id, amount, data);
        emit URI(string.concat("ipfs://", cid), id);
    }

    // --- UTILS ---
    function pause() public onlyOwner { _pause(); }
    function unpause() public onlyOwner { _unpause(); }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable) {
        super._update(from, to, ids, values);
    }
}