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
fn test_zero_fee_is_allowed() {
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    start_cheat_caller_address(address, admin);
    market.set_fee_bps(0);
    assert(market.get_fee(10_000) == 0, 'FEE_NOT_ZERO');
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

#[test]
#[should_panic]
fn test_sell_rejects_slippage() {
    let token: ContractAddress = 40.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();
    let (market, address) = seed_test_market(token);

    start_cheat_caller_address(address, user);
    market.sell(token, 500, 166);
}

#[test]
#[should_panic]
fn test_buy_rejects_uninitialized_market() {
    let (market, _) = deploy_market();
    let token: ContractAddress = 40.try_into().unwrap();

    market.buy(token, 100, 0);
}

#[test]
#[should_panic]
fn test_sell_rejects_zero_amount() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = seed_test_market(token);
    let user: ContractAddress = 50.try_into().unwrap();

    start_cheat_caller_address(address, user);
    market.sell(token, 0, 0);
}

#[test]
#[should_panic]
fn test_non_admin_cannot_create_market() {
    let (market, address) = deploy_market();
    let user: ContractAddress = 50.try_into().unwrap();
    let token: ContractAddress = 40.try_into().unwrap();

    start_cheat_caller_address(address, user);
    market.create_market(token, 1000, 500);
}

#[test]
#[should_panic]
fn test_market_cannot_be_created_twice() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, _) = seed_test_market(token);

    market.create_market(token, 2000, 1000);
}

#[test]
#[should_panic]
fn test_create_market_rejects_zero_token_seed() {
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let token: ContractAddress = 40.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.create_market(token, 0, 500);
}

#[test]
#[should_panic]
fn test_create_market_rejects_zero_strk_seed() {
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let token: ContractAddress = 40.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.create_market(token, 1000, 0);
}

#[test]
#[should_panic]
fn test_buy_rejects_zero_amount() {
    let token: ContractAddress = 40.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();
    let (market, address) = seed_test_market(token);

    start_cheat_caller_address(address, user);
    market.buy(token, 0, 0);
}

#[test]
#[should_panic(expected: 'NOT_ADMIN')]
fn test_non_admin_cannot_change_fee() {
    let (market, address) = deploy_market();
    let user: ContractAddress = 50.try_into().unwrap();

    start_cheat_caller_address(address, user);
    market.set_fee_bps(500);
}

#[test]
fn test_admin_can_set_maximum_fee() {
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.set_fee_bps(1000);

    assert(market.get_fee(10_000) == 1000, 'WRONG_MAX_FEE');
}

#[test]
#[should_panic(expected: 'INVALID_TOKEN')]
fn test_create_market_rejects_strk_as_project_token() {
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let strk: ContractAddress = 30.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.create_market(strk, 1000, 500);
}

#[test]
fn test_fee_rounds_down_for_small_amount() {
    let (market, _) = deploy_market();

    assert(market.get_fee(1) == 0, 'WRONG_SMALL_FEE');
    assert(market.get_fee(99) == 0, 'WRONG_SMALL_FEE');
    assert(market.get_fee(100) == 1, 'WRONG_SMALL_FEE');
}

#[test]
#[should_panic(expected: 'INVALID_AMOUNT')]
fn test_get_fee_rejects_zero_amount() {
    let (market, _) = deploy_market();
    market.get_fee(0);
}


#[test]
#[should_panic(expected: 'NOT_ADMIN')]
fn test_non_admin_cannot_begin_migration() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();
    let strk: ContractAddress = 30.try_into().unwrap();
    let threshold: u256 = 15_000_000_000_000_000_000_000;

    mock_call(token, selector!("transfer_from"), true, 1);
    mock_call(strk, selector!("transfer_from"), true, 1);

    start_cheat_caller_address(address, admin);
    market.create_market(token, 1000, threshold);

    start_cheat_caller_address(address, user);
    market.begin_migration(token);
}

#[test]
fn test_admin_can_begin_migration_at_threshold() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let strk: ContractAddress = 30.try_into().unwrap();
    let threshold: u256 = 15_000_000_000_000_000_000_000;

    mock_call(token, selector!("transfer_from"), true, 1);
    mock_call(strk, selector!("transfer_from"), true, 1);

    start_cheat_caller_address(address, admin);
    market.create_market(token, 1000, threshold);
    market.begin_migration(token);

    assert(market.is_paused(token), 'MARKET_NOT_PAUSED');
}

#[test]
#[should_panic(expected: 'ALREADY_PAUSED')]
fn test_begin_migration_rejects_second_attempt() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = deploy_market();
    let admin: ContractAddress = 10.try_into().unwrap();
    let strk: ContractAddress = 30.try_into().unwrap();
    let threshold: u256 = 15_000_000_000_000_000_000_000;

    mock_call(token, selector!("transfer_from"), true, 1);
    mock_call(strk, selector!("transfer_from"), true, 1);

    start_cheat_caller_address(address, admin);
    market.create_market(token, 1000, threshold);
    market.begin_migration(token);
    market.begin_migration(token);
}



#[test]
#[should_panic(expected: 'MARKET_PAUSED')]
fn test_buy_rejects_paused_market() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = seed_test_market(token);
    let admin: ContractAddress = 10.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.pause_market(token);

    start_cheat_caller_address(address, user);
    market.buy(token, 100, 0);
}

#[test]
#[should_panic(expected: 'MARKET_PAUSED')]
fn test_sell_rejects_paused_market() {
    let token: ContractAddress = 40.try_into().unwrap();
    let (market, address) = seed_test_market(token);
    let admin: ContractAddress = 10.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();

    start_cheat_caller_address(address, admin);
    market.pause_market(token);

    start_cheat_caller_address(address, user);
    market.sell(token, 100, 0);
}
