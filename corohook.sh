#!/bin/bash
# Coro API Hook

# Predefined Vars
MY_BASE=$(basename $0)
MY_DIR=$( readlink -f $(dirname $0) )
LOG_FILE="${MY_DIR}/corohook.log"
info() { echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO]  $*" | tee -a "$LOG_FILE" >&2 ; }
warn() { echo "$(date "+%Y-%m-%d %H:%M:%S") [WARN]  $*" | tee -a "$LOG_FILE" >&2 ; }
error() { echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*" | tee -a "$LOG_FILE" >&2 ; }
fatal() { echo "$(date "+%Y-%m-%d %H:%M:%S") [FATAL] $*" | tee -a "$LOG_FILE" >&2 ; exit 255 ; }

# Usage
func_usage() {
    cat <<EOF

    ./${MY_BASE} -W <WORKSPACE_ID> -A <TARGET> [-E <ENDPOINT>][-T][-h][-d][-c <CONFIG>][-t <TOKENCONF>]

    Required Arguments:

    -A     REQUIRED: API Action (eg. "v1/workspaces")
    -W     REQUIRED: Workspace ID

    Optional Arguments:

    -h     Print this help/usage info
    -d     Enable Debug (set -x)
    -c     Use a specific configuration file
    -t     Use a specific token configuration file
    -E     Target endpoint (default: https://api.secure.coro.net)
    -T     Re/generate the token configuration file
    -O     Send JSON Output to File

    References:
      * Coro Public API:  https://developers.coro.net/openapi/reference/overview/

EOF
}

# DEFAULT VARIABLES
CONF_API="${MY_DIR}/api.conf"
CONF_TOKEN="${MY_DIR}/api_token.conf"
TARGET_ENDPOINT="https://api.secure.coro.net"
GET_NEW_TOKEN="N"

# Options/Args
while getopts A:hdtc:t:E:TW:O: opt
do
    case $opt in
	h)
	    func_usage
	    exit 0
	    ;;
	d)
	    set -x
	    info "DEBUG ENABLED"
	    ;;
	c)
	    CONF_API="${OPTARG}"
	    info "Using configuration ${OPTARG}"
	    ;;
	t)
	    CONF_TOKEN="${OPTARG}"
	    info "Using token config ${OPTARG}"
	    ;;
	E)
	    TARGET_ENDPOINT="${OPTARG}"
	    info "Using \"${OPTARG}\" as the target endpoint."
	    ;;
	A)
	    API_ACTION="${OPTARG}"
	    ;;
	T)
	    info "Generating/updating new token"
	    GET_NEW_TOKEN="Y"
	    ;;
	W)
	    WORKSPACEID="${OPTARG}"
	    info "Using Workspace ID ${OPTARG}"
	    ;;
	O)
	    OUTPUTFILE="${OPTARG}"
	    info "Outputting to file \"${OPTARG}\""
	    ;;
	*)
	    fatal "Invalid Argument ${OPTARG}"
	    ;;
    esac
done

# Preflight checks
## Check for Config
if [ -f ${CONF_API} ]
then
    info "Using configuration (${CONF_API})"
    source ${CONF_API}
else
    fatal "Configuration does not exist"
fi

FUNC_TOKEN_GET() {
    TOKEN_JSON="$(curl -s -f -X POST "${TARGET_ENDPOINT}/oauth/token" -H "Content-Type: application/json" -d "{\"client_id\": \"${CLID}\", \"client_secret\": \"${CLSECRET}\", \"audience\": \"${TARGET_ENDPOINT}\", \"grant_type\": \"client_credentials\"}")"
    TOKEN_JSON_EXIT="$?"
    if [[ ${TOKEN_JSON_EXIT} == 22 ]] ; then
	fatal "cURL died and broke.  Check credentials maybe?"
    fi
    NEW_TOKEN="$(echo "${TOKEN_JSON}" | jq '.access_token' -r)"
    NEW_TOKEN_EXPIRE="$(echo "${TOKEN_JSON}" | jq '.expires_in' -r)"
    EXPIRE_TIME="$(date +%s --date="+${NEW_TOKEN_EXPIRES} seconds")"
    echo "#!/bin/bash" > ${CONF_TOKEN}
    echo "# This file is generated automatically." >> ${CONF_TOKEN}
    echo "API_TOKEN=\"${NEW_TOKEN}\"" >> ${CONF_TOKEN}
    echo "TOKEN_EXPIRE=\"${EXPIRE_TIME}\"" >> ${CONF_TOKEN}
    info "Got new token, generated new config @ ${CONF_TOKEN}"
}

# Are we getting a new token?
if [[ ${GET_NEW_TOKEN} == "Y" ]] ; then
    FUNC_TOKEN_GET
    exit 0
fi

## Check for token config
if [ -f ${CONF_TOKEN} ]
then
    info "Using token config ${CONF_TOKEN}"
    source ${CONF_TOKEN}
    CURTIMEMIN60="$(date +%s --date="-60 seconds")"
    if [[ ${CURTIMEMIN60} > ${TOKEN_EXPIRE} ]] ; then
	info "Token is almost expired.  Getting a new one..."
	FUNC_TOKEN_GET
    fi
else
    fatal "Token config does not exist (${CONF_TOKEN})"
fi

# Check workspace ID set
if [ -z ${WORKSPACEID} ] ; then
    fatal "Workspace not set."
fi

## Check for any action given?
if [ -z ${API_ACTION} ]
then
    fatal "API Action/Target was not set.  What are we hitting?"
else
    info "Targeting \"${API_ACTION}\""
    if [ ! -z ${OUTPUTFILE} ] ; then
	curl -s -f -X GET "${TARGET_ENDPOINT}/${API_ACTION}" -H "Authorization: Bearer ${API_TOKEN}" -H "Workspace: ${WORKSPACEID}" > ${OUTPUTFILE}
	CURLEXIT="$?"
	info "Output sent to file ${OUTPUTFILE}"
    else
	curl -s -f -X GET "${TARGET_ENDPOINT}/${API_ACTION}" -H "Authorization: Bearer ${API_TOKEN}" -H "Workspace: ${WORKSPACEID}" | jq '.'
	CURLEXIT="$?"
    fi
    if [ ${CURLEXIT} == "22" ] ; then
	fatal "cURL had an error?"
    fi
fi
