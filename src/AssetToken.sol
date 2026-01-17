// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @title AssetToken
 * @notice UUPS-upgradeable ERC20 token representing a tokenized financial asset.
 * @dev V1 implementation with role-based access control and capped minting.
 */
contract AssetToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply;

    error MaxSupplyExceeded();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, uint256 maxSupply_, address admin, address minter)
        external
        initializer
    {
        __ERC20_init(name_, symbol_);
        __AccessControl_init();

        maxSupply = maxSupply_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, amount);
    }

    /**
     * @notice Authorizes an upgrade to a new implementation.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev Reserved storage gap for future upgrades.
     */
    uint256[50] private __gap;
}
