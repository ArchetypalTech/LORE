
# usage: export VALUE=${get_profile_env(dev, env_name)}
# get_profile_env () {
#   local PROFILE=$1
#   echo profile: $PROFILE
#   local ENV_NAME=$2
#   echo env: $ENV_NAME
#   local PROFILE_FILE_PATH="./dojo_$PROFILE.toml"
#   echo profile file: $PROFILE_FILE_PATH
#   local RESULT=$(toml get $PROFILE_FILE_PATH --raw env.$ENV_NAME)
#   if [[ -z "$RESULT" ]]; then # if not set
#     >&2 echo "get_profile_env($PROFILE, $ENV_NAME) not found! 👎"
#   fi
#   echo $RESULT
# }
get_profile_env () {
  local PROFILE=$1
  local ENV_NAME=$2
  local FILE="./dojo_${PROFILE}.toml"

  awk -F' *= *' "
    /^\[env\]/ { in_env=1; next }
    /^\[/ { in_env=0 }
    in_env && \$1 == \"${ENV_NAME}\" {
      gsub(/\"/, \"\", \$2)
      print \$2
      exit
    }
  " "$FILE"
}

# usage: export ADDRESS=${get_contract_address(dev, tag)}
# get_contract_address () {
#   local PROFILE=$1
#   local TAG=$2
#   local MANIFEST_FILE_PATH="./manifest_$PROFILE.json"
#   if [ ! -f "$MANIFEST_FILE_PATH" ]; then
#     echo ">> Waiting for manifest file... [${MANIFEST_FILE_PATH}]"
#     wait-on $MANIFEST_FILE_PATH
#   fi
#   # jqn syntax:
#   # https://www.npmjs.com/package/jq.node
#   # cat manifest_dev.json | npx jqn "get('contracts') | filter(['tag','lore-prompt']) | map('address') | thru(a => a.join(''))"
#   local RESULT=$(cat $MANIFEST_FILE_PATH | jqn "get('contracts') | filter(['tag','$TAG']) | map('address') | thru(a => a.join(''))")
#   if [[ -z "$RESULT" ]]; then # if not set
#     >&2 echo "get_contract_address($PROFILE, $TAG) not found! 👎"
#   fi
#   echo $RESULT
# }
get_contract_address () {
  local PROFILE=$1
  local TAG=$2
  local FILE="./manifest_${PROFILE}.json"

  [ -f "$FILE" ] || wait-port "$FILE"

  bun -e "
    const m = require('$FILE');
    const c = m.contracts.find(x => x.tag === '$TAG');
    if (c) process.stdout.write(c.address);
  "
}
