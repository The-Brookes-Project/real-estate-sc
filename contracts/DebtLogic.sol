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
contract DebtLogic is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    DebtStorage public ds;
    function initialize(address _storageAddress) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        ds = DebtStorage(_storageAddress);
    }
    event DepositAdded(
        uint256 indexed debtId,
        address indexed investor,
        uint256 amount
    );
    event DebtPaidOff(uint256 indexed debtId, uint256 amount);
    event DepositWithdrawn(
        uint256 indexed debtId,
        address indexed investor,
        uint256 amount
    );

    event DebtCreated(
        uint256 indexed debtId,
        uint256 amount,
        uint256 interestRate,
        uint256 term
    );
    event DepositReturned(
        uint256 indexed debtId,
        address indexed investor,
        uint256 amount
    );
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
        DebtNFT nftContract = new DebtNFT("Debt NFT", "DEBT", address(this));
        ds.addDebt(
            DebtStorage.Debt({
                maxAmount: _amt,
                interestRate: _interestRate,
                term: _term,
                walletAddress: _walletAddress,
                minInvestmentAmount: _minInvestmentAmount,
                totalInvestment: 0,
                status: DebtStatus.OPEN,
                startDate: 0,
                settledDate: 0,
                nftContractAddress: address(nftContract),
                tokenURI: _tokenURI,
                currency: _currency
            })
        );
        emit DebtCreated(ds.debtCount(), _amt, _interestRate, _term);
    }

    /**
     * @dev Disburses a loan once the investment goal has reached. Disables users from withdrawing from the pool.
     * @param _debtId The ID of the debt.
     */
    function disburseLoan(uint256 _debtId) external onlyOwner nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(
            debt.status == DebtStatus.OPEN,
            "Current loan status needs to be OPEN"
        );
        require(
            debt.totalInvestment == debt.maxAmount,
            "Investment goal not reached"
        );

        // Transfer the Verseprop fee 2% to feeWallet and the rest to the debtor
        uint256 versepropFee = (debt.totalInvestment * 2) / 100;
        if (debt.currency == Currency.ETH) {
            ds.feeWallet().transfer(versepropFee);
            uint256 loanAmount = debt.totalInvestment - versepropFee;
            debt.walletAddress.transfer(loanAmount);
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());

            // Transfer the fee to the fee wallet
            require(
                usdcToken.transfer(ds.feeWallet(), versepropFee),
                "Fee transfer failed"
            );

            uint256 loanAmount = debt.totalInvestment - versepropFee;
            require(
                usdcToken.transfer(debt.walletAddress, loanAmount),
                "Loan transfer failed"
            );
        }

        // Update status and startDate (to be used for interest calculation)
        debt.startDate = block.timestamp;
        debt.status = DebtStatus.FUNDED;
        ds.updateDebt(_debtId, debt);
        emit LoanDisbursed(_debtId, debt.totalInvestment - versepropFee);
    }

    /**
     * @dev Returns deposits to investors if a loan is not disbursed.
     * @param _debtId The ID of the debt.
     */
    function returnDeposit(uint256 _debtId) external onlyOwner nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(
            debt.status == DebtStatus.OPEN,
            "Funds can only be returned if they have not been sent"
        );

        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
        uint256 nextTokenId = nftContract.nextTokenId();

        for (uint256 tokenId = 0; tokenId < nextTokenId; tokenId++) {
            // Checks if the token hasn't been burned
            if (nftContract.ownerOf(tokenId) != address(0)) {
                uint256 investmentAmount = ds.investments(_debtId, tokenId);
                if (investmentAmount > 0) {
                    address owner = nftContract.ownerOf(tokenId);
                    // Refund logic
                    if (debt.currency == Currency.ETH) {
                        payable(owner).transfer(investmentAmount);
                    } else if (debt.currency == Currency.USDC) {
                        IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
                        require(
                            usdcToken.transfer(owner, investmentAmount),
                            "Transfer failed"
                        );
                    }
                    nftContract.burn(tokenId); // Burn the NFT
                    emit DepositReturned(_debtId, owner, investmentAmount);
                }
            }
        }

        // Update debt status
        debt.status = DebtStatus.UNFUNDED;
        ds.updateDebt(_debtId, debt);
    }

    /**
     * @dev Adds a deposit to a debt, which mints the NFT representing the investment.
     * @param _debtId The ID of the debt.
     */
    function addDeposit(
        uint256 _debtId,
        uint256 _amt
    ) external payable nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(
            debt.status == DebtStatus.OPEN,
            "Loan is not accepting funds from deposits"
        );
        require(
            debt.totalInvestment + _amt <= debt.maxAmount,
            "Investment limit exceeded"
        );

        // Ensure user provided sufficient amount in specified debt currency
        if (debt.currency == Currency.ETH) {
            require(msg.value == _amt, "Incorrect ETH amount");
            require(
                msg.value >= debt.minInvestmentAmount,
                "Minimum investment amount not sufficient"
            );
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
            require(
                usdcToken.allowance(msg.sender, address(this)) >=
                    debt.minInvestmentAmount,
                "Minimum investment amount not sufficient"
            );
            require(
                usdcToken.transferFrom(msg.sender, address(this), _amt),
                "USDC transfer failed"
            );
        }
        // Mint NFT which is associated with the investment amount
        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
        uint256 tokenId = nftContract.mint(msg.sender, debt.tokenURI);
        ds.setInvestment(_debtId, tokenId, _amt);

        // Update total investment amount on the debt
        debt.totalInvestment = debt.totalInvestment + _amt;
        ds.updateDebt(_debtId, debt);
        emit DepositAdded(_debtId, msg.sender, _amt);
    }

    /**
     * @dev Withdraws a deposit and interest for an investor.
     * @param _debtId The ID of the debt.
     * @param _tokenId The ID of the NFT token.
     */
    function withdrawDeposit(
        uint256 _debtId,
        uint256 _tokenId
    ) external nonReentrant {
        DebtStorage.Debt memory debt = ds.getDebt(_debtId);
        require(
            debt.status == DebtStatus.OPEN || debt.status == DebtStatus.SETTLED,
            "Invalid loan status"
        );
        require(debt.totalInvestment > 0, "No funds left to settle");
        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "Caller is not the owner of the NFT"
        );
        uint256 investmentAmount = ds.investments(_debtId, _tokenId);
        require(investmentAmount > 0, "No deposit found");

        // Calculate interest for the amount associated with the NFT
        uint256 interest = calculateInterest(_debtId, investmentAmount);
        uint256 totalWithdrawal = investmentAmount + interest;

        nftContract.burn(_tokenId);

        if (debt.currency == Currency.ETH) {
            require(
                address(this).balance >= totalWithdrawal,
                "Insufficient contract balance"
            );
            (bool success, ) = payable(msg.sender).call{value: totalWithdrawal}(
                ""
            );
            require(success, "Transfer failed");
        } else if (debt.currency == Currency.USDC) {
            IERC20 usdcToken = IERC20(ds.usdcTokenAddress());
            require(
                usdcToken.balanceOf(address(this)) >= totalWithdrawal,
                "Insufficient contract balance"
            );
            require(
                usdcToken.transfer(msg.sender, totalWithdrawal),
                "Transfer failed"
            );
        }

        debt.totalInvestment -= investmentAmount;
        ds.updateDebt(_debtId, debt);
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
            require(
                usdcToken.allowance(msg.sender, address(this)) >= totalPayment,
                "Insufficient allowance"
            );
            require(
                usdcToken.transferFrom(
                    msg.sender,
                    debt.walletAddress,
                    totalPayment
                ),
                "Transfer failed"
            );
        }

        debt.status = DebtStatus.SETTLED;
        debt.settledDate = block.timestamp;
        ds.updateDebt(_debtId, debt);
        emit DebtPaidOff(_debtId, totalPayment);
    }

    /**
     * @dev Calculates the interest for a debt.
     * @param _debtId The ID of the debt.
     * @param _amount The amount to calculate the interest on
     * @return The calculated interest.
     */
    function calculateInterest(
        uint256 _debtId,
        uint256 _amount
    ) public view returns (uint256) {
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
        uint256 interestAccrued = (_amount * dailyInterest * timePassed) /
            (1 days);
        return interestAccrued;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
