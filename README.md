# Goblin Bank

The Goblin Bank is a vault that helps you earn a higher return on your cryptocurrency by analyzing and allocating your assets across multiple yield markets.

## Application

You can access the Goblin Bank at: [thegoblins.finance](thegoblins.finance)

Documentation is available at: [docs.thegoblins.finance](docs.thegoblins.finance)

## Dependencies

Install foundry deps:

`forge install`

## Tests

To run all tests against each token: `./forge_test.sh`

To run specific tests against a specific token:
1. Set the base token you want to run the tests against in `./forge_testbench.sh`.
2. Run `./forge_testbench.sh`

### **Environment variables**

Please create directory `environment/variables/` in which you will add evi.

Required env vars for deployments:

```
RPC_URL=
SNOWTRACE_API_KEY=
TIMELOCK_ADDRESS=
OWNER_ADDRESS=
MANAGER_ADDRESS=
DEPLOYER_ADDRESS=
DEPLOYER_PRIVATE_KEY=
```

In order to deploy locally with anvil, you can use this dummy configuration (relative file path: `environment/variables/public/env_localhost.sh`): 
```
export RPC_URL=http://localhost:8545
#prod addresses
export TIMELOCK_ADDRESS=XXXXXXXXXXXXXXXX
export OWNER_ADDRESS=XXXXXXXXXXXXXXXX
export MANAGER_ADDRESS=XXXXXXXXXXXXXXXX
export DEX_ADDRESS=XXXXXXXXXXXXXXXX

ETHERSCAN_API_KEY=

# anvil default test account #1
export DEPLOYER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**NOTICE:** please use your own ETHERSCAN_API_KEY.

Note that the EnvData.s.sol script file reads environment variables if they exist. When run locally, the .env file is sourced before the execution of any script so they are always present. On the other hand, the github action does not source the .env before running the tests because it does not have access to it.   
So the environment variables are used if they exist otherwise default values are used (this is how regular tests are run). In test environment `makeAddr(OWNER)` and `makeAddr(MANAGER)` are used to pull the configuration.

### **Deployment/Update script**

To deploy/update smart contract use `./forge_infra.sh` script.

usage of `./forge_infra.sh` (more examples in the script file):
```
./forge_infra.sh [action] [asset] [dest_env] [optinal_resume]
example:   
./forge_infra.sh deploy btcb localhost 
```

## Access Control

There are 4 roles defined: 
- `ADMIN_ROLE`
- `MANAGER_ROLE`
- `PANICOOOR_ROLE`
- `PRIVATE_ACCESS_ROLE`

The `ADMIN_ROLE` is held by 48-hours Timelock smart contract.

The `MANAGER_ROLE` is held by the Manager Multisig and Timelock. MANAGER_ROLE allows the team to operate the protocol and adjust certain parameters such as the module allocation.

The `PANICOOOR_ROLE` is held by Manager Multisig and TimeLock. It will be also given to off-chain app monitoring the health of the protocol and potential attacks. This role gives ability pause the contract (all interactions including withdrawals), contract can be resumed by MANAGER_ROLE accounts. 

The `PRIVATE_ACCESS_ROLE` is held by restricted set of accounts who can interact with the smart contract (IMPORTANT: this role is set only for private deployment)
