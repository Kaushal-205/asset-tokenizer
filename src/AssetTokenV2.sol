// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {AssetToken} from "./AssetToken.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";

/**
 * @title AssetTokenV2
 * @notice Upgraded version of AssetToken with pause functionality.
 * @dev Adds pause/unpause capabilities to halt transfers in emergencies.
 */
contract AssetTokenV2 is AssetToken, PausableUpgradeable {
    /**
     * @notice Reinitializes the contract for V2.
     * @dev Called after upgrading from V1 to initialize V2-specific state.
     */
    function initializeV2() external reinitializer(2) {
        __Pausable_init();
    }

    /**
     * @notice Pauses all token transfers.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses token transfers.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Hook that is called before any token transfer.
     * @dev Overrides ERC20Upgradeable._update to add pause check.
     * @param from The sender address.
     * @param to The recipient address.
     * @param value The amount being transferred.
     */
    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
