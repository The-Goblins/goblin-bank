# NOTE: before running that you need to start anvil in other terminal
# anvil --fork-url https://api.avax.network/ext/bc/C/rpc

export RPC_URL=https://rpc.vnet.tenderly.co/devnet/goblin/1df8b6a5-9752-49f8-83d2-f2527b9efe4f
export BLOCK_EXPLORER_API_KEY=fake
# use prod addresses
export TIMELOCK_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export OWNER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export MANAGER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# export DEX_ADDRESS=0x0b5e0Ab0650556827E1EbbD16C9Ee837DaAb12Ef

# goblin bank used to fetch other contract addresses
# export BTCB_GOBLIN_BANK=0x3C390b91Fc2f248E75Cd271e2dAbF7DcC955B1A3

s
# anvil default test account #1, #2, #3
export PRIVATE_DEPLOYMENT_ROLE_ACCOUNTS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8,0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,0x90F79bf6EB2c4f870365E785982E1f101E93b906

# anvil default test account #0
export DEPLOYER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
