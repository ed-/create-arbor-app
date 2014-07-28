#!/bin/bash

function get_planfile () {
  local URL=$1
  shift
  local USER_REPO=${URL#https://github.com/}
  USER_REPO=${USER_REPO%.git}
  local PLANFILE_URL="https://api.github.com/repos/$USER_REPO/contents/planfile.yaml"
  local PLANFILE_TMP=$(tempfile -p arbor -s .yaml)
  local CMD="import base64, json, sys; print base64.b64decode(json.loads(sys.stdin.read())['content'])"
  wget -q $PLANFILE_URL -O- | python -c "$CMD" > $PLANFILE_TMP
  echo $PLANFILE_TMP
}

function create_plan () {
  local PLANFILE=$1
  shift
  solum app create $PLANFILE | awk '/^\| uri / { print $4; }'
}

function create_assembly () {
  local APP_NAME=$1
  shift
  local PLANFILE=$1
  shift
  solum assembly create $APP_NAME $PLANFILE | awk '/\| uuid / { print $4; }'
}

if [ $# -lt 2 ]; then
  echo Usage: $0 APP_NAME GIT_URL >&2
  exit 1
fi

APP_NAME=$1
shift

GIT_URL=$1
shift

PLANFILE=$(get_planfile $GIT_URL)
PLAN_URI=$(create_plan $PLANFILE)
ASSEMBLY_ID=$(create_assembly $APP_NAME $PLAN_URI)

echo Successfully created application $ASSEMBLY_ID
