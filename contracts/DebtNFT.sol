// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./DebtAccessControl.sol";

/**
 * @title DebtNFT
 * @dev Extends ERC721URIStorage to support minting, burning, freezing, and unfreezing NFTs.
 * It integrates access control for administrative actions and adds functionality to freeze tokens,
 * preventing transfers. It's intended for use in debt-related financial applications.
 */
contract DebtNFT is ERC721URIStorage, DebtAccessControl {
    uint256 public nextTokenId;
    // Mapping to keep track of frozen tokens
    mapping(uint256 => bool) private _frozenTokens;

    /**
     * @dev Initializes the contract by setting a name and a symbol for the token collection.
     * Grants default admin role to the provided `_admin` address.
     * Grants manager role to the caller contract to allow it to mint NFTs.
     * @param name Name of the NFT collection.
     * @param symbol Symbol of the NFT collection.
     * @param _admin Address to be granted the admin role, allowing them to manage roles and frozen tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        address _admin
    ) ERC721(name, symbol) DebtAccessControl(_admin) {
        // Adding the DebtLogic Contract as manager to allow for minting
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Mints a new token to the specified address with the given token URI.
     * Can only be called by the loan contract.
     * @param to Address to receive the minted token.
     * @param tokenURI URI for the token metadata.
     * @return The tokenId of the minted token.
     */
    function mint(
        address to,
        string memory tokenURI
    ) public onlyManager returns (uint256) {
        uint tokenId = nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    /**
     * @dev Burns a token, removing it from existence. Can only be called by an admin.
     * @param tokenId ID of the token to burn.
     */
    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    /**
     * @dev Freezes a token, preventing any transfers. Can only be called by an admin.
     * @param tokenId ID of the token to freeze.
     */
    function freeze(uint256 tokenId) external onlyAdmin {
        // No direct _exists check needed; _beforeTokenTransfer will implicitly enforce this
        _frozenTokens[tokenId] = true;
    }

    /**
     * @dev Unfreezes a token, allowing transfers again. Can only be called by an admin.
     * @param tokenId ID of the token to unfreeze.
     */
    function unfreeze(uint256 tokenId) external onlyAdmin {
        // Similarly, no direct _exists check needed
        _frozenTokens[tokenId] = false;
    }

    /**
     * @dev Overrides safeTransferFrom to prevent transferring of frozen tokens.
     * @param from Current owner of the token.
     * @param to Address to receive the ownership of the given token ID.
     * @param tokenId ID of the token to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        require(!_frozenTokens[tokenId], "DebtNFT: token is frozen");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
