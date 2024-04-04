// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/AccessControl.sol";

/**
 * @title DebtAccessControl
 * @dev This contract implements role-based access control mechanisms specific to managing debt-related operations. It's built on top of OpenZeppelin's AccessControl for robust, secure management of roles and permissions.
 */
contract DebtAccessControl is AccessControl {
    // Define a role identifier for the manager role.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * @dev Constructor that sets the deploying address as the default administrator.
     * @param admin Address to be granted the default admin role, capable of managing other roles.
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Modifier to restrict access to only users who have been granted the admin role.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    /**
     * @dev Modifier to restrict access to only users who have been granted the manager role.
     */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        _;
    }

    /**
     * @dev Public function to grant the manager role to a specified address. Can only be called by an admin.
     * @param manager Address to be granted the manager role.
     */
    function addManager(address manager) public onlyAdmin {
        grantRole(MANAGER_ROLE, manager);
    }

    /**
     * @dev Public function to revoke the manager role from a specified address. Can only be called by an admin.
     * @param manager Address from which the manager role will be revoked.
     */
    function removeManager(address manager) public onlyAdmin {
        revokeRole(MANAGER_ROLE, manager);
    }

    /**
     * @dev Public function to grant the admin role to a new address. Can only be called by an existing admin.
     * @param newAdmin Address to be granted the admin role.
     */
    function addAdmin(address newAdmin) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev Public function to revoke the admin role from a specified address. Can only be called by an existing admin.
     * @param adminToRemove Address from which the admin role will be revoked.
     */
    function removeAdmin(address adminToRemove) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, adminToRemove);
    }
}
