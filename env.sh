#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/.env* 1>/dev/null 2>&1 || true # source any optional/hidden env config files first if available
source $(dirname ${BASH_SOURCE[0]})/configuration.env.sh # source main configuration file
