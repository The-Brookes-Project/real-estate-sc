// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DebtNFT is ERC721, Ownable {
    address public loanContract;

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

    function reissue(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}