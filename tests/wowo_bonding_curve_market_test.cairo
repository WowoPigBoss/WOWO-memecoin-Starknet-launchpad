use snforge_std::{
ContractClassTrait, DeclareResultTrait, declare, mock_call,
start_cheat_caller_address,
};
use starknet::ContractAddress;

use wowo_launchpad::wowo_bonding_curve_market::{
IWowoBondingCurveMarketDispatcher,
IWowoBondingCurveMarketDispatcherTrait,
};

fn deploy_market() -> (IWowoBondingCurveMarketDispatcher, ContractAddress) {
let admin: ContractAddress = 10.try_into().unwrap();
let treasury: ContractAddress = 20.try_into().unwrap();
let strk: ContractAddress = 30.try_into().unwrap();

let contract = declare("WowoBondingCurveMarket")
    .unwrap()
    .contract_class();

let mut calldata = array![];
admin.serialize(ref calldata);
treasury.serialize(ref calldata);
strk.serialize(ref calldata);

let (address, _) = contract.deploy(@calldata).unwrap();

(
    IWowoBondingCurveMarketDispatcher {
        contract_address: address
    },
    address
)

}

#[test]
fn test_default_fee_is_one_percent() {
let (market, _) = deploy_market();
assert(market.get_fee(10_000) == 100, 'WRONG_FEE');
}

#[test]
fn test_admin_can_change_fee() {
let (market, address) = deploy_market();
let admin: ContractAddress = 10.try_into().unwrap();

start_cheat_caller_address(address, admin);
market.set_fee_bps(200);

assert(market.get_fee(10_000) == 200, 'FEE_NOT_UPDATED');

}

#[test]
#[should_panic]
fn test_fee_cannot_exceed_ten_percent() {
let (market, address) = deploy_market();
let admin: ContractAddress = 10.try_into().unwrap();

start_cheat_caller_address(address, admin);
market.set_fee_bps(1001);

}

fn seed_test_market(
token: ContractAddress,
) -> (IWowoBondingCurveMarketDispatcher, ContractAddress) {
let (market, address) = deploy_market();
let admin: ContractAddress = 10.try_into().unwrap();
let strk: ContractAddress = 30.try_into().unwrap();

start_cheat_caller_address(address, admin);
mock_call(token, selector!("transfer_from"), true, 1);
mock_call(strk, selector!("transfer_from"), true, 1);

market.create_market(token, 1000, 500);
(market, address)

}

#[test]
fn test_create_market_sets_reserves() {
let token: ContractAddress = 40.try_into().unwrap();
let (market, _) = seed_test_market(token);

let (token_reserve, strk_reserve) = market.get_reserves(token);
assert(token_reserve == 1000, 'WRONG_TOKEN_RESERVE');
assert(strk_reserve == 500, 'WRONG_STRK_RESERVE');

}

#[test]
fn test_buy_updates_reserves() {
let token: ContractAddress = 40.try_into().unwrap();
let strk: ContractAddress = 30.try_into().unwrap();
let user: ContractAddress = 50.try_into().unwrap();
let (market, address) = seed_test_market(token);

start_cheat_caller_address(address, user);
mock_call(strk, selector!("transfer_from"), true, 1);
mock_call(strk, selector!("transfer"), true, 1);
mock_call(token, selector!("transfer"), true, 1);

let out = market.buy(token, 100, 165);
assert(out == 165, 'WRONG_BUY_OUTPUT');

let (token_reserve, strk_reserve) = market.get_reserves(token);
assert(token_reserve == 835, 'WRONG_TOKEN_RESERVE');
assert(strk_reserve == 599, 'WRONG_STRK_RESERVE');

}

#[test]
fn test_sell_updates_reserves() {
let token: ContractAddress = 40.try_into().unwrap();
let strk: ContractAddress = 30.try_into().unwrap();
let user: ContractAddress = 50.try_into().unwrap();
let (market, address) = seed_test_market(token);

start_cheat_caller_address(address, user);
mock_call(token, selector!("transfer_from"), true, 1);
mock_call(strk, selector!("transfer"), true, 2);

let out = market.sell(token, 500, 165);
assert(out == 165, 'WRONG_SELL_OUTPUT');

let (token_reserve, strk_reserve) = market.get_reserves(token);
assert(token_reserve == 1500, 'WRONG_TOKEN_RESERVE');
assert(strk_reserve == 334, 'WRONG_STRK_RESERVE');

}

#[test]
#[should_panic]
fn test_buy_rejects_slippage() {
let token: ContractAddress = 40.try_into().unwrap();
let user: ContractAddress = 50.try_into().unwrap();
let (market, address) = seed_test_market(token);

start_cheat_caller_address(address, user);
market.buy(token, 100, 166);

}
