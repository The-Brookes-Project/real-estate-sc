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
 * @title DebtAdmin
 * @dev The admin interface for interacting with the debt
 */
contract DebtAdmin is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    DebtStorage public ds;

    function initialize(address _storageAddress) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        ds = DebtStorage(_storageAddress);
    }

    event DebtCreated(uint256 indexed debtId, uint256 amount, uint256 interestRate, uint256 term);
    event DepositReturned(uint256 indexed debtId, address indexed investor, uint256 amount);
    event LoanDisbursed(uint256 indexed debtId, uint256 amount);

    /**
     * @dev Creates a new debt.
     * @param _amt The amount of the debt.
     * @param _interestRate The interest rate of the debt.
     * @param _term The term of the debt in months.
     * @param _walletAddress The wallet address of the debtor to disburse to.
     * @param _minInvestmentAmount The minimum investment amount required for deposit.
     */
    function createDebt(
        uint256 _amt,
        uint256 _interestRate,
        uint256 _term,
        address payable _walletAddress,
        uint256 _minInvestmentAmount,
        string memory _tokenURI,
        Currency _currency
    ) external onlyOwner {
        ds.incrementDebtCount();
        DebtNFT nftContract = new DebtNFT("Debt NFT", "DEBT", address(this));
        ds.setDebt(ds.debtCount(), DebtStorage.Debt({
            maxAmount: _amt,
            interestRate: _interestRate,
            term: _term,
            walletAddress: _walletAddress,
            minInvestmentAmount: _minInvestmentAmount,
            totalInvestment: 0,
            status: DebtStatus.OPEN,
            startDate: 0,
            settledDate: 0,
            nftContractAddress : address(nftContract),
            tokenURI : _tokenURI,
            currency: _currency
        }));
        emit DebtCreated(ds.debtCount(), _amt, _interestRate, _term);
    }

    /**
     * @dev Disburses a loan once the investment goal has reached. Disables users from withdrawing from the pool.
     * @param _debtId The ID of the debt.
     */
    function disburseLoan(uint256 _debtId) external onlyOwner nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(debt.status == DebtStatus.OPEN, "Current loan status needs to be OPEN");
        require(debt.totalInvestment == debt.maxAmount, "Investment goal not reached");

        // Transfer the Verseprop fee 2% to feeWallet and the rest to the debtor
        uint256 versepropFee = debt.totalInvestment * 2 / 100;
        if (debt.currency == Currency.ETH) {
            ds.feeWallet().transfer(versepropFee);
            uint256 loanAmount = debt.totalInvestment - versepropFee;
            debt.walletAddress.transfer(loanAmount);
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());

            // Transfer the fee to the fee wallet
            require(usdcToken.transfer(ds.feeWallet(), versepropFee), "Fee transfer failed");

            uint256 loanAmount = debt.totalInvestment - versepropFee;
            require(usdcToken.transfer(debt.walletAddress, loanAmount), "Loan transfer failed");
        }

        // Update status and startDate (to be used for interest calculation)
        debt.startDate = block.timestamp;
        debt.status = DebtStatus.FUNDED;
        ds.setDebt(_debtId, debt);
        emit LoanDisbursed(_debtId, debt.totalInvestment - versepropFee);
    }

//    /**
//     * @dev Returns deposits to investors if a loan is not disbursed.
//     * @param _debtId The ID of the debt.
//     */
//    function returnDeposit(uint256 _debtId) external onlyOwner nonReentrant {
//        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
//        require(debt.status == DebtStatus.OPEN, "Funds can only be returned if they have not been sent");
//
//        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
//        uint256 nextTokenId = nftContract.nextTokenId();
//
//        for (uint256 tokenId = 0; tokenId < nextTokenId; tokenId++) {
//            // Checks if the token hasn't been burned
//            if (nftContract.ownerOf(tokenId) != address(0)) {
//                uint256 investmentAmount = ds.investments(_debtId, tokenId);
//                if (investmentAmount > 0) {
//                    address owner = nftContract.ownerOf(tokenId);
//                    // Refund logic
//                    if (debt.currency == Currency.ETH) {
//                        payable(owner).transfer(investmentAmount);
//                    } else if (debt.currency == Currency.USDC) {
//                        IERC20 usdcToken = IERC20(usdcTokenAddress);
//                        require(usdcToken.transfer(owner, investmentAmount), "Transfer failed");
//                    }
//                    nftContract.burn(tokenId); // Burn the NFT
//                    emit DepositReturned(_debtId, owner, investmentAmount);
//                }
//            }
//        }
//
//        // Update debt status
//        debt.status = DebtStatus.UNFUNDED;
//        ds.setDebt(_debtId, debt);
//    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
