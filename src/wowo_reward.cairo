#[starknet::interface]
trait IERC20BalanceOf<TState> {
    fn balance_of(self: @TState, account: starknet::ContractAddress) -> u256;
}

#[starknet::contract]
mod WowoReward {
    use starknet::ContractAddress;
    use starknet::storage::{Map, StoragePathEntry};
    use super::{IERC20BalanceOfDispatcher, IERC20BalanceOfDispatcherTrait};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: ContractAddress,
        wowo_token: ContractAddress,
        reward_token: ContractAddress,
        reward_pool: u256,
        min_balance: u256,
        holding_period: u64,
        daily_rate: u256,
        holding_start: Map<ContractAddress, u64>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        wowo_token: ContractAddress,
        reward_token: ContractAddress,
        reward_pool: u256,
        min_balance: u256,
        holding_period: u64,
        daily_rate: u256,
    ) {
        self.admin.write(admin);
        self.wowo_token.write(wowo_token);
        self.reward_token.write(reward_token);
        self.reward_pool.write(reward_pool);
        self.min_balance.write(min_balance);
        self.holding_period.write(holding_period);
        self.daily_rate.write(daily_rate);
    }

    #[external(v0)]
    fn register(
            ref self: ContractState,
    ) {
            let caller = starknet::get_caller_address();

                let wowo = IERC20BalanceOfDispatcher {
                            contract_address: self.wowo_token.read()
                };

                    let balance = wowo.balance_of(caller);
                        let current = starknet::get_block_timestamp();
                            let start = self.holding_start.entry(caller).read();

                                if balance < self.min_balance.read() {
                                            self.holding_start.entry(caller).write(0);
                                } else if start == 0 {
                                            self.holding_start.entry(caller).write(current);
                                }
    }
    #[external(v0)]
    fn get_admin(
        self: @ContractState,
    ) -> ContractAddress {
        self.admin.read()
    }

    #[external(v0)]
    fn get_min_balance(
        self: @ContractState,
    ) -> u256 {
        self.min_balance.read()
    }

    #[external(v0)]
    fn get_holding_period(
        self: @ContractState,
    ) -> u64 {
        self.holding_period.read()
    }

    #[external(v0)]
    fn get_daily_rate(
        self: @ContractState,
    ) -> u256 {
        self.daily_rate.read()
    }

    #[external(v0)]
    fn get_holding_start(
        self: @ContractState,
        account: ContractAddress,
    ) -> u64 {
        self.holding_start.entry(account).read()
    }
}
