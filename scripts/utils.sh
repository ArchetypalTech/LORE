
# usage: export VALUE=${get_profile_env(dev, env_name)}
get_profile_env () {
  local PROFILE=$1
  local ENV_NAME=$2
  local PROFILE_FILE_PATH="./dojo_$PROFILE.toml"
  local RESULT=$(toml get $PROFILE_FILE_PATH --raw env.$ENV_NAME)
  if [[ -z "$RESULT" ]]; then # if not set
    >&2 echo "get_profile_env($PROFILE, $ENV_NAME) not found! 👎"
  fi
  echo $RESULT
}

# usage: export ADDRESS=${get_contract_address(dev, tag)}
get_contract_address () {
  local PROFILE=$1
  local TAG=$2
  local MANIFEST_FILE_PATH="./manifest_$PROFILE.json"
  if [ ! -f "$MANIFEST_FILE_PATH" ]; then
    echo ">> Waiting for manifest file... [${MANIFEST_FILE_PATH}]"
    wait-on $MANIFEST_FILE_PATH
  fi
  # jqn syntax:
  # https://www.npmjs.com/package/jq.node
  # cat manifest_dev.json | npx jqn "get('contracts') | filter(['tag','lore-prompt']) | map('address') | thru(a => a.join(''))"
  local RESULT=$(cat $MANIFEST_FILE_PATH | jqn "get('contracts') | filter(['tag','$TAG']) | map('address') | thru(a => a.join(''))")
  if [[ -z "$RESULT" ]]; then # if not set
    >&2 echo "get_contract_address($PROFILE, $TAG) not found! 👎"
  fi
  echo $RESULT
}
