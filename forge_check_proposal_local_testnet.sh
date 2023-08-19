# NOTE: before running that you need to start anvil in other terminal
# anvil --fork-url https://api.avax.network/ext/bc/C/rpc

# File with PUBLIC_KEY, PRIVATE_KEY, SNOWTRACE_API_KEY
source ./environment/variables/public/env_prod.sh

# NOTE: set the asset to test against
export BASE_TOKEN_NAME="BTCB"

forge test --fork-url $RPC_URL --match-contract "ProposalChecker" -vv
