#!/usr/bin/env bash

# usage: ./forge_infra [action] [asset] [dest_env] [optinal_resume]
# if dest env is private add "-private" to dest name, eg.: stage-private
# eg.:   ./forge_infra deploy usdc localhost
# eg.:   ./forge_infra deploy usdc localhost-private
# eg.:   ./forge_infra deploy usdc stage resume
# eg.:   ./forge_infra update usdc localhost
# eg.:   ./forge_infra update usdc prod
# eg.:   ./forge_infra update usdc prod-private

echo "
   _____       _     _ _         ____              _
  / ____|     | |   | (_)       |  _ \            | |
 | |  __  ___ | |__ | |_ _ __   | |_) | __ _ _ __ | | __
 | | |_ |/ _ \| '_ \| | | '_ \  |  _ < / _' | '_ \| |/ /
 | |__| | (_) | |_) | | | | | | | |_) | (_| | | | |   <
  \_____|\___/|_.__/|_|_|_| |_| |____/ \__,_|_| |_|_|\_\


"

set -e # exit if any command will fail

############### Flags and vars #################

resume_flag=""
verify_flag=""
script_name=""

############### Init functions #################


init_dest_env() {
    echo "Init deployment environment vars .."
    _dest_env=$1

    if [[ $_dest_env == "stage" ]]; then
        source ./environment/variables/public/env_stage.sh
    elif [[ $_dest_env == "prod" ]]; then
        source ./environment/variables/public/env_prod.sh
    elif [[ $_dest_env == "localhost" ]]; then
        source ./environment/variables/public/env_localhost.sh
    elif [[ $_dest_env == "stage-private" ]]; then
        source ./environment/variables/private/env_stage.sh
    elif [[ $_dest_env == "prod-private" ]]; then
        source ./environment/variables/private/env_prod.sh
    elif [[ $_dest_env == "localhost-private" ]]; then
        source ./environment/variables/private/env_localhost.sh
    else
     echo "wrong dest environment ❌"
     exit 1
    fi
}

init_asset() {
     echo "Init asset vars .."
    _asset=$1
    if [[ $_asset == "usdc" ]]; then
        export BASE_TOKEN_NAME="USDC"

    else
     echo "wrong asset ❌"
     exit 1
    fi
}

init_flags() {
    echo "Init flags .."
    _optional_resume=$1
    _action=$2

    if [[ $optional_resume == "resume" ]]; then
        resume_flag="--resume"
    fi

    if [[ $action == "deploy" ]]; then
        script_name="script/Deployer.s.sol:Deployer"
        verify_flag="--verify"
    elif [[ $action == "update" ]]; then
        script_name="script/Updatoor.s.sol:Updatoor"
    else
        echo "wrong action name ❌"
        exit 1
    fi

}


################ Main execution ################

action=$1
asset=$2
dest_env=$3
optional_resume=$4


# init variables for deployment environment
init_dest_env $dest_env
# init variables for asset
init_asset $asset
# init flags and vars
init_flags $optional_resume $action

if [[ $dest_env == "localhost" || $dest_env == "localhost-private" ]]; then
    echo "forge script $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$SNOWTRACE_API_KEY --broadcast $resume_flag"
    forge script $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$SNOWTRACE_API_KEY --broadcast $resume_flag -vvv
elif [[ $dest_env == "stage" || $dest_env == "stage-private" ]]; then
    forge script $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$SNOWTRACE_API_KEY --broadcast $verify_flag $resume_flag
elif [[ $dest_env == "prod" || $dest_env == "prod-private" ]]; then
    read -p "Are you sure? " -n 1 -r reply_val
    echo  # (optional) move to a new line
    if [[ ! $reply_val =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi
    forge script $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$SNOWTRACE_API_KEY --broadcast $verify_flag $resume_flag
fi


