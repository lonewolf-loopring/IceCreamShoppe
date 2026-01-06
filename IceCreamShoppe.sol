// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract IceCreamShoppe is ERC1155, Ownable, ERC1155Pausable, ERC1155Burnable, ERC1155Supply, ERC2981 {

    string private _contractCID; // _contractURI
    string private _baseCID; // _setURI

    uint96 public constant ROYALTY_PERCENTAGE = 500; // 5% Hardcoded

    string public name = "Ice Cream Shoppe";
    string public symbol = "ICS";

    constructor(address initialOwner, string memory initialContractCID, string memory initialBaseCID)
        ERC1155("") // Handled by override below
        Ownable(initialOwner) // Expected Format : Wallet Address of Contract / Vault Owner

    {
        _contractCID = initialContractCID; // Expected Format : <Collection.json CID>
        _baseCID = initialBaseCID; // Expected Format :<Metadata Folder CID>
        _setDefaultRoyalty(initialOwner, ROYALTY_PERCENTAGE); // 5% H
    }

    // ContractURI Block

    function contractURI() public view returns (string memory) {
        return string.concat("ipfs://", _contractCID);
    }

    function setContractCID(string memory newContractCID) public onlyOwner {
        _contractCID = newContractCID;
    }
  
    // setURI Block
    
    function uri(uint256 /* id */) public view override returns (string memory) {
        return string.concat("ipfs://", _baseCID, "/{id}.json"); // Automatically builds: ipfs://<CID>/0.json
    }

    function setBaseCID(string memory newBaseCID) public onlyOwner {
        _baseCID = newBaseCID;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // Allows changing the receiver address only; royalty % hardcoded
    function updateRoyaltyVault(address newVault) public onlyOwner {
        require(newVault != address(0), "Cannot send to zero address");
        _setDefaultRoyalty(newVault, ROYALTY_PERCENTAGE);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}