use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoAmmPool<TContractState> {
    fn get_token0(self: @TContractState) -> ContractAddress;
    fn get_token1(self: @TContractState) -> ContractAddress;
    fn get_reserves(self: @TContractState) -> (u256, u256);
    fn add_liquidity(ref self: TContractState, amount0: u256, amount1: u256);
}

#[starknet::contract]
pub mod WowoAmmPool {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc20::SafeERC20DispatcherTrait;

    #[storage]
    struct Storage {
        token0: ContractAddress,
        token1: ContractAddress,
        reserve0: u256,
        reserve1: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        token0: ContractAddress,
        token1: ContractAddress,
    ) {
        assert(token0 != token1, 'IDENTICAL_TOKENS');
        self.token0.write(token0);
        self.token1.write(token1);
        self.reserve0.write(0);
        self.reserve1.write(0);
    }

    #[abi(embed_v0)]
    impl WowoAmmPoolImpl of super::IWowoAmmPool<ContractState> {
        fn get_token0(self: @ContractState) -> ContractAddress {
            self.token0.read()
        }

        fn get_token1(self: @ContractState) -> ContractAddress {
            self.token1.read()
        }

        fn get_reserves(self: @ContractState) -> (u256, u256) {
            (self.reserve0.read(), self.reserve1.read())
        }

        fn add_liquidity(ref self: ContractState, amount0: u256, amount1: u256) {
            assert(amount0 > 0 && amount1 > 0, 'ZERO_AMOUNT');
            let caller = get_caller_address();
            let token0 = IERC20Dispatcher { contract_address: self.token0.read() };
            let token1 = IERC20Dispatcher { contract_address: self.token1.read() };
            token0.assert_transfer_from(caller, get_contract_address(), amount0);
            token1.assert_transfer_from(caller, get_contract_address(), amount1);
            self.reserve0.write(self.reserve0.read() + amount0);
            self.reserve1.write(self.reserve1.read() + amount1);
        }
    }
}
