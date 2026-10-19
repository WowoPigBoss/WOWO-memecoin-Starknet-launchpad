
use starknet::ContractAddress;

#[starknet::interface]
pub trait IWowoBondingCurveMarket<TContractState> {
        fn get_fee(self: @TContractState, amount: u256) -> u256;
}

#[starknet::contract]
pub mod WowoBondingCurveMarket {
        use super::IWowoBondingCurveMarket;
            use starknet::ContractAddress;
                use starknet::storage::{
                            StoragePointerReadAccess,
                                    StoragePointerWriteAccess,
                };

                    #[storage]
                        struct Storage {
                                    admin: ContractAddress,
                                            treasury: ContractAddress,
                                                    fee_bps: u16,
                        }

                            #[constructor]
                                fn constructor(
                                            ref self: ContractState,
                                                    admin: ContractAddress,
                                                            treasury: ContractAddress,
                                ) {

                                                            self.admin.write(admin);
                                                                    self.treasury.write(treasury);
                                                                            self.fee_bps.write(100);
                                }

                                    #[abi(embed_v0)]
                                        impl MarketImpl of IWowoBondingCurveMarket<ContractState> {
                                                    fn get_fee(
                                                                    self: @ContractState,
                                                                                amount: u256,
                                                    ) -> u256 {
                                                                    assert(amount > 0, 'INVALID_AMOUNT');
                                                                                (amount * self.fee_bps.read().into()) / 10_000
                                                    }
                                        }
}

