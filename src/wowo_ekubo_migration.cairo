use starknet::ContractAddress;
use core::num::traits::Zero;
use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

#[starknet::interface]
pub trait IWowoEkuboMigration<TContractState> {
    fn get_admin(self: @TContractState) -> ContractAddress;
    fn get_core(self: @TContractState) -> ContractAddress;
    fn get_positions(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod WowoEkuboMigration {
    use starknet::ContractAddress;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        admin: ContractAddress,
        core: ContractAddress,
        positions: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        core: ContractAddress,
        positions: ContractAddress,
    ) {
        assert(admin != 0, 'INVALID_ADMIN');
        assert(core != 0, 'INVALID_CORE');
        assert(positions != 0, 'INVALID_POSITIONS');

        self.admin.write(admin);
        self.core.write(core);
        self.positions.write(positions);
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
    }
}
