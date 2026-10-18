use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoBondingCurve<TContractState> {
    fn get_price(
        self: @TContractState,
        virtual_token_reserve: u256,
        virtual_strk_reserve: u256,
        token_amount: u256,
    ) -> u256;

    fn get_buy_cost(
        self: @TContractState,
        token_reserve: u256,
        strk_reserve: u256,
        token_amount: u256,
    ) -> u256;

    fn get_sell_return(
        self: @TContractState,
        token_reserve: u256,
        strk_reserve: u256,
        token_amount: u256,
    ) -> u256;
}

#[starknet::contract]
pub mod WowoBondingCurve {
    use super::IWowoBondingCurve;
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        admin: ContractAddress,
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

        fn get_buy_cost(
            self: @ContractState,
            token_reserve: u256,
            strk_reserve: u256,
            token_amount: u256,
        ) -> u256 {
            assert(token_reserve > 0, 'INVALID_TOKEN_RESERVE');
            assert(strk_reserve > 0, 'INVALID_STRK_RESERVE');
            assert(token_amount > 0, 'INVALID_AMOUNT');
            assert(token_amount < token_reserve, 'INSUFFICIENT_TOKEN_RESERVE');

            (strk_reserve * token_amount)
                / (token_reserve - token_amount)
        }

        fn get_sell_return(
            self: @ContractState,
            token_reserve: u256,
            strk_reserve: u256,
            token_amount: u256,
        ) -> u256 {
            assert(token_reserve > 0, 'INVALID_TOKEN_RESERVE');
            assert(strk_reserve > 0, 'INVALID_STRK_RESERVE');
            assert(token_amount > 0, 'INVALID_AMOUNT');

            (strk_reserve * token_amount)
                / (token_reserve + token_amount)
        }
    }
}
