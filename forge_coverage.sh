export BASE_TOKEN_NAME="USDC"

forge coverage --fork-url https://api.avax.network/ext/bc/C/rpc --fork-block-number 25397500 --report lcov --report summary --match-contract "Timelock|GoblinBank|NativeGateway|TraderJoeDex|BaseModule|Stargate|CompoundV2|Aave|Rescuable" -v
