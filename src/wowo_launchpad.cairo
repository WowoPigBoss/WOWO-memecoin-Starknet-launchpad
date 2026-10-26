#[starknet::contract]
mod WowoLaunchpad {
    use openzeppelin::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc20::SafeERC20DispatcherTrait;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
            wowo_token: ContractAddress,
        strk_token: ContractAddress,
                treasury: ContractAddress,
                    fee_strk: u256,
                        wowo_per_strk: u256,
                            admin: ContractAddress,
    }

    #[constructor]
    fn constructor(
            ref self: ContractState,
                wowo_token: ContractAddress,
        strk_token: ContractAddress,
                    treasury: ContractAddress,
                        fee_strk: u256,
                            wowo_per_strk: u256,
                                admin: ContractAddress,
    ) {
            self.wowo_token.write(wowo_token);
        self.strk_token.write(strk_token);
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
        assert(new_rate > 0, 'INVALID_RATE');
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

    #[external(v0)]
    fn pay_fee_strk(self: @ContractState) {
        let sender = get_caller_address();
        let fee = (self.fee_strk.read() * 110_u256 + 99_u256) / 100_u256;
        let strk = IERC20Dispatcher {
            contract_address: self.strk_token.read()
        };
        strk.assert_transfer_from(sender, self.treasury.read(), fee);
    }

}
