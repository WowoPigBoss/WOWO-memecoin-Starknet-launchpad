use starknet::ContractAddress;

#[starknet::interface]
pub trait IEkuboPositionNFT<TContractState> {
        fn owner_of(
                    self: @TContractState,
                            token_id: u256,
        ) -> ContractAddress;

            fn transfer_from(
                        ref self: TContractState,
                                from: ContractAddress,
                                        to: ContractAddress,
                                                token_id: u256,
            );
}

#[starknet::interface]
pub trait IWowoLiquidityLock<TContractState> {
        fn lock_position(
                    ref self: TContractState,
                            position_id: u64,
                                    duration: u64,
        ) -> u64;

            fn withdraw(
                        ref self: TContractState,
                                lock_id: u64,
            );

                fn get_creator(
                            self: @TContractState,
                                    lock_id: u64,
                ) -> ContractAddress;

                    fn get_position_id(
                                self: @TContractState,
                                        lock_id: u64,
                    ) -> u64;

                        fn get_unlock_time(
                                    self: @TContractState,
                                            lock_id: u64,
                        ) -> u64;

                            fn is_active(
                                        self: @TContractState,
                                                lock_id: u64,
                            ) -> bool;
}

#[starknet::contract]
pub mod WowoLiquidityLock {
        use super::{
                    ContractAddress,
                            IEkuboPositionNFTDispatcher,
                                    IEkuboPositionNFTDispatcherTrait,
                                            IWowoLiquidityLock,
        };

            use starknet::{
                        get_block_timestamp,
                                get_caller_address,
                                        get_contract_address,
            };

                use starknet::storage::{
                            Map,
                                    StorageMapReadAccess,
        StoragePointerReadAccess,
                                            StorageMapWriteAccess,
        StoragePointerWriteAccess,
                };

                    const DURATION_28D: u64 = 28 * 24 * 60 * 60;
                        const DURATION_90D: u64 = 90 * 24 * 60 * 60;
                            const DURATION_180D: u64 = 180 * 24 * 60 * 60;
                                const DURATION_1Y: u64 = 365 * 24 * 60 * 60;

                                    #[storage]
                                        struct Storage {
                                                    position_nft: ContractAddress,
                                                            next_lock_id: u64,

                                                                    creators: Map<u64, ContractAddress>,
                                                                            position_ids: Map<u64, u64>,
                                                                                    start_times: Map<u64, u64>,
                                                                                            unlock_times: Map<u64, u64>,
                                                                                                    active: Map<u64, bool>,
                                        }

                                            #[event]
                                                #[derive(Drop, starknet::Event)]
                                                    enum Event {
                                                                PositionLocked: PositionLocked,
                                                                        PositionUnlocked: PositionUnlocked,
                                                    }

                                                        #[derive(Drop, starknet::Event)]
                                                            struct PositionLocked {
                                                                        #[key]
                                                                                lock_id: u64,
                                                                                        creator: ContractAddress,
                                                                                                position_id: u64,
                                                                                                        unlock_time: u64,
                                                            }

                                                                #[derive(Drop, starknet::Event)]
                                                                    struct PositionUnlocked {
                                                                                #[key]
                                                                                        lock_id: u64,
                                                                                                creator: ContractAddress,
                                                                                                        position_id: u64,
                                                                    }

                                                                        #[constructor]
                                                                            fn constructor(
                                                                                        ref self: ContractState,
                                                                                                position_nft: ContractAddress,
                                                                            ) {
                                                                                        self.position_nft.write(position_nft);
                                                                                                self.next_lock_id.write(1);
                                                                            }

                                                                                fn validate_duration(duration: u64) {
                                                                                            assert(
                                                                                                            duration == DURATION_28D
                                                                                                                            || duration == DURATION_90D
                                                                                                                                            || duration == DURATION_180D
                                                                                                                                                            || duration == DURATION_1Y,
                                                                                                                                                                        'INVALID_DURATION',
                                                                                            );
                                                                                }

                                                                                    #[abi(embed_v0)]
                                                                                        impl WowoLiquidityLockImpl of IWowoLiquidityLock<ContractState> {

                                                                                                    fn lock_position(
                                                                                                                    ref self: ContractState,
                                                                                                                                position_id: u64,
                                                                                                                                            duration: u64,
                                                                                                    ) -> u64 {
                                                                                                                    validate_duration(duration);

                                                                                                                                let creator = get_caller_address();
                                                                                                                                            let now = get_block_timestamp();

                                                                                                                                                        let nft = IEkuboPositionNFTDispatcher {
                                                                                                                                                                            contract_address: self.position_nft.read(),
                                                                                                                                                        };

                                                                                                                                                                    let token_id = u256 {
                                                                                                                                                                                        low: position_id.into(),
                                                                                                                                                                                                        high: 0,
                                                                                                                                                                    };

                                                                                                                                                                                assert(
                                                                                                                                                                                                    nft.owner_of(token_id) == creator,
                                                                                                                                                                                                                    'NOT_NFT_OWNER',
                                                                                                                                                                                );

                                                                                                                                                                                            let lock_id = self.next_lock_id.read();
                                                                                                                                                                                                        let unlock_time = now + duration;

                                                                                                                                                                                                                    nft.transfer_from(
                                                                                                                                                                                                                                        creator,
                                                                                                                                                                                                                                                        get_contract_address(),
                                                                                                                                                                                                                                                                        token_id,
                                                                                                                                                                                                                    );



                                                                                                                                                                                                                                self.creators.write(lock_id, creator);
                                                                                                                                                                                                                                            self.position_ids.write(lock_id, position_id);
                                                                                                                                                                                                                                                        self.start_times.write(lock_id, now);
                                                                                                                                                                                                                                                                    self.unlock_times.write(lock_id, unlock_time);
                                                                                                                                                                                                                                                                                self.active.write(lock_id, true);

                                                                                                                                                                                                                                                                                            self.next_lock_id.write(lock_id + 1);

                                                                                                                                                                                                                                                                                                        self.emit(
                                                                                                                                                                                                                                                                                                                            PositionLocked {
                                                                                                                                                                                                                                                                                                                                                    lock_id,
                                                                                                                                                                                                                                                                                                                                                                        creator,
                                                                                                                                                                                                                                                                                                                                                                                            position_id,
                                                                                                                                                                                                                                                                                                                                                                                                                unlock_time,
                                                                                                                                                                                                                                                                                                                            },
                                                                                                                                                                                                                                                                                                        );

                                                                                                                                                                                                                                                                                                                    lock_id
                                                                                                    }

                                                                                                            fn withdraw(
                                                                                                                            ref self: ContractState,
                                                                                                                                        lock_id: u64,
                                                                                                            ) {
                                                                                                                            let caller = get_caller_address();
                                                                                                                                        let now = get_block_timestamp();

                                                                                                                                                    assert(
                                                                                                                                                                        self.active.read(lock_id),
                                                                                                                                                                                        'LOCK_NOT_ACTIVE',
                                                                                                                                                    );

                                                                                                                                                                let creator = self.creators.read(lock_id);

                                                                                                                                                                            assert(
                                                                                                                                                                                                creator == caller,
                                                                                                                                                                                                                'NOT_CREATOR',
                                                                                                                                                                            );

                                                                                                                                                                                        let unlock_time = self.unlock_times.read(lock_id);

                                                                                                                                                                                                    assert(
                                                                                                                                                                                                                        now >= unlock_time,
                                                                                                                                                                                                                                        'LOCK_NOT_EXPIRED',
                                                                                                                                                                                                    );

                                                                                                                                                                                                                let position_id = self.position_ids.read(lock_id);

                                                                                                                                                                                                                            let nft = IEkuboPositionNFTDispatcher {
                                                                                                                                                                                                                                                contract_address: self.position_nft.read(),
                                                                                                                                                                                                                            };

                                                                                                                                                                                                                                        let token_id = u256 {
                                                                                                                                                                                                                                                            low: position_id.into(),
                                                                                                                                                                                                                                                                            high: 0,
                                                                                                                                                                                                                                        };

                                                                                                                                                                                                                                                    nft.transfer_from(
                                                                                                                                                                                                                                                                        get_contract_address(),
                                                                                                                                                                                                                                                                                        caller,
                                                                                                                                                                                                                                                                                                        token_id,
                                                                                                                                                                                                                                                    );

                                                                                                                                                                                                                                                                self.active.write(lock_id, false);

                                                                                                                                                                                                                                                                            self.emit(
                                                                                                                                                                                                                                                                                                PositionUnlocked {
                                                                                                                                                                                                                                                                                                                        lock_id,
                                                                                                                                                                                                                                                                                                                                            creator,
                                                                                                                                                                                                                                                                                                                                                                position_id,
                                                                                                                                                                                                                                                                                                },
                                                                                                                                                                                                                                                                            );
                                                                                                            }

                                                                                                                    fn get_creator(
                                                                                                                                    self: @ContractState,
                                                                                                                                                lock_id: u64,
                                                                                                                    ) -> ContractAddress {
                                                                                                                                    self.creators.read(lock_id)
                                                                                                                    }

                                                                                                                            fn get_position_id(
                                                                                                                                            self: @ContractState,
                                                                                                                                                        lock_id: u64,
                                                                                                                            ) -> u64 {
                                                                                                                                            self.position_ids.read(lock_id)
                                                                                                                            }

                                                                                                                                    fn get_unlock_time(
                                                                                                                                                    self: @ContractState,
                                                                                                                                                                lock_id: u64,
                                                                                                                                    ) -> u64 {
                                                                                                                                                    self.unlock_times.read(lock_id)
                                                                                                                                    }

                                                                                                                                            fn is_active(
                                                                                                                                                            self: @ContractState,
                                                                                                                                                                        lock_id: u64,
                                                                                                                                            ) -> bool {
                                                                                                                                                            self.active.read(lock_id)
                                                                                                                                            }
                                                                                        }
}
