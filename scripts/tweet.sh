#!/bin/bash

#########################################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#########################################################################

if [ -z $CONSUMER_KEY ]; then
	echo -e "CONSUMER_KEY not defined"
	exit 1
elif [ -z $CONSUMER_SECRET ]; then
	echo -e "CONSUMER_SECRET not defined"
	exit 1
elif [ -z $ACCESS_TOKEN ]; then
	echo -e "ACCESS_TOKEN not defined"
	exit 1
elif [ -z $ACCESS_TOKEN_SECRET ]; then
	echo -e "ACCESS_TOKEN_SECRET not defined"
	exit 1
fi

#########################################################################

die() {
    echo -e "$1"
    exit 1
}

# urlencode() by https://gist.github.com/cdown/1163649
urlencode() {
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

#########################################################################

# Get the text from stdin if we have no parameters
if [ "$#" -eq 0 ]; then
    if [ -t 0 ]; then
        echo "Input the tweet content:"
    fi

    read -r stdin
    set -- "$stdin"
fi

# Check that we actually have something to send and it's less than
# 280 characters

if [ -z "$1" ]; then
    die 'Cannot send an empty tweet!'
fi

#echo "$(expr length "$1")"
#if [ $(expr length "$1") -gt 280 ]; then
#    die 'Tweet is more than 280 characters long!'
#fi

URL_POST='https://api.twitter.com/1.1/statuses/update.json'

# Gather the data that will be needed to sign and send the request
declare -A params
params=(
    ["oauth_consumer_key"]="$(urlencode "$CONSUMER_KEY")"
    ["oauth_nonce"]="$(urlencode "$(head -c32 /dev/urandom | base64)")"
    ["oauth_signature_method"]="$(urlencode 'HMAC-SHA1')"
    ["oauth_timestamp"]="$(date +%s)"
    ["oauth_token"]="$(urlencode "$ACCESS_TOKEN")"
    ["oauth_version"]="$(urlencode '1.0')"
    ["status"]="$(urlencode "$1")"
)

# Another array to iterate the parameters in alphabetial order
declare -a params_order
params_order=("oauth_consumer_key" "oauth_nonce" "oauth_signature_method" "oauth_timestamp" "oauth_token" "oauth_version" "status")

# Generate the string that will be signed
params_string=""

for param in "${params_order[@]}"; do
    if ! [ -z "$params_string" ]; then
        params_string+='&'
    fi

    params_string+="$param=${params[$param]}"
done

signature_string="POST&"
signature_string+="$(urlencode "$URL_POST")&"
signature_string+="$(urlencode "$params_string")"

# Generate the signing key
sign_key="$(urlencode "$CONSUMER_SECRET")&$(urlencode "$ACCESS_TOKEN_SECRET")"

# Get the signature
signature="$(echo -n "$signature_string" | openssl dgst -binary -sha1 -hmac "$sign_key" | base64)"

# Generate the OAuth Authorization header
oauth_header=""

for param in "${params_order[@]}"; do
    if [ "$param" != "status" ]; then
        if ! [ -z "$oauth_header" ]; then
            oauth_header+=', '
        fi

        oauth_header+="$param=\"${params[$param]}\""
    fi
done

oauth_header="OAuth $oauth_header, oauth_signature=\"$(urlencode "$signature")\""

curl_output=$(curl -X POST -w '\n%{http_code}' -d "status=${params["status"]}" "$URL_POST" --header "Content-Type: application/x-www-form-urlencoded" --header "Authorization: $oauth_header" 2>/dev/null)

resp_data=()
while read -r line; do
    resp_data+=("$line")
done <<< "$curl_output"

if [ "${resp_data[1]}" -ne 200 ]; then
    die "POST to Twitter API failed (HTTP code ${resp_data[1]}):\n${resp_data[0]}"
fi