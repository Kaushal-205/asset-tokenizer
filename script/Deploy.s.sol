// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script, console} from "forge-std/Script.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetTokenV2} from "../src/AssetTokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAssetToken
 * @notice Deployment script for AssetToken V1 via ERC1967Proxy.
 * @dev Run with: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
 */
contract DeployAssetToken is Script {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 1e18; // 1M tokens

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);

        

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy V1 implementation
        AssetToken implementation = new AssetToken();
        console.log("V1 Implementation deployed at:", address(implementation));

        // 2. Encode initialize calldata
        bytes memory initData = abi.encodeCall(
            AssetToken.initialize,
            ("Xaults Asset 1", "XLTA1", MAX_SUPPLY, deployer, deployer)
        );

        // 3. Deploy ERC1967Proxy pointing to V1
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));

        // 4. Verify initialization
        AssetToken token = AssetToken(address(proxy));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Max supply:", token.maxSupply());

        vm.stopBroadcast();
    }
}

/**
 * @title UpgradeToV2
 * @notice Upgrade script to migrate from V1 to V2.
 * @dev Run with: forge script script/Deploy.s.sol:UpgradeToV2 --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
 */
contract UpgradeToV2 is Script {
    function run() external {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log("Upgrading proxy at:", proxyAddress);

        vm.startBroadcast();

        // 1. Deploy V2 implementation
        AssetTokenV2 v2Implementation = new AssetTokenV2();
        console.log(
            "V2 Implementation deployed at:",
            address(v2Implementation)
        );

        // 2. Encode reinitializer calldata
        bytes memory reinitData = abi.encodeCall(AssetTokenV2.initializeV2, ());

        // 3. Upgrade proxy to V2
        AssetToken proxy = AssetToken(proxyAddress);
        proxy.upgradeToAndCall(address(v2Implementation), reinitData);
        console.log("Upgrade complete!");

        // 4. Verify V2 functionality
        AssetTokenV2 tokenV2 = AssetTokenV2(proxyAddress);
        console.log("Paused:", tokenV2.paused());

        vm.stopBroadcast();
    }
}
