use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::{ContractAddress, contract_address_const};
use wowo_launchpad::wowo_bonding_curve::{
    IWowoBondingCurveDispatcher,
    IWowoBondingCurveDispatcherTrait,
};

fn deploy_curve() -> IWowoBondingCurveDispatcher {
    let admin: ContractAddress = contract_address_const::<'admin'>();

    let contract = declare("WowoBondingCurve")
        .unwrap()
        .contract_class();

    let constructor_calldata = array![admin.into()];
    let (contract_address, _) = contract
        .deploy(@constructor_calldata)
        .unwrap();

    IWowoBondingCurveDispatcher { contract_address }
}

#[test]
fn test_get_price() {
    let dispatcher = deploy_curve();
    let price = dispatcher.get_price(1000, 500, 100);
    assert(price == 50, 'WRONG_PRICE');
}

#[test]
fn test_get_buy_cost() {
    let dispatcher = deploy_curve();
    let cost = dispatcher.get_buy_cost(1000, 500, 100);
    assert(cost == 55, 'WRONG_BUY_COST');
}

#[test]
fn test_get_sell_return() {
    let dispatcher = deploy_curve();
    let amount = dispatcher.get_sell_return(1000, 500, 100);
    assert(amount == 45, 'WRONG_SELL_RETURN');
}
