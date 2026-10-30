use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoEkuboMigration<TContractState> {
    fn get_admin(self: @TContractState) -> ContractAddress;
    fn get_core(self: @TContractState) -> ContractAddress;
    fn get_positions(self: @TContractState) -> ContractAddress;
    fn collect_reserves(ref self: TContractState, token: ContractAddress) -> (u256, u256);
}

#[starknet::contract]
pub mod WowoEkuboMigration {
    use super::IWowoEkuboMigration;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::super::wowo_bonding_curve_market::{
        IWowoBondingCurveMarketDispatcher,
        IWowoBondingCurveMarketDispatcherTrait
    };

    #[storage]
    struct Storage {
        admin: ContractAddress,
        core: ContractAddress,
        positions: ContractAddress,
        market: ContractAddress,
        strk_token: ContractAddress,
        collected: bool,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        core: ContractAddress,
        positions: ContractAddress,
        market: ContractAddress,
        strk_token: ContractAddress,
    ) {
        assert(admin != 0, 'INVALID_ADMIN');
        assert(core != 0, 'INVALID_CORE');
        assert(positions != 0, 'INVALID_POSITIONS');
        assert(market != 0, 'INVALID_MARKET');
        assert(strk_token != 0, 'INVALID_STRK');

        self.admin.write(admin);
        self.core.write(core);
        self.positions.write(positions);
        self.market.write(market);
        self.strk_token.write(strk_token);
        self.collected.write(false);
    }

    #[abi(embed_v0)]
    impl MigrationImpl of super::IWowoEkuboMigration<ContractState> {
        fn get_admin(self: @ContractState) -> ContractAddress {
            self.admin.read()
        }

        fn get_core(self: @ContractState) -> ContractAddress {
            self.core.read()
        }

        fn get_positions(self: @ContractState) -> ContractAddress {
            self.positions.read()
        }

        fn collect_reserves(
            ref self: ContractState,
            token: ContractAddress
        ) -> (u256, u256) {
            assert(get_caller_address() == self.admin.read(), 'NOT_ADMIN');
            assert(!self.collected.read(), 'ALREADY_COLLECTED');
            assert(token != 0 && token != self.strk_token.read(), 'INVALID_TOKEN');

            let token_contract = IERC20Dispatcher { contract_address: token };
            let strk_contract = IERC20Dispatcher {
                contract_address: self.strk_token.read()
            };

            let address = get_contract_address();
            let token_before = token_contract.balance_of(address);
            let strk_before = strk_contract.balance_of(address);

            let market = IWowoBondingCurveMarketDispatcher {
                contract_address: self.market.read()
            };
            let (token_amount, strk_amount) = market.begin_migration(token);

            let token_after = token_contract.balance_of(address);
            let strk_after = strk_contract.balance_of(address);

            assert(token_after - token_before == token_amount, 'TOKEN_RECEIPT_MISMATCH');
            assert(strk_after - strk_before == strk_amount, 'STRK_RECEIPT_MISMATCH');

            self.collected.write(true);
            (token_amount, strk_amount)
        }
    }
}
