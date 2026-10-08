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
