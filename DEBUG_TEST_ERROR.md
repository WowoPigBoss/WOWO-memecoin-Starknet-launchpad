]633;E;echo "# WOWO test diagnostics";54ba959c-5ac2-4912-8632-366befec0ca3]633;C# WOWO test diagnostics

- Branch: feature/ekubo-migration
- snforge test exit code: 2

## Error details
541- --> /workspaces/WOWO-memecoin-Starknet-launchpad/tests/wowo_liquidity_lock_test.cairo:361:34
542-    use super::{ContractAddress, IReentrantNFT, IWowoLiquidityLockDispatcher, IWowoLiquidityLockDispatcherTrait};
543-                                 ^^^^^^^^^^^^^
544-
545:[ERROR] Failed to build test artifacts with Scarb: `scarb` exited with error

## Last 60 log lines
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/merkle_tree/Scarb.toml:12:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/utils/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/presets/Scarb.toml:13:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/testing/Scarb.toml:13:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/security/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/test_common/Scarb.toml:7:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/token/Scarb.toml:15:1)
warn: unknown manifest field `workspace.package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/Scarb.toml:31:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/upgrades/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/utils/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/testing/Scarb.toml:13:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/access/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/test_common/Scarb.toml:7:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/account/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/finance/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/interfaces/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/governance/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/introspection/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/macros/Scarb.toml:12:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/merkle_tree/Scarb.toml:12:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/presets/Scarb.toml:13:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/security/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/token/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/upgrades/Scarb.toml:14:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/utils/Scarb.toml:15:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/testing/Scarb.toml:13:1)
warn: unknown manifest field `package.scarb-version` (/home/codespace/.cache/scarb/registry/git/checkouts/cairo-contracts-9cboa8jg3jldq/87e32f3d/packages/test_common/Scarb.toml:7:1)
   Compiling test(wowo_launchpad_unittest) wowo_launchpad v0.1.0 (/workspaces/WOWO-memecoin-Starknet-launchpad/Scarb.toml)
warn[E2100]: Unused import: `wowo_launchpad::wowo_ekubo_migration::ContractAddress`
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/src/wowo_ekubo_migration.cairo:1:15
use starknet::ContractAddress;
              ^^^^^^^^^^^^^^^

warn[E2100]: Unused import: `wowo_launchpad::wowo_bonding_curve::ContractAddress`
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/src/wowo_bonding_curve.cairo:1:15
use starknet::ContractAddress;
              ^^^^^^^^^^^^^^^

warn[E2100]: Unused import: `wowo_launchpad::wowo_launchpad::WowoLaunchpad::IERC20DispatcherTrait`
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/src/wowo_launchpad.cairo:3:61
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
                                                            ^^^^^^^^^^^^^^^^^^^^^

warn[E2100]: Unused import: `wowo_launchpad::wowo_bonding_curve_market::WowoBondingCurveMarket::IERC20DispatcherTrait`
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/src/wowo_bonding_curve_market.cairo:40:19
IERC20Dispatcher, IERC20DispatcherTrait
                  ^^^^^^^^^^^^^^^^^^^^^

   Compiling test(wowo_launchpad_integrationtest) wowo_launchpad_integrationtest v0.1.0 (/workspaces/WOWO-memecoin-Starknet-launchpad/Scarb.toml)
warn[E2066]: Usage of deprecated feature `"deprecated-starknet-consts"` with no `#[feature("deprecated-starknet-consts")]` attribute. Note: "Use `TryInto::try_into` in const context instead."
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/tests/wowo_bonding_curve_test.cairo:2:33
use starknet::{ContractAddress, contract_address_const};
                                ^^^^^^^^^^^^^^^^^^^^^^

warn[E2100]: Unused import: `wowo_launchpad_integrationtest::wowo_liquidity_lock_test::ReentrantNFT::IReentrantNFT`
 --> /workspaces/WOWO-memecoin-Starknet-launchpad/tests/wowo_liquidity_lock_test.cairo:361:34
    use super::{ContractAddress, IReentrantNFT, IWowoLiquidityLockDispatcher, IWowoLiquidityLockDispatcherTrait};
                                 ^^^^^^^^^^^^^

[ERROR] Failed to build test artifacts with Scarb: `scarb` exited with error
