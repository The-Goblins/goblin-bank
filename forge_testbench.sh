echo "\n USDC tests \n"
export BASE_TOKEN_NAME="USDC"
forge test --fork-url https://arb-mainnet.g.alchemy.com/v2/YOUR_API_KEY --fork-block-number 114434100 --etherscan-api-key=$SNOWTRACE_API_KEY --mt "testOnlyExecutorCanExecute" -vvvv
