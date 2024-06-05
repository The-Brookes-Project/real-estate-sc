pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReceiptToken is ERC721URIStorage, Ownable {
    uint256 private _maxSupply;
    uint256 private _percentageInterest;
    string private _description;
    string private _location;
    uint256 private _value;
    string private _landTitleRegistry;
    uint256 private _nextTokenId = 1;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupplyArg,
        uint256 percentageInterestArg,
        string memory descriptionArg,
        string memory locationArg,
        uint256 valueArg,
        string memory landTitleRegistryArg
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _maxSupply = maxSupplyArg;
        _percentageInterest = percentageInterestArg;
        _description = descriptionArg;
        _location = locationArg;
        _value = valueArg;
        _landTitleRegistry = landTitleRegistryArg;
    }

    function mint(
        address to,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function reissue(
        address to,
        uint256 tokenId,
        string memory tokenURI
    ) public onlyOwner {
        _burn(tokenId);
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function percentageInterest() public view returns (uint256) {
        return _percentageInterest;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function location() public view returns (string memory) {
        return _location;
    }

    function value() public view returns (uint256) {
        return _value;
    }

    function landTitleRegistry() public view returns (string memory) {
        return _landTitleRegistry;
    }
}
