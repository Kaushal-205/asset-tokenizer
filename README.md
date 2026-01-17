# Upgradeable Asset Tokenizer

A UUPS-upgradeable ERC20 token representing a tokenized financial asset, built with Foundry and OpenZeppelin.

## Features

- **V1 (`AssetToken`)**: ERC20 with role-based access control and capped minting
- **V2 (`AssetTokenV2`)**: Adds pause/unpause functionality for emergency stops

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity 0.8.33+

## Setup

```bash
# Clone and install dependencies
git clone <repo-url>
cd asset-tokenizer
forge install
```

## Build

```bash
forge build
```

## Test

```bash
forge test -vvv
```

## Deploy

### Local (Anvil)

```bash
# Terminal 1: Start local node
anvil

# Terminal 2: Deploy
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### Testnet/Mainnet

```bash
export PRIVATE_KEY=<your-private-key>
forge script script/Deploy.s.sol --rpc-url <rpc-url> --broadcast --verify
```

## Upgrade to V2

```bash
export PRIVATE_KEY=<your-private-key>
export PROXY_ADDRESS=<deployed-proxy-address>
forge script script/Deploy.s.sol:UpgradeToV2 --rpc-url <rpc-url> --broadcast
```

## CLI Interaction (Cast)

Using Anvil default addresses:
- **Account 0 (Admin/Minter)**: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- **Account 1 (Minter)**: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`  
- **Account 2 (User)**: `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`

```bash
# Set environment variables (Anvil Account 0)
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export PROXY_ADDRESS=<deployed-proxy-address>  # From deployment output

# Mint 100 tokens to Account 2 (requires MINTER_ROLE)
cast send $PROXY_ADDRESS "mint(address,uint256)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 100000000000000000000 --private-key $PRIVATE_KEY --rpc-url http://127.0.0.1:8545

# Check balance of Account 2
cast call $PROXY_ADDRESS "balanceOf(address)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC --rpc-url http://127.0.0.1:8545

# Pause (V2 only, requires DEFAULT_ADMIN_ROLE)
cast send $PROXY_ADDRESS "pause()" --private-key $PRIVATE_KEY --rpc-url http://127.0.0.1:8545
```

## Storage Layout Verification

The upgrade from V1 to V2 is storage-safe because:

1. **Inheritance Order Preserved**: `AssetTokenV2` inherits from `AssetToken` first, then `PausableUpgradeable`. This appends V2 storage after V1 storage.

2. **Storage Gaps**: V1 contract already includes `__gap` array:
   - `AssetToken`: `uint256[50] private __gap;`

3. **Verification Command**:
   ```bash
   # Compare storage layouts
   forge inspect AssetToken storage-layout --pretty > v1_layout.txt
   forge inspect AssetTokenV2 storage-layout --pretty > v2_layout.txt
   diff v1_layout.txt v2_layout.txt
   ```

   V2 should only add new slots after V1's layout, with no reordering of existing slots.

4. **reinitializer(2)**: V2 uses `reinitializer(2)` instead of `initializer` to safely initialize V2-specific state without re-running V1 initialization.

## Project Structure

```
├── src/
│   ├── AssetToken.sol      # V1 implementation
│   └── AssetTokenV2.sol    # V2 with pause
├── test/
│   └── AssetToken.t.sol    # Solidity test suite
├── script/
│   └── Deploy.s.sol        # Deployment scripts
└── foundry.toml            # Foundry config
```

## License

MIT
