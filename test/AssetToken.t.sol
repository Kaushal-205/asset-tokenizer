// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetTokenV2} from "../src/AssetTokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title AssetTokenTest
 * @notice Solidity test suite for the AssetToken upgrade lifecycle.
 */
contract AssetTokenTest is Test {
    AssetToken public implementation;
    AssetToken public token; // Proxy cast to V1 interface
    AssetTokenV2 public tokenV2; // Proxy cast to V2 interface
    ERC1967Proxy public proxy;

    address public admin = address(this);
    address public minter = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address public user = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

    uint256 public constant MAX_SUPPLY = 1_000_000 * 1e18; // 1M tokens

    function setUp() public {
        // 1. Deploy V1 implementation
        implementation = new AssetToken();

        // 2. Encode initialize call
        bytes memory initData =
            abi.encodeCall(AssetToken.initialize, ("Xaults Asset 1", "XLTA1", MAX_SUPPLY, admin, admin));

        // 3. Deploy ERC1967Proxy pointing to V1 with init calldata
        proxy = new ERC1967Proxy(address(implementation), initData);

        // 4. Cast proxy to V1 interface
        token = AssetToken(address(proxy));
    }

    /// @notice Test: Deploy and initialize V1 correctly
    function test_DeployAndInitialize() public view {
        assertEq(token.name(), "Xaults Asset 1");
        assertEq(token.symbol(), "XLTA1");
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
    }

    /// @notice Test: Mint 100 tokens to user and verify balance
    function test_Minting() public {
        uint256 mintAmount = 100 * 1e18;
        token.mint(user, mintAmount);
        assertEq(token.balanceOf(user), mintAmount);
    }

    /// @notice Test: Minting beyond maxSupply reverts with MaxSupplyExceeded
    function test_MintingCapEnforced() public {
        // Mint up to max supply
        token.mint(user, MAX_SUPPLY);
        assertEq(token.totalSupply(), MAX_SUPPLY);

        // Attempt to mint 1 more token should revert
        vm.expectRevert(AssetToken.MaxSupplyExceeded.selector);
        token.mint(user, 1);
    }

    /// @notice Test: Non-minter cannot mint
    function test_AccessControl_NonMinterCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100);
    }

    /// @notice Test: Non-admin cannot upgrade
    function test_AccessControl_NonAdminCannotUpgrade() public {
        AssetTokenV2 v2Impl = new AssetTokenV2();

        vm.prank(user);
        vm.expectRevert();
        token.upgradeToAndCall(address(v2Impl), "");
    }

    /// @notice Test: Upgrade from V1 to V2 and verify state persistence
    function test_UpgradeToV2_StatePersistence() public {
        // Mint 100 tokens before upgrade
        uint256 mintAmount = 100 * 1e18;
        token.mint(user, mintAmount);
        assertEq(token.balanceOf(user), mintAmount);

        // Deploy V2 implementation
        AssetTokenV2 v2Impl = new AssetTokenV2();

        // Upgrade proxy to V2 and call initializeV2
        bytes memory reinitData = abi.encodeCall(AssetTokenV2.initializeV2, ());
        token.upgradeToAndCall(address(v2Impl), reinitData);

        // Cast proxy to V2 interface
        tokenV2 = AssetTokenV2(address(proxy));

        // Verify state persistence: balance should still be 100 tokens
        assertEq(tokenV2.balanceOf(user), mintAmount);
        assertEq(tokenV2.maxSupply(), MAX_SUPPLY);
        assertEq(tokenV2.name(), "Xaults Asset 1");
    }

    /// @notice Test: V2 pause functionality halts transfers
    function test_V2_PauseFunctionality() public {
        // Mint tokens
        uint256 mintAmount = 100 * 1e18;
        token.mint(user, mintAmount);

        // Upgrade to V2
        AssetTokenV2 v2Impl = new AssetTokenV2();
        bytes memory reinitData = abi.encodeCall(AssetTokenV2.initializeV2, ());
        token.upgradeToAndCall(address(v2Impl), reinitData);
        tokenV2 = AssetTokenV2(address(proxy));

        // Pause the contract
        tokenV2.pause();
        assertTrue(tokenV2.paused());

        // Transfer should revert when paused
        vm.prank(user);
        vm.expectRevert();
        tokenV2.transfer(admin, 10 * 1e18);

        // Unpause and verify transfer works
        tokenV2.unpause();
        assertFalse(tokenV2.paused());

        vm.prank(user);
        tokenV2.transfer(admin, 10 * 1e18);
        assertEq(tokenV2.balanceOf(admin), 10 * 1e18);
    }

    /// @notice Test: V2 minting also respects pause
    function test_V2_PausedMintingReverts() public {
        // Upgrade to V2
        AssetTokenV2 v2Impl = new AssetTokenV2();
        bytes memory reinitData = abi.encodeCall(AssetTokenV2.initializeV2, ());
        token.upgradeToAndCall(address(v2Impl), reinitData);
        tokenV2 = AssetTokenV2(address(proxy));

        // Pause the contract
        tokenV2.pause();

        // Minting should revert when paused
        vm.expectRevert();
        tokenV2.mint(user, 100);
    }
}
