// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";

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

contract DebtStorage is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    mapping(uint256 => Debt) public debts;
    mapping(uint256 => mapping(uint256 => uint256)) public investments;
    uint256 public debtCount;
    address payable public feeWallet;
    address public usdcTokenAddress;

    constructor(
        address _admin,
        address payable _feeWallet,
        address _usdcTokenAddress
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        feeWallet = _feeWallet;
        usdcTokenAddress = _usdcTokenAddress;
    }

    // Modifier to restrict access to admin-only functions
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        _;
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

    function addDebt(Debt memory _debt) public onlyManager {
        debts[debtCount] = _debt;
        debtCount += 1;
    }

    function updateDebt(uint256 _id, Debt memory _debt) public onlyManager {
        require(
            debts[_id].maxAmount != 0,
            "Debt with the provided id does not exist"
        );
        debts[_id] = _debt;
    }

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

    function getDebt(uint256 _id) public view returns (Debt memory) {
        return debts[_id];
    }

    /**
     * @dev Sets the fee wallet address.
     * @param _feeWallet The new fee wallet address.
     * @notice Only the contract owner can call this function.
     */
    function setFeeWallet(address payable _feeWallet) external onlyAdmin {
        feeWallet = _feeWallet;
    }

    function addManager(address _manager) public onlyAdmin {
        grantRole(MANAGER_ROLE, _manager);
    }

    function removeManager(address _manager) public onlyAdmin {
        revokeRole(MANAGER_ROLE, _manager);
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, _adminToRemove);
    }
}
