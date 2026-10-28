use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoBondingCurveMarket<TContractState> {
fn get_fee(self: @TContractState, amount: u256) -> u256;
fn get_reserves(
self: @TContractState,
token: ContractAddress,
) -> (u256, u256);
fn can_migrate(self: @TContractState, token: ContractAddress) -> bool;
fn begin_migration(ref self: TContractState, token: ContractAddress);
fn create_market(
ref self: TContractState,
token: ContractAddress,
token_seed: u256,
strk_seed: u256,
);
fn buy(
ref self: TContractState,
token: ContractAddress,
strk_amount: u256,
min_tokens_out: u256,
) -> u256;
fn sell(
ref self: TContractState,
token: ContractAddress,
token_amount: u256,
min_strk_out: u256,
) -> u256;
fn set_fee_bps(ref self: TContractState, new_fee_bps: u16);
fn pause_market(ref self: TContractState, token: ContractAddress);
fn is_paused(self: @TContractState, token: ContractAddress) -> bool;
fn is_migrated(self: @TContractState, token: ContractAddress) -> bool;
}

#[starknet::contract]
pub mod WowoBondingCurveMarket {
use super::IWowoBondingCurveMarket;
use openzeppelin::interfaces::erc20::{
IERC20Dispatcher, IERC20DispatcherTrait
};
use openzeppelin::token::erc20::SafeERC20DispatcherTrait;
use starknet::{
ContractAddress, get_caller_address, get_contract_address
};
use starknet::storage::{
Map, StoragePathEntry,
StoragePointerReadAccess, StoragePointerWriteAccess
};

#[storage]
struct Storage {
    admin: ContractAddress,
    treasury: ContractAddress,
    strk_token: ContractAddress,
    fee_bps: u16,
    initialized: Map<ContractAddress, bool>,
    token_reserve: Map<ContractAddress, u256>,
    strk_reserve: Map<ContractAddress, u256>,
    paused: Map<ContractAddress, bool>,
    migrated: Map<ContractAddress, bool>,
}

#[constructor]
fn constructor(
    ref self: ContractState,
    admin: ContractAddress,
    treasury: ContractAddress,
    strk_token: ContractAddress,
) {
    self.admin.write(admin);
    self.treasury.write(treasury);
    self.strk_token.write(strk_token);
    self.fee_bps.write(100);
}

#[abi(embed_v0)]
impl MarketImpl of IWowoBondingCurveMarket<ContractState> {
    fn get_fee(self: @ContractState, amount: u256) -> u256 {
        assert(amount > 0, 'INVALID_AMOUNT');
        (amount * self.fee_bps.read().into()) / 10_000_u256
    }

    fn get_reserves(
        self: @ContractState,
        token: ContractAddress,
    ) -> (u256, u256) {
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        (
            self.token_reserve.entry(token).read(),
            self.strk_reserve.entry(token).read()
        )
    }

    fn can_migrate(
        self: @ContractState,
        token: ContractAddress,
    ) -> bool {
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        self.strk_reserve.entry(token).read()
            >= 15_000_000_000_000_000_000_000_u256
    }

    fn begin_migration(
        ref self: ContractState,
        token: ContractAddress,
    ) {
        assert(get_caller_address() == self.admin.read(), 'NOT_ADMIN');
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        assert(!self.migrated.entry(token).read(), 'ALREADY_MIGRATED');
        assert(!self.paused.entry(token).read(), 'ALREADY_PAUSED');
        assert(
            self.strk_reserve.entry(token).read()
                >= 15_000_000_000_000_000_000_000_u256,
            'MIGRATION_THRESHOLD_NOT_MET'
        );
        self.paused.entry(token).write(true);
    }

    fn create_market(
        ref self: ContractState,
        token: ContractAddress,
        token_seed: u256,
        strk_seed: u256,
    ) {
        let caller = get_caller_address();
        assert(caller == self.admin.read(), 'NOT_ADMIN');
        assert(token != self.strk_token.read(), 'INVALID_TOKEN');
        assert(!self.initialized.entry(token).read(), 'MARKET_EXISTS');
        assert(token_seed > 0, 'INVALID_TOKEN_SEED');
        assert(strk_seed > 0, 'INVALID_STRK_SEED');

        let token_contract = IERC20Dispatcher {
            contract_address: token
        };
        let strk_contract = IERC20Dispatcher {
            contract_address: self.strk_token.read()
        };

        token_contract.assert_transfer_from(
            caller, get_contract_address(), token_seed
        );
        strk_contract.assert_transfer_from(
            caller, get_contract_address(), strk_seed
        );

        self.token_reserve.entry(token).write(token_seed);
        self.strk_reserve.entry(token).write(strk_seed);
        self.initialized.entry(token).write(true);
        self.paused.entry(token).write(false);
        self.migrated.entry(token).write(false);
    }

    fn buy(
        ref self: ContractState,
        token: ContractAddress,
        strk_amount: u256,
        min_tokens_out: u256,
    ) -> u256 {
        let caller = get_caller_address();
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        assert(!self.paused.entry(token).read(), 'MARKET_PAUSED');
        assert(!self.migrated.entry(token).read(), 'ALREADY_MIGRATED');
        assert(strk_amount > 0, 'INVALID_AMOUNT');

        let token_reserve = self.token_reserve.entry(token).read();
        let strk_reserve = self.strk_reserve.entry(token).read();
        let fee = self.get_fee(strk_amount);
        let net_input = strk_amount - fee;

        assert(net_input > 0, 'AMOUNT_TOO_SMALL');

        let tokens_out =
            (token_reserve * net_input) / (strk_reserve + net_input);

        assert(tokens_out > 0, 'OUTPUT_TOO_SMALL');
        assert(tokens_out >= min_tokens_out, 'SLIPPAGE');
        assert(tokens_out < token_reserve, 'INSUFFICIENT_LIQUIDITY');

        let strk_contract = IERC20Dispatcher {
            contract_address: self.strk_token.read()
        };
        let token_contract = IERC20Dispatcher {
            contract_address: token
        };

        strk_contract.assert_transfer_from(
            caller, get_contract_address(), strk_amount
        );

        if fee > 0 {
            strk_contract.assert_transfer(
                self.treasury.read(), fee
            );
        }

        token_contract.assert_transfer(caller, tokens_out);

        self.token_reserve.entry(token).write(
            token_reserve - tokens_out
        );
        self.strk_reserve.entry(token).write(
            strk_reserve + net_input
        );

        tokens_out
    }

    fn sell(
        ref self: ContractState,
        token: ContractAddress,
        token_amount: u256,
        min_strk_out: u256,
    ) -> u256 {
        let caller = get_caller_address();
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        assert(!self.paused.entry(token).read(), 'MARKET_PAUSED');
        assert(!self.migrated.entry(token).read(), 'ALREADY_MIGRATED');
        assert(token_amount > 0, 'INVALID_AMOUNT');

        let token_reserve = self.token_reserve.entry(token).read();
        let strk_reserve = self.strk_reserve.entry(token).read();

        let gross_output =
            (strk_reserve * token_amount)
                / (token_reserve + token_amount);

        assert(gross_output > 0, 'OUTPUT_TOO_SMALL');

        let fee = self.get_fee(gross_output);
        let net_output = gross_output - fee;

        assert(net_output >= min_strk_out, 'SLIPPAGE');
        assert(gross_output <= strk_reserve, 'INSUFFICIENT_STRK');

        let token_contract = IERC20Dispatcher {
            contract_address: token
        };
        let strk_contract = IERC20Dispatcher {
            contract_address: self.strk_token.read()
        };

        token_contract.assert_transfer_from(
            caller, get_contract_address(), token_amount
        );

        strk_contract.assert_transfer(caller, net_output);

        if fee > 0 {
            strk_contract.assert_transfer(
                self.treasury.read(), fee
            );
        }

        self.token_reserve.entry(token).write(
            token_reserve + token_amount
        );
        self.strk_reserve.entry(token).write(
            strk_reserve - gross_output
        );

        net_output
    }

    fn set_fee_bps(
        ref self: ContractState,
        new_fee_bps: u16,
    ) {
        assert(
            get_caller_address() == self.admin.read(),
            'NOT_ADMIN'
        );
        assert(new_fee_bps <= 1000, 'FEE_TOO_HIGH');
        self.fee_bps.write(new_fee_bps);
    }

    fn pause_market(
        ref self: ContractState,
        token: ContractAddress,
    ) {
        assert(get_caller_address() == self.admin.read(), 'NOT_ADMIN');
        assert(self.initialized.entry(token).read(), 'NO_MARKET');
        assert(!self.migrated.entry(token).read(), 'ALREADY_MIGRATED');
        assert(!self.paused.entry(token).read(), 'ALREADY_PAUSED');
        self.paused.entry(token).write(true);
    }

    fn is_paused(
        self: @ContractState,
        token: ContractAddress,
    ) -> bool {
        self.paused.entry(token).read()
    }

    fn is_migrated(
        self: @ContractState,
        token: ContractAddress,
    ) -> bool {
        self.migrated.entry(token).read()
    }
}

}
