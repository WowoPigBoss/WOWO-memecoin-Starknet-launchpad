use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::ContractAddress;
use starknet::contract_address_const;

use wowo_launchpad::wowo_amm_pool::{
    IWowoAmmPoolDispatcher, IWowoAmmPoolDispatcherTrait
};

#[test]
fn test_pool_initial_state() {
    let token0: ContractAddress = contract_address_const::<111>();
    let token1: ContractAddress = contract_address_const::<222>();

    let contract = declare("WowoAmmPool").unwrap().contract_class();
    let calldata = array![token0.into(), token1.into()];
    let (address, _) = contract.deploy(@calldata).unwrap();

    let pool = IWowoAmmPoolDispatcher { contract_address: address };

    assert(pool.get_token0() == token0, 'TOKEN0_MISMATCH');
    assert(pool.get_token1() == token1, 'TOKEN1_MISMATCH');

    let (reserve0, reserve1) = pool.get_reserves();
    assert(reserve0 == 0, 'RESERVE0_NOT_ZERO');
    assert(reserve1 == 0, 'RESERVE1_NOT_ZERO');
}
