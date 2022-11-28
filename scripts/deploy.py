from brownie import SCAiPES, accounts

def main():
    # Deploy
    account = accounts.load('goerli_account')
    address = SCAiPES.deploy({'from': account})

    # Verify
    contract = SCAiPES.at(address)
    SCAiPES.publish_source(contract)
