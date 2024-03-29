// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./DebtNFT.sol";

contract SmartContractLoan is Ownable, ReentrancyGuard {
    struct Debt {
        uint256 amount;
        uint256 interestRate;
        uint256 term;
        address payable walletAddress;
        uint256 investmentAmount;
        uint256 totalInvestment;
        bool disbursed;
        uint256 startDate;
        address[] investors;
        uint256 investorCount;
        address nftContractAddress;
    }

    constructor() Ownable(msg.sender) {}

    mapping(uint256 => Debt) public debts;
    mapping(uint256 => mapping(address => uint256)) public investments;
    mapping(uint256 => uint256) public debtTokenIdCounter;
    uint256 public debtCount;

    event DebtCreated(uint256 indexed debtId, uint256 amount, uint256 interestRate, uint256 term);
    event DepositAdded(uint256 indexed debtId, address indexed investor, uint256 amount);
    event LoanDisbursed(uint256 indexed debtId, uint256 amount);
    event DepositReturned(uint256 indexed debtId, address indexed investor, uint256 amount);
    event DebtPaidOff(uint256 indexed debtId, uint256 amount);
    event DepositWithdrawn(uint256 indexed debtId, address indexed investor, uint256 amount);

    function createDebt(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _term,
        address payable _walletAddress,
        uint256 _investmentAmount
    ) external onlyOwner {
        debtCount++;
        DebtNFT nftContract = new DebtNFT("Debt NFT", "DEBT", address(this));
        debts[debtCount] = Debt({
            amount: _amount,
            interestRate: _interestRate,
            term: _term,
            walletAddress: _walletAddress,
            investmentAmount: _investmentAmount,
            totalInvestment: 0,
            disbursed: false,
            startDate: 0,
            investors: new address[](0),
            investorCount: 0,
            nftContractAddress : address(nftContract)
        });
        emit DebtCreated(debtCount, _amount, _interestRate, _term);
    }

    function addDeposit(uint256 _debtId) external payable nonReentrant {
        Debt storage debt = debts[_debtId];
        require(!debt.disbursed, "Loan already disbursed");
        require(debt.totalInvestment + msg.value <= debt.amount, "Investment limit exceeded");

        if (investments[_debtId][msg.sender] == 0) {
            debt.investors.push(msg.sender);
            debt.investorCount++;
        }

        debt.totalInvestment = debt.totalInvestment + msg.value;
        investments[_debtId][msg.sender] = investments[_debtId][msg.sender] + msg.value;

        uint256 tokenId = debtTokenIdCounter[_debtId] + 1;
        debtTokenIdCounter[_debtId] = tokenId;

        DebtNFT nftContract = DebtNFT(debts[_debtId].nftContractAddress);
        nftContract.mint(msg.sender, tokenId);

        emit DepositAdded(_debtId, msg.sender, msg.value);
    }

    function disburseLoan(uint256 _debtId) external onlyOwner nonReentrant {
        Debt storage debt = debts[_debtId];
        require(!debt.disbursed, "Loan already disbursed");
        require(debt.totalInvestment == debt.amount, "Investment goal not reached");

        uint256 verseProFee = debt.totalInvestment * 2 / 100; // 2% fee
        uint256 loanAmount = debt.totalInvestment - verseProFee;

        debt.walletAddress.transfer(loanAmount);
        debt.disbursed = true;
        debt.startDate = block.timestamp;

        emit LoanDisbursed(_debtId, loanAmount);
    }

    function returnDeposit(uint256 _debtId) external onlyOwner nonReentrant {
        Debt storage debt = debts[_debtId];
        require(!debt.disbursed, "Loan already disbursed");

        for (uint256 i = 0; i < debt.investorCount; i++) {
            address investor = debt.investors[i];
            uint256 depositAmount = investments[_debtId][investor];
            if (depositAmount > 0) {
                investments[_debtId][investor] = 0;
                payable(investor).transfer(depositAmount);
                emit DepositReturned(_debtId, investor, depositAmount);
            }
        }
    }

    function withdrawDeposit(uint256 _debtId, uint256 _tokenId) external nonReentrant {
        Debt storage debt = debts[_debtId];
        require(debt.disbursed == false, "Loan is already disbursed");
        DebtNFT nftContract = DebtNFT(debt.nftContractAddress);

        require(nftContract.ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the NFT");

        uint256 depositAmount = debt.investmentAmount;
        require(depositAmount > 0, "No deposit found");

        uint256 interest = calculateInterest(_debtId);
        uint256 totalWithdrawal = depositAmount + interest;

        debt.totalInvestment -= depositAmount;

        nftContract.burn(_tokenId);

        require(address(this).balance >= totalWithdrawal, "Insufficient contract balance");


        (bool success, ) = payable(msg.sender).call{value: totalWithdrawal}("");
        require(success, "Transfer failed");

        emit DepositWithdrawn(_debtId, msg.sender, totalWithdrawal);
    }

    function payOffDebt(uint256 _debtId) external payable nonReentrant {
        Debt storage debt = debts[_debtId];
        require(debt.disbursed, "Loan not disbursed");

        uint256 interest = calculateInterest(_debtId);
        uint256 totalPayment = debt.amount + interest;
        require(msg.value >= totalPayment, "Insufficient payment");

        debt.walletAddress.transfer(totalPayment);
        debt.disbursed = false;

        emit DebtPaidOff(_debtId, totalPayment);
    }

    function calculateInterest(uint256 _debtId) public view returns (uint256) {
        Debt storage debt = debts[_debtId];
        uint256 timePassed = block.timestamp - debt.startDate;
        uint256 dailyInterest = debt.interestRate / 10000;
        uint256 interestAccrued = debt.amount * dailyInterest * timePassed / (1 days);
        return interestAccrued;
    }
}