use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoBondingCurve<TContractState> {
    fn get_price(
        self: @TContractState,
        virtual_token_reserve: u256,
        virtual_strk_reserve: u256,
        token_amount: u256,
    ) -> u256;
}

#[starknet::contract]
pub mod WowoBondingCurve {
    use super::IWowoBondingCurve;
    use core::starknet::storage::Map;
    use starknet::storage::{StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        admin: ContractAddress,
        token_reserves: Map<ContractAddress, u256>,
        strk_reserves: Map<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
    ) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl WowoBondingCurveImpl of IWowoBondingCurve<ContractState> {
        fn get_price(
            self: @ContractState,
            virtual_token_reserve: u256,
            virtual_strk_reserve: u256,
            token_amount: u256,
        ) -> u256 {
            assert(virtual_token_reserve > 0, 'INVALID_TOKEN_RESERVE');
            assert(virtual_strk_reserve > 0, 'INVALID_STRK_RESERVE');
            assert(token_amount > 0, 'INVALID_AMOUNT');

            (virtual_strk_reserve * token_amount)
                / virtual_token_reserve
        }
    }
}
