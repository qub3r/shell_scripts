#!/usr/bin/env bash

main() {
    print_status -l "Process 1"
    sleep 1
    print_status -l "Process 1" -r "FINISH"
    echo

    print_status -c "-" -l "Process 2"
    sleep 1
    print_status -c "-" -l "Process 2" -r "FAIL"
    echo
}

print_status() {
    # parse function args
    while [ -n "$1" ] ; do
        case "$1" in
            -c) local PAD_CHARACTER="$2"    ; shift 2 ;;
            -l) local LEFT_MESSAGE="$2"     ; shift 2 ;;
            -r) local RIGHT_MESSAGE="$2"    ; shift 2 ;;
            -p) local PAD_LENGTH="$2"       ; shift 2 ;;
            *)  return 1 ;;
        esac
    done

    # process args and set defaults
    : ${LEFT_MESSAGE:?print_status() requires the -l flag}
    local PAD_CHARACTER=${PAD_CHARACTER:-.}
    local PAD_LENGTH=${PAD_LENGTH:-80}

    # construct line
    local MPAD_LENGTH=$(( $PAD_LENGTH - ${#LEFT_MESSAGE} - ${#RIGHT_MESSAGE} ))
    local STATUS_MPAD=$(printf -- "${PAD_CHARACTER}%.0s" $(seq -s ' ' 1 ${MPAD_LENGTH}))

    printf -- "%s%s%s\r" "$LEFT_MESSAGE" "$STATUS_MPAD" "$RIGHT_MESSAGE"
}

main "$@"
