# Coro.net API

Just some hooking against Coro.net API

# Link/Notes

* [KnowledgeBase for API Authentication](https://developers.coro.net/developer-portal/authentication/)
* [Control Panel: Manage API Keys](https://secure.coro.net/portal/settings/connectors/api-keys)

# Initial Setup

1. Rename `api.conf.sample` to `api.conf`
2. Fill in variables for Client ID and Client Secret
3. Generate new token (good for ~24 hours)
4. Get a workspace ID for the target workspace
   * NOTE: Currently, there is no API function for listing workspaces
   * Get workspace IDs from Hovering over your profile and going to "My Workspaces"
5. Start hitting API endpoints

## Generate new Token Config

```
$ ./corohook.sh -T
2024-06-03 13:08:44 [INFO]  Generating/updating new token
2024-06-03 13:08:44 [INFO]  Using configuration (/path/to/git/coro_api_hooking/api.conf)
2024-06-03 13:08:44 [INFO]  Got new token, generated new config @ /path/to/git/coro_api_hooking/api_token.conf
```

# Usage

## Help Usage

```sh
    ./corohook.sh -W <WORKSPACE_ID> -A <TARGET> [-E <ENDPOINT>][-T][-h][-d][-c <CONFIG>][-t <TOKENCONF>]

    -h     Print this help/usage
    -d     Enable Debug (set -x)
    -c     Use a specific configuration file
    -t     Use a specific token configuration file
    -E     Target endpoint (default: https://api.secure.coro.net)
    -A     REQUIRED: API Action (eg. "v1/workspaces)
    -T     Re/generate the token configuration file
    -W     REQUIRED: Workspace ID
    -O     Send JSON Output to File

```

### Example

Example getting devices listing and printing to console:

```sh
$ ./corohook.sh -W exampleWS_92NB_b -A "v1/devices"
2024-06-03 13:05:52 [INFO]  Using Workspace ID exampleWS_92NB_b
2024-06-03 13:05:52 [INFO]  Using configuration (/path/to/coro_api_hooking/api.conf)
2024-06-03 13:05:52 [INFO]  Using token config /path/to/git/coro_api_hooking/api_token.conf
2024-06-03 13:05:52 [INFO]  Token is almost expired.  Getting a new one...
2024-06-03 13:05:52 [INFO]  Got new token, generated new config @ /path/to/git/coro_api_hooking/api_token.conf
2024-06-03 13:05:52 [INFO]  Targeting "v1/devices"
{
  "items": [
    {
      "enrollmentCode": "92NB467876231292",
      "deviceId": "D4EDE84B47B2CD2D2C9333180D9B55673B9C7D48FD9AC2058EDD14B07211AF9F84EAD41C27ED19BBFCBB5AA2425C7C4CAEB3902C8122054019EF82A64AF01F65",
      "deviceModel": "To Be Filled By O.E.M. To Be Filled By O.E.M.",
      "hostname": "DESKTOP-8FDASD",
      "osType": "WINDOWS",
      "osVersion": "10.0.22631",
      "appVersion": "2.5.60.1",
      "activationTime": 1717211190752
    }
  ],
  "totalElements": 1
}
```
