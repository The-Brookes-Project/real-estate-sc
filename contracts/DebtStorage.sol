// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./DebtAccessControl.sol";

// Enums for managing currencies and debt status
enum Currency {
    ETH,
    USDC
}

enum DebtStatus {
    OPEN,
    FUNDED,
    SETTLED,
    UNFUNDED
}

/**
 * @title DebtStorage
 * @dev Contract for managing the storage, creation, and updating of debts. This contract leverages role-based access control for managing permissions.
 */
contract DebtStorage is DebtAccessControl {
    // Public state variables
    mapping(uint256 => Debt) public debts; // Mapping of debt ID to Debt structure for storing debt information.
    mapping(uint256 => mapping(uint256 => uint256)) public investments; // Mapping of debt ID to another mapping of token ID to investment amount.
    uint256 public debtCount; // Counter for the total number of debts stored.
    address payable public feeWallet; // Wallet address for collecting fees.
    address public usdcTokenAddress; // Address of the USDC token used for investments.

    /**
     * @dev Struct for representing a debt.
     * @param maxAmount Maximum amount of debt.
     * @param interestRate Interest rate of the debt.
     * @param term Term of the debt.
     * @param walletAddress Address of the wallet associated with the debt.
     * @param minInvestmentAmount Minimum investment amount for the debt.
     * @param totalInvestment Total amount invested in the debt.
     * @param status Current status of the debt.
     * @param startDate Start date of the debt.
     * @param settledDate Date the debt was settled.
     * @param nftContractAddress Address of the NFT contract associated with the debt.
     * @param tokenURI URI for the token associated with the debt.
     * @param currency Currency of the debt (e.g., ETH, USDC).
     */
    struct Debt {
        uint256 maxAmount;
        uint256 interestRate;
        uint256 term;
        address payable walletAddress;
        uint256 minInvestmentAmount;
        uint256 totalInvestment;
        DebtStatus status;
        uint256 startDate;
        uint256 settledDate;
        address nftContractAddress;
        string tokenURI;
        Currency currency;
    }

    /**
     * @dev Constructor for DebtStorage contract.
     * @param _admin Address to be granted default admin role.
     * @param _feeWallet Address of the wallet for collecting fees.
     * @param _usdcTokenAddress Address of the USDC token used for investments.
     */
    constructor(
        address _admin,
        address payable _feeWallet,
        address _usdcTokenAddress
    ) DebtAccessControl(_admin) {
        feeWallet = _feeWallet;
        usdcTokenAddress = _usdcTokenAddress;
    }

    /**
     * @dev Function to add a new debt. Can only be called by a manager.
     * @param _debt Struct containing the debt details.
     */
    function addDebt(Debt memory _debt) public onlyManager {
        debts[debtCount] = _debt;
        debtCount += 1;
    }

    /**
     * @dev Function to update an existing debt. Can only be called by a manager.
     * @param _id The ID of the debt to update.
     * @param _debt Struct containing the new debt details.
     */
    function updateDebt(uint256 _id, Debt memory _debt) public onlyManager {
        require(
            debts[_id].maxAmount != 0,
            "Debt with the provided id does not exist"
        );
        debts[_id] = _debt;
    }

    /**
     * @dev Function to set investment for a debt. Can only be called by a manager.
     * @param _debtId The ID of the debt.
     * @param _tokenId The ID of the token being used for investment.
     * @param _amount The amount of the investment.
     */
    function setInvestment(
        uint256 _debtId,
        uint256 _tokenId,
        uint256 _amount
    ) public onlyManager {
        require(
            investments[_debtId][_tokenId] == 0,
            "TokenId under provided debtId already exists"
        );
        investments[_debtId][_tokenId] = _amount;
    }

    /**
     * @dev Function to retrieve a debt's details by its ID.
     * @param _id The ID of the debt to retrieve.
     * @return Debt Struct containing the debt details.
     */
    function getDebt(uint256 _id) public view returns (Debt memory) {
        return debts[_id];
    }

    /**
     * @dev Function to set the fee wallet address. Can only be called by an admin.
     * @param _feeWallet The new fee wallet address.
     */
    function setFeeWallet(address payable _feeWallet) external onlyAdmin {
        feeWallet = _feeWallet;
    }
}
