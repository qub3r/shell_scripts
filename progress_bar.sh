#!/usr/bin/env bash

main() {
    local items=80
    for i in $(seq 1 $items) ; do
        printf -v percent -- '%.0f' "$(echo "100 * ($i/$items)" | bc -l)"
        progress_bar "$percent"
        sleep .1
    done
    progress_bar "DONE"
}

progress_bar() {
    if [ "${1,,}" == "done" ]; then
        local spinner="X"
        local percent_done="100"
        local progress_message="Done!"
    else
        local spinner='/-\|'
        local percent_done="${1:-0}"
        local progress_message="$percent_done %"
    fi

    local percent_none="$(( 100 - $percent_done ))"
    [ "$percent_done" -gt 0 ] && local done_bar="$(printf '#%.0s' $(seq -s ' ' 1 $percent_done))"
    [ "$percent_none" -gt 0 ] && local none_bar="$(printf '~%.0s' $(seq -s ' ' 1 $percent_none))"

    # clear the screen
    printf "\r Progress: [%s%s] %s %s" \
            "$done_bar" \
            "$none_bar" \
            "${spinner:x++%${#spinner}:1}" \
            "$progress_message"
}

main "$@"
