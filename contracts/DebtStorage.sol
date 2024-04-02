// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

enum Currency { ETH, USDC }
enum DebtStatus { OPEN, FUNDED, SETTLED, UNFUNDED }

contract DebtStorage is Ownable {
    mapping(uint256 => Debt) public debts;
    mapping(uint256 => mapping(uint256 => uint256)) public investments;
    uint256 public debtCount;
    address payable public feeWallet;
    address public usdcTokenAddress;

    constructor(address initialOwner, address payable _feeWallet, address _usdcTokenAddress) Ownable(initialOwner) {
        feeWallet = _feeWallet;
        usdcTokenAddress = _usdcTokenAddress;
    }

    /**
     * @dev Struct representing a debt.
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

    function setDebt(uint256 _id, Debt memory _debt) public onlyOwner {
        debts[_id] = _debt;
    }

    function setInvestment(uint256 _debtId, uint256 _tokenId, uint256 _amount) public onlyOwner {
        investments[_debtId][_tokenId] = _amount;
    }

    function incrementDebtCount() public onlyOwner {
        debtCount += 1;
    }

    function getDebt(uint256 _id) public view returns (Debt memory) {
        return debts[_id];
    }

    /**
     * @dev Sets the fee wallet address.
     * @param _feeWallet The new fee wallet address.
     * @notice Only the contract owner can call this function.
     */
    function setFeeWallet(address payable _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }
}