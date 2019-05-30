#!/usr/bin/env bash

main() {
    print_message -M "HEADER MESSAGE"
    echo
    print_message -c "." -m "Section Message"
    echo
}

print_message() {
    # parse function args
    while [ -n "$1" ] ; do
        case "$1" in
            -m|-M)
                [ "$1" == "-m" ] && local TYPE=SECTION || local TYPE=HEADER
                local MESSAGE="   $2   "
                shift 2
                ;;
            -c) local PAD_CHARACTER="$2"    ; shift 2 ;;
            -p) local PAD_LENGTH="$2"       ; shift 2 ;;
            *)  return 1 ;;
        esac
    done

    # process and set defaults
    : ${MESSAGE:?print_message() requires the -m or -M flag}
    local PAD_CHARACTER=${PAD_CHARACTER:-#}
    if [ ! "$PAD_LENGTH" ] ; then
        if [ "$(tput cols)" -gt 120 ] ; then
            PAD_LENGTH=120
        else
            PAD_LENGTH="$(tput cols)"
        fi
    fi

    # construct message
    local LPAD_LENGTH=$(( ( $PAD_LENGTH - ${#MESSAGE} ) / 2 ))
    local RPAD_LENGTH=$(( $PAD_LENGTH - ( $LPAD_LENGTH + ${#MESSAGE} ) ))
    local HEADER_PAD=$(  printf -- "${PAD_CHARACTER}%.0s" $(seq -s ' ' 1 ${PAD_LENGTH} ))
    local MESSAGE_LPAD=$(printf -- "${PAD_CHARACTER}%.0s" $(seq -s ' ' 1 ${LPAD_LENGTH}))
    local MESSAGE_RPAD=$(printf -- "${PAD_CHARACTER}%.0s" $(seq -s ' ' 1 ${RPAD_LENGTH}))

    # print top padding line
    [ "$TYPE" == "HEADER" ] && printf -- "%s\n" "$HEADER_PAD"
    # print message line
    printf -- "%s%s%s\n" "$MESSAGE_LPAD" "$MESSAGE" "$MESSAGE_RPAD"
    # print bottom padding line
    [ "$TYPE" == "HEADER" ] && printf -- "%s\n" "$HEADER_PAD"
}

main "$@"
