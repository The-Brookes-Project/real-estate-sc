// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SinglePropertyToken is
ERC721,
ERC721URIStorage,
ERC721Pausable,
AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Property-specific metadata (fixed for this contract)
    enum AssetType { DEBT, EQUITY, HYBRID }
    enum InvestorType { PUBLIC, ACCREDITED, WHITELISTED }
    enum PayoutType { DIVIDEND, FIXED_INTEREST, REVENUE_SHARING, NONE }
    enum PayoutFrequency { MONTHLY, QUARTERLY, ANNUALLY }

    struct PropertyDetails {
        AssetType assetType;
        uint256 assetValuation;
        InvestorType investorType;
        bool kycRequired;
        PayoutType payoutType;
        PayoutFrequency payoutFrequency;
        uint256 yieldRate; // Stored as basis points (e.g., 500 = 5%)
        bool hasVotingRights;
        uint256 votingThreshold;
        string propertyURI; // IPFS or other URI containing additional property details
    }

    // Fixed property details for this contract
    PropertyDetails public propertyDetails;

    // Total supply configuration
    uint256 public maxSupply;
    uint256 private _currentSupply;

    event PropertyDetailsSet(PropertyDetails details);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        PropertyDetails memory details
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        maxSupply = _maxSupply;
        propertyDetails = details;

        emit PropertyDetailsSet(details);
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function mint(address to) public onlyRole(MANAGER_ROLE) {
        require(_currentSupply < maxSupply, "Maximum supply reached");
        _currentSupply++;
        _safeMint(to, _currentSupply);
    }

    function burn(uint256 tokenId) public {
        require(
            _ownerOf(tokenId) == _msgSender() ||
            isApprovedForAll(_ownerOf(tokenId), _msgSender()) ||
            getApproved(tokenId) == _msgSender(),
            "Caller is not owner nor approved"
        );
        _currentSupply--;
        _burn(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _currentSupply;
    }

    // Emergency function to update property valuation if needed
    function updateValuation(uint256 newValuation) public onlyRole(MANAGER_ROLE) {
        propertyDetails.assetValuation = newValuation;
        emit PropertyDetailsSet(propertyDetails);
    }

    // Emergency function to update yield rate if needed
    function updateYieldRate(uint256 newYieldRate) public onlyRole(MANAGER_ROLE) {
        require(newYieldRate <= 10000, "Yield rate cannot exceed 100%");
        propertyDetails.yieldRate = newYieldRate;
        emit PropertyDetailsSet(propertyDetails);
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Pausable)
    returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721URIStorage, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
