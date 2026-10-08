use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, mock_call,
    start_cheat_block_timestamp, start_cheat_caller_address,
};
use starknet::ContractAddress;

#[starknet::interface]
trait IWowoLiquidityLock<TState> {
    fn lock_position(ref self: TState, position_id: u64, duration: u64) -> u64;
    fn withdraw(ref self: TState, lock_id: u64);
    fn get_creator(self: @TState, lock_id: u64) -> ContractAddress;
    fn get_position_id(self: @TState, lock_id: u64) -> u64;
    fn get_unlock_time(self: @TState, lock_id: u64) -> u64;
    fn is_active(self: @TState, lock_id: u64) -> bool;
}

#[test]
fn test_lock_position() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    mock_call(nft, selector!("owner_of"), creator, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);
    mock_call(nft, selector!("transfer_from"), (), 1);

    let id = lock.lock_position(123, 28 * 24 * 60 * 60);

    assert(id == 1, 'wrong id');
    assert(lock.get_creator(id) == creator, 'wrong creator');
    assert(lock.get_position_id(id) == 123, 'wrong position');
    assert(lock.is_active(id), 'not active');
}

#[test]
#[should_panic]
fn test_cannot_withdraw_early() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    mock_call(nft, selector!("owner_of"), creator, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);
    mock_call(nft, selector!("transfer_from"), (), 2);

    let id = lock.lock_position(123, 28 * 24 * 60 * 60);
    lock.withdraw(id);
}

#[test]
fn test_withdraw_after_expiry() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    mock_call(nft, selector!("owner_of"), creator, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);
    mock_call(nft, selector!("transfer_from"), (), 2);

    let id = lock.lock_position(123, 28 * 24 * 60 * 60);

    start_cheat_block_timestamp(address, 1_000_000 + 28 * 24 * 60 * 60);

    lock.withdraw(id);

    assert(!lock.is_active(id), 'still active');
}

#[test]
#[should_panic]
fn test_invalid_duration() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);

    lock.lock_position(123, 1);
}

#[test]
#[should_panic]
fn test_other_creator_cannot_withdraw() {
    let creator_a: ContractAddress = 10.try_into().unwrap();
    let creator_b: ContractAddress = 11.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator_a);
    start_cheat_block_timestamp(address, 1_000_000);

    mock_call(nft, selector!("owner_of"), creator_a, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);

    let id = lock.lock_position(123, 28 * 24 * 60 * 60);

    start_cheat_caller_address(address, creator_b);
    start_cheat_block_timestamp(
        address,
        1_000_000 + 28 * 24 * 60 * 60,
    );

    lock.withdraw(id);
}

#[test]
#[should_panic]
fn test_cannot_withdraw_twice() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    mock_call(nft, selector!("owner_of"), creator, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);
    mock_call(nft, selector!("transfer_from"), (), 2);

    let id = lock.lock_position(123, 28 * 24 * 60 * 60);

    start_cheat_block_timestamp(
        address,
        1_000_000 + 28 * 24 * 60 * 60,
    );

    lock.withdraw(id);

    // Percobaan kedua harus gagal.
    lock.withdraw(id);
}

#[test]
#[should_panic]
fn test_non_owner_cannot_lock_position() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft_owner: ContractAddress = 11.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    // NFT sebenarnya milik wallet lain.
    mock_call(nft, selector!("owner_of"), nft_owner, 1);

    lock.lock_position(123, 28 * 24 * 60 * 60);
}

#[test]
#[should_panic]
fn test_same_position_cannot_be_locked_twice() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let nft: ContractAddress = 20.try_into().unwrap();

    let contract = declare("WowoLiquidityLock").unwrap().contract_class();
    let mut calldata = array![];
    nft.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    let lock = IWowoLiquidityLockDispatcher { contract_address: address };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    // Posisi pertama kali dimiliki creator.
    mock_call(nft, selector!("owner_of"), creator, 1);
    mock_call(nft, selector!("transfer_from"), (), 2);

    lock.lock_position(123, 28 * 24 * 60 * 60);

    // Setelah dikunci, NFT seharusnya bukan lagi milik creator.
    mock_call(nft, selector!("owner_of"), address, 1);

    // Percobaan lock kedua harus gagal.
    lock.lock_position(123, 28 * 24 * 60 * 60);
}



#[test]
#[should_panic]
fn test_transfer_failure_reverts_lock() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let dummy_arg: ContractAddress = 20.try_into().unwrap();

    // Deploy dummy contract terlebih dahulu.
    let contract = declare("WowoLiquidityLock").unwrap().contract_class();

    let mut nft_calldata = array![];
    dummy_arg.serialize(ref nft_calldata);

    let (nft, _) = contract.deploy(@nft_calldata).unwrap();

    // Deploy Lock dengan alamat dummy NFT yang benar-benar sudah deployed.
    let mut lock_calldata = array![];
    nft.serialize(ref lock_calldata);

    let (address, _) = contract.deploy(@lock_calldata).unwrap();

    let lock = IWowoLiquidityLockDispatcher {
        contract_address: address
    };

    start_cheat_caller_address(address, creator);

    // Owner NFT dibuat valid.
    mock_call(
        nft,
        selector!("owner_of"),
        creator,
        1
    );

    // transfer_from sengaja tidak dimock.
    // Dummy contract tidak memiliki fungsi transfer_from,
    // sehingga lock_position harus revert.
    lock.lock_position(999, 28 * 24 * 60 * 60);
}

#[test]
#[feature("safe_dispatcher")]
fn test_failed_unlock_keeps_lock_active() {
    let creator: ContractAddress = 10.try_into().unwrap();
    let dummy_arg: ContractAddress = 20.try_into().unwrap();

    // Deploy dummy contract sebagai NFT.
    let contract = declare("WowoLiquidityLock").unwrap().contract_class();

    let mut nft_calldata = array![];
    dummy_arg.serialize(ref nft_calldata);

    let (nft, _) = contract.deploy(@nft_calldata).unwrap();

    // Deploy Lock dengan alamat NFT tersebut.
    let mut lock_calldata = array![];
    nft.serialize(ref lock_calldata);

    let (address, _) = contract.deploy(@lock_calldata).unwrap();

    let lock = IWowoLiquidityLockDispatcher {
        contract_address: address
    };

    start_cheat_caller_address(address, creator);
    start_cheat_block_timestamp(address, 1_000_000);

    // NFT dimiliki creator.
    mock_call(
        nft,
        selector!("owner_of"),
        creator,
        1
    );

    // Transfer pertama berhasil: NFT masuk ke Lock.
    // Transfer kedua TIDAK dimock: sengaja dibuat gagal saat withdraw.
    mock_call(
        nft,
        selector!("transfer_from"),
        (),
        1
    );

    let lock_id = lock.lock_position(
        999,
        28 * 24 * 60 * 60
    );

    assert(lock.is_active(lock_id), 'lock not active');

    // Lompat ke waktu setelah expiry.
    start_cheat_block_timestamp(
        address,
        1_000_000 + 28 * 24 * 60 * 60
    );

    let safe_lock = IWowoLiquidityLockSafeDispatcher {
        contract_address: address
    };

    // Withdraw harus gagal karena transfer NFT kedua tidak tersedia.
    match safe_lock.withdraw(lock_id) {
        Result::Ok(_) => panic!("withdraw unexpectedly succeeded"),
        Result::Err(_) => {}
    }

    // Karena withdraw gagal, lock HARUS tetap aktif.
    assert(
        lock.is_active(lock_id),
        'LOCK_INACTIVE'
    );
}


#[starknet::interface]
trait IReentrantNFT<TState> {
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
    );
    fn was_reentered(self: @TState) -> bool;
}

#[starknet::contract]
mod ReentrantNFT {
    use super::{ContractAddress, IReentrantNFT, IWowoLiquidityLockDispatcher, IWowoLiquidityLockDispatcherTrait};

    use starknet::storage::{
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };

    #[storage]
    struct Storage {
        entered: bool,
        reentered: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl ReentrantNFTImpl of super::IReentrantNFT<ContractState> {

        fn owner_of(
            self: @ContractState,
            token_id: u256,
        ) -> ContractAddress {
            10.try_into().unwrap()
        }

        fn transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
        ) {
            if !self.entered.read() {
                self.entered.write(true);
                self.reentered.write(true);

                let lock = IWowoLiquidityLockDispatcher {
                    contract_address: to,
                };

                lock.lock_position(
                    1000,
                    28 * 24 * 60 * 60
                );
            }
        }

        fn was_reentered(
            self: @ContractState,
        ) -> bool {
            self.reentered.read()
        }
    }
}

#[test]
#[should_panic]
fn test_reentrancy_attempt_is_detected() {
    let nft_contract = declare("ReentrantNFT").unwrap().contract_class();

    let mut nft_calldata = array![];
    let (nft_address, _) = nft_contract.deploy(@nft_calldata).unwrap();

    let lock_contract = declare("WowoLiquidityLock").unwrap().contract_class();

    let mut lock_calldata = array![];
    nft_address.serialize(ref lock_calldata);

    let (lock_address, _) = lock_contract.deploy(@lock_calldata).unwrap();

    let lock = IWowoLiquidityLockDispatcher {
        contract_address: lock_address
    };

    let nft = IReentrantNFTDispatcher {
        contract_address: nft_address
    };

    let creator: ContractAddress = 10.try_into().unwrap();

    start_cheat_caller_address(lock_address, creator);

    mock_call(
        nft_address,
        selector!("owner_of"),
        creator,
        2
    );

    lock.lock_position(
        999,
        28 * 24 * 60 * 60
    );

    assert(
        nft.was_reentered(),
        'REENTRANCY_DETECTED'
    );
}
