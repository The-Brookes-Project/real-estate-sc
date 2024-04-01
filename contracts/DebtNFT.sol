// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract DebtNFT is ERC721, Ownable {
    address public loanContract;

    // Mapping to keep track of frozen tokens
    mapping(uint256 => bool) private _frozenTokens;

    constructor(string memory name, string memory symbol, address _loanContract) ERC721(name, symbol) Ownable(msg.sender) {
        loanContract = _loanContract;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == loanContract, "Only loan contract can mint");
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function freeze(uint256 tokenId) external onlyOwner {
        // No direct _exists check needed; _beforeTokenTransfer will implicitly enforce this
        _frozenTokens[tokenId] = true;
    }

    function unfreeze(uint256 tokenId) external onlyOwner {
        // Similarly, no direct _exists check needed
        _frozenTokens[tokenId] = false;
    }

    // Override functions to prevent transferring of frozen tokens
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(!_frozenTokens[tokenId], "DebtNFT: token is frozen");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(!_frozenTokens[tokenId], "DebtNFT: token is frozen");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function reissue(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}