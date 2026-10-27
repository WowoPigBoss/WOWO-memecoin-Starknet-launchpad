use core::serde::Serde;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;
use openzeppelin::interfaces::erc20::{
    IERC20Dispatcher, IERC20DispatcherTrait,
};

#[starknet::interface]
trait IWowoLaunchpadPayment<TState> {
    fn pay_fee(self: @TState);
    fn pay_fee_strk(self: @TState);
    fn set_wowo_per_strk(ref self: TState, new_rate: u256);
}

fn deploy_token(recipient: ContractAddress) -> IERC20Dispatcher {
    let class = declare("TestERC20").unwrap().contract_class();
    let mut calldata = array![];
    recipient.serialize(ref calldata);
    100_000_u256.serialize(ref calldata);
    let (address, _) = class.deploy(@calldata).unwrap();
    IERC20Dispatcher { contract_address: address }
}

fn deploy_launchpad(
    wowo: ContractAddress,
    strk: ContractAddress,
    treasury: ContractAddress,
    admin: ContractAddress,
) -> (IWowoLaunchpadPaymentDispatcher, ContractAddress) {
    let class = declare("WowoLaunchpad").unwrap().contract_class();
    let mut calldata = array![];
    wowo.serialize(ref calldata);
    strk.serialize(ref calldata);
    treasury.serialize(ref calldata);
    100_u256.serialize(ref calldata);
    2_u256.serialize(ref calldata);
    admin.serialize(ref calldata);

    let (address, _) = class.deploy(@calldata).unwrap();
    (IWowoLaunchpadPaymentDispatcher { contract_address: address }, address)
}

#[test]
fn test_pay_fee_wowo_transfers_expected_amount() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(wowo.contract_address, admin);
    wowo.approve(address, 200);
    stop_cheat_caller_address(wowo.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee();

    assert(wowo.balance_of(treasury) == 200, 'WRONG_WOWO_FEE');
}

#[test]
fn test_pay_fee_strk_transfers_current_fee() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(strk.contract_address, admin);
    strk.approve(address, 110);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee_strk();

    assert(strk.balance_of(treasury) == 110, 'WRONG_STRK_FEE');
}

#[test]
#[should_panic]
fn test_pay_fee_wowo_rejects_without_allowance() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee();
}

#[test]
#[should_panic]
fn test_pay_fee_strk_rejects_without_allowance() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee_strk();
}

#[test]
#[should_panic]
fn test_pay_fee_wowo_rejects_insufficient_balance() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let user: ContractAddress = 30.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(wowo.contract_address, user);
    wowo.approve(address, 200);
    stop_cheat_caller_address(wowo.contract_address);

    start_cheat_caller_address(address, user);
    launchpad.pay_fee();
}

#[test]
#[should_panic]
fn test_pay_fee_strk_rejects_insufficient_balance() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let user: ContractAddress = 30.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(strk.contract_address, user);
    strk.approve(address, 110);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(address, user);
    launchpad.pay_fee_strk();
}

#[test]
#[should_panic]
fn test_pay_fee_wowo_rejects_allowance_one_below_fee() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(wowo.contract_address, admin);
    wowo.approve(address, 199);
    stop_cheat_caller_address(wowo.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee();
}

#[test]
#[should_panic]
fn test_pay_fee_strk_rejects_allowance_one_below_fee() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(strk.contract_address, admin);
    strk.approve(address, 109);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee_strk();
}

#[test]
fn test_updated_rate_changes_wowo_payment_amount() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);
    let (launchpad, address) = deploy_launchpad(
        wowo.contract_address, strk.contract_address, treasury, admin
    );

    start_cheat_caller_address(address, admin);
    launchpad.set_wowo_per_strk(5);

    start_cheat_caller_address(wowo.contract_address, admin);
    wowo.approve(address, 500);
    stop_cheat_caller_address(wowo.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee();

    assert(wowo.balance_of(treasury) == 500, 'UPDATED_RATE_WRONG_FEE');
}

#[test]
fn test_pay_fee_strk_rounds_fraction_up() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let wowo = deploy_token(admin);
    let strk = deploy_token(admin);

    let class = declare("WowoLaunchpad").unwrap().contract_class();
    let mut calldata = array![];
    wowo.contract_address.serialize(ref calldata);
    strk.contract_address.serialize(ref calldata);
    treasury.serialize(ref calldata);
    101_u256.serialize(ref calldata);
    2_u256.serialize(ref calldata);
    admin.serialize(ref calldata);

    let (address, _) = class.deploy(@calldata).unwrap();
    let launchpad = IWowoLaunchpadPaymentDispatcher {
        contract_address: address
    };

    start_cheat_caller_address(strk.contract_address, admin);
    strk.approve(address, 112);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(address, admin);
    launchpad.pay_fee_strk();

    assert(strk.balance_of(treasury) == 112, 'STRK_FEE_NOT_ROUNDED_UP');
}
