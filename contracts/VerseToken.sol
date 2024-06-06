pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReceiptToken is ERC721URIStorage, Ownable {
    uint256 private _maxSupply;
    uint256 private _percentageInterest;
    string private _description;
    string private _location;
    string private _value;
    string private _other;
    uint256 private _nextTokenId = 1;
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 interest,
        string memory description,
        string memory location,
        string memory value,
        string memory other,
        string memory baseTokenURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _maxSupply = maxSupply;
        _percentageInterest = interest;
        _description = description;
        _location = location;
        _value = value;
        _other = other;
        _baseTokenURI = baseTokenURI;
    }

    function mint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        string memory tokenURI = string(
            abi.encodePacked(
                _baseTokenURI,
                toAsciiString(address(this)),
                "/",
                uint2str(tokenId),
                "/"
            )
        );
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

    function value() public view returns (string memory) {
        return _value;
    }

    function other() public view returns (string memory) {
        return _other;
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            uint8 b = uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i))));
            uint8 hi = b / 16;
            uint8 lo = b - 16 * hi;
            s[2 + 2 * i] = char(hi);
            s[2 + 2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(uint8 b) internal pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x57);
        }
    }
}
