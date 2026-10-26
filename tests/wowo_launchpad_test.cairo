use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare,
    start_cheat_caller_address,
};
use starknet::ContractAddress;

#[starknet::interface]
trait IWowoLaunchpad<TState> {
    fn set_wowo_per_strk(ref self: TState, new_rate: u256);
    fn get_wowo_per_strk(self: @TState) -> u256;
}

fn deploy_launchpad() -> (IWowoLaunchpadDispatcher, ContractAddress) {
    let admin: ContractAddress = 10.try_into().unwrap();
    let wowo: ContractAddress = 20.try_into().unwrap();
    let strk: ContractAddress = 30.try_into().unwrap();
    let treasury: ContractAddress = 40.try_into().unwrap();

    let contract = declare("WowoLaunchpad").unwrap().contract_class();
    let mut calldata = array![];
    wowo.serialize(ref calldata);
    strk.serialize(ref calldata);
    treasury.serialize(ref calldata);
    100_u256.serialize(ref calldata);
    2_u256.serialize(ref calldata);
    admin.serialize(ref calldata);

    let (address, _) = contract.deploy(@calldata).unwrap();
    (IWowoLaunchpadDispatcher { contract_address: address }, address)
}

#[test]
#[should_panic(expected: 'INVALID_RATE')]
fn test_admin_cannot_set_zero_rate() {
    let (launchpad, address) = deploy_launchpad();
    let admin: ContractAddress = 10.try_into().unwrap();
    start_cheat_caller_address(address, admin);
    launchpad.set_wowo_per_strk(0);
}

#[test]
fn test_admin_can_set_positive_rate() {
    let (launchpad, address) = deploy_launchpad();
    let admin: ContractAddress = 10.try_into().unwrap();
    start_cheat_caller_address(address, admin);
    launchpad.set_wowo_per_strk(5);
    assert(launchpad.get_wowo_per_strk() == 5, 'RATE_NOT_UPDATED');
}

#[test]
#[should_panic(expected: 'NOT_ADMIN')]
fn test_non_admin_cannot_set_rate() {
    let (launchpad, address) = deploy_launchpad();
    let user: ContractAddress = 50.try_into().unwrap();
    start_cheat_caller_address(address, user);
    launchpad.set_wowo_per_strk(5);
}
