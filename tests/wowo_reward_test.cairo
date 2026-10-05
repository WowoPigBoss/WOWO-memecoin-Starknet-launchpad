use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, mock_call, start_cheat_block_timestamp,
    start_cheat_caller_address,
};
use starknet::ContractAddress;

#[starknet::interface]
trait IWowoReward<TState> {
    fn register(ref self: TState);
    fn get_admin(self: @TState) -> ContractAddress;
    fn get_min_balance(self: @TState) -> u256;
    fn get_holding_period(self: @TState) -> u64;
    fn get_daily_rate(self: @TState) -> u256;
    fn get_holding_start(self: @TState, account: ContractAddress) -> u64;
    fn set_daily_rate(ref self: TState, new_rate: u256);
    fn claim_reward(ref self: TState) -> u256;
}

#[test]
fn test_reward_constructor_and_getters() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();

    let reward_pool: u256 = 1_000_000;
    let min_balance: u256 = 10_000;
    let holding_period: u64 = 604_800;
    let daily_rate: u256 = 1000;

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    reward_pool.serialize(ref calldata);
    min_balance.serialize(ref calldata);
    holding_period.serialize(ref calldata);
    daily_rate.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    assert(reward.get_admin() == admin, 'wrong admin');
    assert(reward.get_min_balance() == min_balance, 'wrong min balance');
    assert(reward.get_holding_period() == holding_period, 'wrong period');
    assert(reward.get_daily_rate() == daily_rate, 'wrong daily rate');
    assert(reward.get_holding_start(admin) == 0, 'holding should start at zero');
}

#[test]
fn test_register_holding_start_and_reset() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();
    let holder: ContractAddress = 10.try_into().unwrap();

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    (1_000_000_u256).serialize(ref calldata);
    (10_000_u256).serialize(ref calldata);
    604_800_u64.serialize(ref calldata);
    (1000_u256).serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    start_cheat_caller_address(contract_address, holder);
    start_cheat_block_timestamp(contract_address, 1_000_000);

    mock_call(wowo_token, selector!("balance_of"), 20_000_u256, 1);

    reward.register();

    assert(reward.get_holding_start(holder) == 1_000_000, 'holding start not recorded');

    mock_call(wowo_token, selector!("balance_of"), 5_000_u256, 1);

    reward.register();

    assert(reward.get_holding_start(holder) == 0, 'holding start not reset');
}

#[test]
fn test_holding_period_seven_days() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();
    let holder: ContractAddress = 10.try_into().unwrap();

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    (1_000_000_u256).serialize(ref calldata);
    (10_000_u256).serialize(ref calldata);
    604_800_u64.serialize(ref calldata);
    (1000_u256).serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    start_cheat_caller_address(contract_address, holder);
    start_cheat_block_timestamp(contract_address, 1_000_000);

    mock_call(wowo_token, selector!("balance_of"), 20_000_u256, 1);

    reward.register();

    let start = reward.get_holding_start(holder);

    assert(start == 1_000_000, 'wrong start timestamp');

    start_cheat_block_timestamp(contract_address, 1_604_800);

    let elapsed = 1_604_800 - start;

    assert(elapsed == 604_800, 'seven days not reached');
    assert(elapsed >= reward.get_holding_period(), 'holding period not completed');
}

#[test]
fn test_admin_can_change_daily_rate() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    (1_000_000_u256).serialize(ref calldata);
    (10_000_u256).serialize(ref calldata);
    604_800_u64.serialize(ref calldata);
    (1000_u256).serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    start_cheat_caller_address(contract_address, admin);

    reward.set_daily_rate(500_u256);

    assert(reward.get_daily_rate() == 500_u256, 'daily rate was not changed');
}

#[test]
#[should_panic]
fn test_non_admin_cannot_change_daily_rate() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let user: ContractAddress = 99.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    (1_000_000_u256).serialize(ref calldata);
    (10_000_u256).serialize(ref calldata);
    604_800_u64.serialize(ref calldata);
    (1000_u256).serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    start_cheat_caller_address(contract_address, user);

    reward.set_daily_rate(500_u256);
}

#[test]
fn test_claim_reward_after_seven_days() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let holder: ContractAddress = 99.try_into().unwrap();
    let wowo_token: ContractAddress = 2.try_into().unwrap();
    let reward_token: ContractAddress = 3.try_into().unwrap();

    let contract = declare("WowoReward").unwrap().contract_class();

    let mut calldata = array![];
    admin.serialize(ref calldata);
    wowo_token.serialize(ref calldata);
    reward_token.serialize(ref calldata);
    (1_000_000_u256).serialize(ref calldata);
    (10_000_u256).serialize(ref calldata);
    604_800_u64.serialize(ref calldata);
    (1000_u256).serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let reward = IWowoRewardDispatcher { contract_address };

    start_cheat_caller_address(contract_address, holder);
    start_cheat_block_timestamp(contract_address, 1_000_000);

    mock_call(wowo_token, selector!("balance_of"), 20_000_u256, 2);

    reward.register();

    start_cheat_block_timestamp(contract_address, 1_604_800);

    let amount = reward.claim_reward();

    assert(amount == 70_u256, 'wrong reward amount');
}
