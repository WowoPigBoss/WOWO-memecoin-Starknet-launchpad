#[starknet::contract]
mod WowoReward {
        use openzeppelin_interfaces::erc20::IERC20Dispatcher;
            use openzeppelin_token::erc20::utils::SafeERC20DispatcherTrait;
                use starknet::{
                            ContractAddress,
                                    get_caller_address, get_contract_address,
                                            get_block_timestamp,
                                                    storage::{
                                                                    Map, StoragePathEntry,
                                                                                StoragePointerReadAccess,
                                                                                            StoragePointerWriteAccess,
                                                    },
                };

                    const MIN_WOWO: u256 = 10000000000000000000000;
                        const SEVEN_DAYS: u64 = 604800;

                            #[storage]
                                struct Storage {
                                            wowo_token: ContractAddress,
                                                    strk_token: ContractAddress,
                                                            admin: ContractAddress,

                                                                    reward_pool: u256,

                                                                            registered: Map<ContractAddress, bool>,
                                                                                    holding_start: Map<ContractAddress, u64>,
                                                                                            last_claim: Map<ContractAddress, u64>,
                                }

                                    #[event]
                                        #[derive(Drop, starknet::Event)]
                                            enum Event {
                                                        HolderRegistered: HolderRegistered,
                                                                RewardClaimed: RewardClaimed,
                                                                        PoolFunded: PoolFunded,
                                            }

                                                #[derive(Drop, starknet::Event)]
                                                    struct HolderRegistered {
                                                                #[key]
                                                                        holder: ContractAddress,
                                                                                timestamp: u64,
                                                    }

                                                        #[derive(Drop, starknet::Event)]
                                                            struct RewardClaimed {
                                                                        #[key]
                                                                                holder: ContractAddress,
                                                                                        reward: u256,
                                                            }

                                                                #[derive(Drop, starknet::Event)]
                                                                    struct PoolFunded {
                                                                                #[key]
                                                                                        admin: ContractAddress,
                                                                                                amount: u256,
                                                                    }

                                                                        #[constructor]
                                                                            fn constructor(
                                                                                        ref self: ContractState,
                                                                                                wowo_token: ContractAddress,
                                                                                                        strk_token: ContractAddress,
                                                                                                                admin: ContractAddress,
                                                                            ) {
                                                                                        self.wowo_token.write(wowo_token);
                                                                                                self.strk_token.write(strk_token);
                                                                                                        self.admin.write(admin);
                                                                                                                self.reward_pool.write(0);
                                                                            }

                                                                                #[external(v0)]
                                                                                    fn register(
                                                                                                ref self: ContractState,
                                                                                    ) {
                                                                                                let caller = get_caller_address();

                                                                                                        let wowo = IERC20Dispatcher {
                                                                                                                        contract_address: self.wowo_token.read()
                                                                                                        };

                                                                                                                let balance = wowo.balance_of(caller);

                                                                                                                        assert(balance >= MIN_WOWO, 'MIN_10000_WOWO');

                                                                                                                                if !self.registered.entry(caller) {
                                                                                                                                                self.registered.entry(caller, true);
                                                                                                                                                            self.holding_start.entry(caller, get_block_timestamp());

                                                                                                                                                                        self.emit(
                                                                                                                                                                                            HolderRegistered {
                                                                                                                                                                                                                    holder: caller,
                                                                                                                                                                                                                                        timestamp: get_block_timestamp(),
                                                                                                                                                                                            }
                                                                                                                                                                        );
                                                                                                                                }
                                                                                    }

                                                                                        #[external(v0)]
                                                                                            fn fund_pool(
                                                                                                        ref self: ContractState,
                                                                                                                amount: u256,
                                                                                            ) {
                                                                                                        let caller = get_caller_address();

                                                                                                                assert(caller == self.admin.read(), 'NOT_ADMIN');
                                                                                                                        assert(amount > 0, 'INVALID_AMOUNT');

                                                                                                                                let strk = IERC20Dispatcher {
                                                                                                                                                contract_address: self.strk_token.read()
                                                                                                                                };

                                                                                                                                        strk.assert_transfer_from(
                                                                                                                                                        caller,
                                                                                                                                                                    get_contract_address(),
                                                                                                                                                                                amount
                                                                                                                                        );

                                                                                                                                                self.reward_pool.write(
                                                                                                                                                                self.reward_pool.read() + amount
                                                                                                                                                );

                                                                                                                                                        self.emit(
                                                                                                                                                                        PoolFunded {
                                                                                                                                                                                            admin: caller,
                                                                                                                                                                                                            amount,
                                                                                                                                                                        }
                                                                                                                                                        );
                                                                                            }

                                                                                                #[external(v0)]
                                                                                                    fn claim(
                                                                                                                ref self: ContractState,
                                                                                                    ) {
                                                                                                                let caller = get_caller_address();

                                                                                                                        let wowo = IERC20Dispatcher {
                                                                                                                                        contract_address: self.wowo_token.read()
                                                                                                                        };

                                                                                                                                let balance = wowo.balance_of(caller);

                                                                                                                                        assert(balance >= MIN_WOWO, 'MIN_10000_WOWO');
                                                                                                                                                assert(self.registered.entry(caller), 'NOT_REGISTERED');

                                                                                                                                                        let now = get_block_timestamp();
                                                                                                                                                                let start = self.holding_start.entry(caller);

                                                                                                                                                                        assert(now >= start + SEVEN_DAYS, 'HOLD_7_DAYS');

                                                                                                                                                                                let elapsed_days: u256 =
                                                                                                                                                                                            (now - start).into() / 86400;

                                                                                                                                                                                                    // 0,001% = 0.00001
                                                                                                                                                                                                            // Weight = saldo WOWO × jumlah hari × 0,001%
                                                                                                                                                                                                                    let weight =
                                                                                                                                                                                                                                balance * elapsed_days / 100000;

                                                                                                                                                                                                                                        assert(weight > 0, 'ZERO_WEIGHT');

                                                                                                                                                                                                                                                let reward_pool = self.reward_pool.read();

                                                                                                                                                                                                                                                        assert(reward_pool > 0, 'EMPTY_POOL');

                                                                                                                                                                                                                                                                // Versi awal:
                                                                                                                                                                                                                                                                        // reward berdasarkan weight, dibatasi oleh pool.
                                                                                                                                                                                                                                                                                let reward = if weight < reward_pool {
                                                                                                                                                                                                                                                                                                weight
                                                                                                                                                                                                                                                                                } else {
                                                                                                                                                                                                                                                                                                reward_pool
                                                                                                                                                                                                                                                                                };

                                                                                                                                                                                                                                                                                        assert(reward > 0, 'ZERO_REWARD');

                                                                                                                                                                                                                                                                                                let strk = IERC20Dispatcher {
                                                                                                                                                                                                                                                                                                                contract_address: self.strk_token.read()
                                                                                                                                                                                                                                                                                                };

                                                                                                                                                                                                                                                                                                        strk.assert_transfer(caller, reward);

                                                                                                                                                                                                                                                                                                                self.reward_pool.write(
                                                                                                                                                                                                                                                                                                                                reward_pool - reward
                                                                                                                                                                                                                                                                                                                );

                                                                                                                                                                                                                                                                                                                        self.last_claim.entry(caller, now);

                                                                                                                                                                                                                                                                                                                                self.emit(
                                                                                                                                                                                                                                                                                                                                                RewardClaimed {
                                                                                                                                                                                                                                                                                                                                                                    holder: caller,
                                                                                                                                                                                                                                                                                                                                                                                    reward,
                                                                                                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                                                                                );
                                                                                                    }

                                                                                                        #[view]
                                                                                                            fn get_holding_time(
                                                                                                                        self: @ContractState,
                                                                                                                                holder: ContractAddress,
                                                                                                            ) -> u64 {
                                                                                                                        if !self.registered.entry(holder) {
                                                                                                                                        0
                                                                                                                        } else {
                                                                                                                                        get_block_timestamp() - self.holding_start.entry(holder)
                                                                                                                        }
                                                                                                            }

                                                                                                                #[view]
                                                                                                                    fn get_reward_pool(
                                                                                                                                self: @ContractState,
                                                                                                                    ) -> u256 {
                                                                                                                                self.reward_pool.read()
                                                                                                                    }

                                                                                                                        #[view]
                                                                                                                            fn is_registered(
                                                                                                                                        self: @ContractState,
                                                                                                                                                holder: ContractAddress,
                                                                                                                            ) -> bool {
                                                                                                                                        self.registered.entry(holder)
                                                                                                                            }
}
                                                                                                                                                                                            }
                                                                            )
                                                    }
                }
}