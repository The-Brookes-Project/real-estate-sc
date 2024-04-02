// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./DebtStorage.sol";
import "./DebtNFT.sol";

/**
 * @title DebtLogic
 * @dev A smart contract for managing real-estate debt loans and investments using NFTs.
 */
contract DebtLogic is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    DebtStorage public ds;
    function initialize(address _storageAddress) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        ds = DebtStorage(_storageAddress);
    }
    event DepositAdded(uint256 indexed debtId, address indexed investor, uint256 amount);
    event DebtPaidOff(uint256 indexed debtId, uint256 amount);
    event DepositWithdrawn(uint256 indexed debtId, address indexed investor, uint256 amount);


    /**
     * @dev Adds a deposit to a debt, which mints the NFT representing the investment.
     * @param _debtId The ID of the debt.
     */
    function addDeposit(uint256 _debtId, uint256 _amt) external payable nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(debt.status == DebtStatus.OPEN, "Loan is not accepting funds from deposits");
        require(debt.totalInvestment + _amt <= debt.maxAmount, "Investment limit exceeded");

        // Ensure user provided sufficient amount in specified debt currency
        if(debt.currency == Currency.ETH) {
            require(msg.value == _amt, "Incorrect ETH amount");
            require(msg.value >= debt.minInvestmentAmount, "Minimum investment amount not sufficient");
        } else if(debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
            require(usdcToken.allowance(msg.sender, address(this)) >= debt.minInvestmentAmount, "Minimum investment amount not sufficient");
            require(usdcToken.transferFrom(msg.sender, address(this), _amt), "USDC transfer failed");
        }
        // Mint NFT which is associated with the investment amount
        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
        uint256 tokenId = nftContract.mint(msg.sender, debt.tokenURI);
        ds.setInvestment(_debtId, tokenId, _amt);

        // Update total investment amount on the debt
        debt.totalInvestment = debt.totalInvestment + _amt;
        ds.setDebt(_debtId, debt);
        emit DepositAdded(_debtId, msg.sender, _amt);
    }

    /**
    * @dev Withdraws a deposit and interest for an investor.
     * @param _debtId The ID of the debt.
     * @param _tokenId The ID of the NFT token.
     */
    function withdrawDeposit(uint256 _debtId, uint256 _tokenId) external nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(debt.status == DebtStatus.OPEN || debt.status == DebtStatus.SETTLED, "Invalid loan status");
        require(debt.totalInvestment > 0, "No funds left to settle");
        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the NFT");
        uint256 investmentAmount = ds.investments(_debtId, _tokenId);
        require(investmentAmount > 0, "No deposit found");

        // Calculate interest for the amount associated with the NFT
        uint256 interest = calculateInterest(_debtId, investmentAmount);
        uint256 totalWithdrawal = investmentAmount + interest;

        nftContract.burn(_tokenId);

        if (debt.currency == Currency.ETH) {
            require(address(this).balance >= totalWithdrawal, "Insufficient contract balance");
            (bool success, ) = payable(msg.sender).call{value: totalWithdrawal}("");
            require(success, "Transfer failed");
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
            require(usdcToken.balanceOf(address(this)) >= totalWithdrawal, "Insufficient contract balance");
            require(usdcToken.transfer(msg.sender, totalWithdrawal), "Transfer failed");
        }

        debt.totalInvestment -= investmentAmount;
        ds.setDebt(_debtId, debt);
        emit DepositWithdrawn(_debtId, msg.sender, totalWithdrawal);
    }

    /**
     * @dev Pays off a debt.
     * @param _debtId The ID of the debt.
     */
    function payOffDebt(uint256 _debtId) external payable nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(debt.status == DebtStatus.FUNDED, "Loan not funded");

        uint256 interest = calculateInterest(_debtId, debt.maxAmount);
        uint256 totalPayment = debt.maxAmount + interest;

        if (debt.currency == Currency.ETH) {
            require(msg.value >= totalPayment, "Insufficient payment");
            debt.walletAddress.transfer(totalPayment);
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
            require(usdcToken.allowance(msg.sender, address(this)) >= totalPayment, "Insufficient allowance");
            require(usdcToken.transferFrom(msg.sender, debt.walletAddress, totalPayment), "Transfer failed");
        }

        debt.status = DebtStatus.SETTLED;
        debt.settledDate = block.timestamp;
        ds.setDebt(_debtId, debt);
        emit DebtPaidOff(_debtId, totalPayment);
    }

    /**
     * @dev Calculates the interest for a debt.
     * @param _debtId The ID of the debt.
     * @param _amount The amount to calculate the interest on
     * @return The calculated interest.
     */
    function calculateInterest(uint256 _debtId, uint256 _amount) public view returns (uint256) {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        uint256 timePassed;

        // Check if the debt is settled
        if (debt.settledDate == 0) {
            // If not settled, use current time to calculate time passed
            timePassed = block.timestamp - debt.startDate;
        } else {
            // If settled, use settledDate to calculate time passed
            timePassed = debt.settledDate - debt.startDate;
        }

        uint256 dailyInterest = debt.interestRate / 10000;
        uint256 interestAccrued = _amount * dailyInterest * timePassed / (1 days);
        return interestAccrued;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}