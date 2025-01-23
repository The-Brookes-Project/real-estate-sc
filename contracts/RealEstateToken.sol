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

    enum AssetType {
        DEBT,
        EQUITY,
        HYBRID
    }
    enum InvestorType {
        PUBLIC,
        ACCREDITED,
        WHITELISTED
    }
    enum PayoutType {
        DIVIDEND,
        FIXED_INTEREST,
        REVENUE_SHARING,
        NONE
    }
    enum PayoutFrequency {
        MONTHLY,
        QUARTERLY,
        ANNUALLY
    }

    struct PropertyDetails {
        AssetType assetType;
        uint256 assetValuation;
        InvestorType investorType;
        bool kycRequired;
        PayoutType payoutType;
        PayoutFrequency payoutFrequency;
        uint256 yieldRate; // Basis points (e.g., 500 = 5%)
        bool hasVotingRights;
        uint256 votingThreshold;
        string propertyURI; // IPFS URI with additional details
    }

    struct Payment {
        address recipient;
        uint256 amount;
        string paymentId;
        uint256 timestamp;
        uint256 tokenId;
    }

    PropertyDetails public propertyDetails;
    uint256 public maxSupply;
    uint256 private _currentSupply;

    Payment[] public payments;
    mapping(uint256 => uint256) public totalPaymentsByToken;
    mapping(address => uint256) public totalPaymentsByAddress;

    event PaymentRecorded(
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 amount,
        string paymentId,
        uint256 timestamp
    );
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

    function recordPayment(
        uint256 tokenId,
        uint256 amount,
        string calldata paymentId
    ) public onlyRole(MANAGER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(bytes(paymentId).length > 0, "Payment ID cannot be empty");

        address recipient = ownerOf(tokenId);
        Payment memory newPayment = Payment({
            recipient: recipient,
            amount: amount,
            paymentId: paymentId,
            timestamp: block.timestamp,
            tokenId: tokenId
        });

        payments.push(newPayment);
        totalPaymentsByToken[tokenId] += amount;
        totalPaymentsByAddress[recipient] += amount;

        emit PaymentRecorded(
            recipient,
            tokenId,
            amount,
            paymentId,
            block.timestamp
        );
    }

    function getPaymentsByToken(
        uint256 tokenId
    ) public view returns (Payment[] memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        uint256 count = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].tokenId == tokenId) {
                count++;
            }
        }

        Payment[] memory tokenPayments = new Payment[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].tokenId == tokenId) {
                tokenPayments[index] = payments[i];
                index++;
            }
        }
        return tokenPayments;
    }

    function getPaymentsByAddress(
        address wallet
    ) public view returns (Payment[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].recipient == wallet) {
                count++;
            }
        }

        Payment[] memory addressPayments = new Payment[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].recipient == wallet) {
                addressPayments[index] = payments[i];
                index++;
            }
        }
        return addressPayments;
    }

    function getPaymentCount() public view returns (uint256) {
        return payments.length;
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

    function updateValuation(
        uint256 newValuation
    ) public onlyRole(MANAGER_ROLE) {
        propertyDetails.assetValuation = newValuation;
        emit PropertyDetailsSet(propertyDetails);
    }

    function updateYieldRate(
        uint256 newYieldRate
    ) public onlyRole(MANAGER_ROLE) {
        require(newYieldRate <= 10000, "Yield rate cannot exceed 100%");
        propertyDetails.yieldRate = newYieldRate;
        emit PropertyDetailsSet(propertyDetails);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
