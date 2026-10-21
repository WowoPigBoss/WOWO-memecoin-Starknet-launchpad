use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;
use openzeppelin::interfaces::erc20::{
    IERC20Dispatcher, IERC20DispatcherTrait,
};
use wowo_launchpad::wowo_bonding_curve_market::{
    IWowoBondingCurveMarketDispatcher,
    IWowoBondingCurveMarketDispatcherTrait,
};

fn deploy_token(
    recipient: ContractAddress,
) -> IERC20Dispatcher {
    let class = declare("TestERC20").unwrap().contract_class();
    let calldata = array![
        recipient.into(), 100_000_u128.into(), 0_u128.into()
    ];
    let (address, _) = class.deploy(@calldata).unwrap();
    IERC20Dispatcher { contract_address: address }
}

fn deploy_market(
    admin: ContractAddress,
    treasury: ContractAddress,
    strk: ContractAddress,
) -> (IWowoBondingCurveMarketDispatcher, ContractAddress) {
    let class = declare("WowoBondingCurveMarket")
        .unwrap().contract_class();
    let calldata = array![admin.into(), treasury.into(), strk.into()];
    let (address, _) = class.deploy(@calldata).unwrap();
    (
        IWowoBondingCurveMarketDispatcher { contract_address: address },
        address
    )
}

#[test]
fn test_real_token_buy_transfers_balances() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();

    let token = deploy_token(admin);
    let strk = deploy_token(admin);
    let (market, market_address) =
        deploy_market(admin, treasury, strk.contract_address);

    start_cheat_caller_address(token.contract_address, admin);
    token.approve(market_address, 1000);
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(strk.contract_address, admin);
    strk.approve(market_address, 500);
    strk.transfer(user, 100);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(market_address, admin);
    market.create_market(token.contract_address, 1000, 500);

    start_cheat_caller_address(strk.contract_address, user);
    strk.approve(market_address, 100);
    stop_cheat_caller_address(strk.contract_address);

    stop_cheat_caller_address(market_address);
    start_cheat_caller_address(market_address, user);
    let out = market.buy(token.contract_address, 100, 165);

    assert(out == 165, 'WRONG_OUTPUT');
    assert(token.balance_of(user) == 165, 'WRONG_USER_TOKEN');
    assert(strk.balance_of(treasury) == 1, 'WRONG_TREASURY_FEE');
    assert(strk.balance_of(market_address) == 599, 'WRONG_MARKET_STRK');
    let (token_reserve, strk_reserve) = market.get_reserves(token.contract_address);
    assert(token_reserve == 835, 'WRONG_TOKEN_RESERVE');
    assert(strk_reserve == 599, 'WRONG_STRK_RESERVE');
}

#[test]
fn test_real_token_sell_transfers_balances() {
    let admin: ContractAddress = 10.try_into().unwrap();
    let treasury: ContractAddress = 20.try_into().unwrap();
    let user: ContractAddress = 50.try_into().unwrap();

    let token = deploy_token(admin);
    let strk = deploy_token(admin);
    let (market, market_address) =
        deploy_market(admin, treasury, strk.contract_address);

    start_cheat_caller_address(token.contract_address, admin);
    token.approve(market_address, 1000);
    token.transfer(user, 500);
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(strk.contract_address, admin);
    strk.approve(market_address, 500);
    stop_cheat_caller_address(strk.contract_address);

    start_cheat_caller_address(market_address, admin);
    market.create_market(token.contract_address, 1000, 500);
    stop_cheat_caller_address(market_address);

    start_cheat_caller_address(token.contract_address, user);
    token.approve(market_address, 500);
    stop_cheat_caller_address(token.contract_address);

    start_cheat_caller_address(market_address, user);
    let out = market.sell(token.contract_address, 500, 165);

    assert(out == 165, 'WRONG_OUTPUT');
    assert(strk.balance_of(user) == 165, 'WRONG_USER_STRK');
    assert(strk.balance_of(treasury) == 1, 'WRONG_TREASURY_FEE');
    assert(strk.balance_of(market_address) == 334, 'WRONG_MARKET_STRK');
    let (token_reserve, strk_reserve) = market.get_reserves(token.contract_address);
    assert(token_reserve == 1500, 'WRONG_TOKEN_RESERVE');
    assert(strk_reserve == 334, 'WRONG_STRK_RESERVE');
}
