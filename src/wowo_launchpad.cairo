#[starknet::contract]
mod WowoLaunchpad {
    use openzeppelin_interfaces::erc20::IERC20Dispatcher;
    use openzeppelin_token::erc20::utils::SafeERC20DispatcherTrait;
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
            wowo_token: ContractAddress,
                treasury: ContractAddress,
                    fee_strk: u256,
                        wowo_per_strk: u256,
                            admin: ContractAddress,
    }

    #[constructor]
    fn constructor(
            ref self: ContractState,
                wowo_token: ContractAddress,
                    treasury: ContractAddress,
                        fee_strk: u256,
                            wowo_per_strk: u256,
                                admin: ContractAddress,
    ) {
            self.wowo_token.write(wowo_token);
                self.treasury.write(treasury);
                    self.fee_strk.write(fee_strk);
                        self.wowo_per_strk.write(wowo_per_strk);
   self.admin.write(admin); }

    #[external(v0)]
    fn get_wowo_token(self: @ContractState) -> ContractAddress {
        self.wowo_token.read()
    }

    #[external(v0)]
    fn get_treasury(self: @ContractState) -> ContractAddress {
        self.treasury.read()
    }
#[external(v0)]
fn get_fee_strk(self: @ContractState) -> u256 {
        self.fee_strk.read()
}

#[external(v0)]
fn get_wowo_per_strk(self: @ContractState) -> u256 {
        self.wowo_per_strk.read()
}
    #[external(v0)]
    fn set_wowo_per_strk(
            ref self: ContractState,
                new_rate: u256,
    ) {
            let caller = get_caller_address();

                assert(caller == self.admin.read(), 'NOT_ADMIN');

                    self.wowo_per_strk.write(new_rate);
    }

#[external(v0)]
fn pay_fee(
        self: @ContractState,
) {
        let sender = get_caller_address();

            let fee_wowo = self.fee_strk.read() * self.wowo_per_strk.read();

                let wowo = IERC20Dispatcher {
                            contract_address: self.wowo_token.read()
                };

                    wowo.assert_transfer_from(
                                sender,
                                        self.treasury.read(),
                                                fee_wowo
                    );
}
            }
