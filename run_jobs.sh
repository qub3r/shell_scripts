#!/usr/bin/env bash

# if nothing else, die cleanly
trap "exit" INT TERM
trap "echo ; kill 0" EXIT

USAGE="$(cat << EOF
usage:
  bash $(basename "$0") [commands] [options]

commands:
  dev
    Turns on full execution display mode. This will 
    output every command (to stdout) executed by
    this script. This will get messy and is generally
    only useful when you are modifying the script.

options:
  NOTE: All option values should be quoted.

  -c|--command "some command to execute"
    A command to be executed on every file in
    the input-directory.
    REQUIRED=True  DEFAULT=None

  -i|--intput-directory "/full/path/to/directory"
    The directory with files to be processed.
    REQUIRED=True  DEFAULT=None

  -j|--jobs "INTEGER"
    The number of jobs you want to run in the background. 
    REQUIRED=False  DEFAULT=1

  -l|--log-level "(debug|info|warning|error|critical)"
    Only output log data >= the log-level specified.
    REQUIRED=False  DEFAULT=warning

  -o|--output-directory "/full/path/to/directory"
    The directory to place output from the 
    executed command.
    REQUIRED=False  DEFAULT=/dev/null

  -h|--help
    Print this help document.

  -e|--execute
    Tells the script to execute the command
    instead of printing them to stdout.
    REQUIRED=False  DEFAULT=NA

example:
  bash $(basename "$0") -i "/data/files" -o "/tmp" -c "head -n 5 {{file}}"
  bash $(basename "$0") -i "/data/files" -o "/tmp" -c "head -n 5 {{file}}" --execute
  bash $(basename "$0") -i "/data/files" -c "bash {{file}}" --jobs "4" --execute
EOF
)"

main() {
  [ "$1" == "dev" ] && shift 1 && set -x
  parse_args "$@"

  QUEUE=( $(ls "$INPUT_DIRECTORY") )

  local INDEX="0"
  # stay in the while loop as long as there are still jobs in the
  # queue or there are still jobs running.
  while [ -n "${QUEUE[$INDEX]}" -o "$(jobs -r | wc -l)" -gt 0 ]; do

    # if there are still jobs in the queue and the running job count
    # drops below the desired job count, run the next job in the queue.
    if [ -n "${QUEUE[$INDEX]}" -a "$(jobs -r | wc -l)" -lt "$DESIRED_JOBS" ]; then

      # replace {{file}} with the current item in the queue.
      RUN_CMD="$(printf "%s" "$RUN_COMMAND" | sed "s@{{file}}@${INPUT_DIRECTORY}/${QUEUE[$INDEX]}@g")"

      # set output for command
      if [ -n "$OUTPUT_DIRECTORY" ]; then
        OUTPUT="> ${OUTPUT_DIRECTORY}/${QUEUE[$INDEX]}.stdout.log 2> ${OUTPUT_DIRECTORY}/${QUEUE[$INDEX]}.stderr.log"
      else
        OUTPUT="> /dev/null 2>&1"
      fi

      # build run command
      RUN_CMD="$(printf "( %s %s ) &" "$RUN_CMD" "$OUTPUT")"

      # if execute mode is true, run the command, otherwise log the command though would be run
      if [ "$EXECUTE" == "true" ]; then
        eval "$RUN_CMD"
      else
        log "info" "command to be executed $RUN_CMD"
      fi
      INDEX="$(($INDEX + 1))"
    fi

    # update the status spinner
    progress_bar "$(( 100 * $(($INDEX - $(jobs -r | wc -l))) / ${#QUEUE[@]}))"
    sleep 1
  done
  progress_bar "done"
}

parse_args() {
  while [ -n "$1" ]; do
    case "$1" in
      -c|--command) RUN_COMMAND="$2" && shift 2 ;;
      -e|--execute) EXECUTE="true" && shift 1 ;;
      -h|--help) printf "\n%s\n" "$USAGE" && end 0 ;;
      -i|--intput-directory) 
        INPUT_DIRECTORY="$2"
        [ ! -d "$INPUT_DIRECTORY" ] && log "error" "the input directory $INPUT_DIRECTORY does not exist!" && end 2
        shift 2
        ;;
      -j|--jobs) DESIRED_JOBS="$2" && shift 2 ;;
      -l|--log-level) 
        case "$(printf "$2" | tr "[:upper:]" "[:lower:]")" in
          debug)    LOG_LEVEL="4" && shift 2 ;;
          info)     LOG_LEVEL="3" && shift 2 ;;
          warning)  LOG_LEVEL="2" && shift 2 ;;
          error)    LOG_LEVEL="1" && shift 2 ;;
          critical) LOG_LEVEL="0" && shift 2 ;;
          *)        LOG_LEVEL="2" && shift 2 ;;
        esac
        ;;
      -o|--output-directory)
        OUTPUT_DIRECTORY="$2"
        [ ! -d "$OUTPUT_DIRECTORY" ] && log "error" "the output directory $OUTPUT_DIRECTORY does not exist!" && end 2
        shift 2
        ;;
      *) log "error" "the $1 flag is not recognised." && end 2 ;;
    esac
  done
  [ -z "$RUN_COMMAND" ] && log "error" "the -c|--command option is required!" && end 2
  [ -z "$INPUT_DIRECTORY" ] && log "error" "the -i|--input-directory option is required!" && end 2
  DESIRED_JOBS="${DESIRED_JOBS:-1}"
  LOG_LEVEL="${LOG_LEVEL:-2}"
}

progress_bar() {
  if [ "$1" == "done" ]; then
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
  #printf "\n%.0s" {1..100}
  printf "\r Progress: [%s%s] %s %s" \
    "$done_bar" \
    "$none_bar" \
    "${spinner:x++%${#spinner}:1}" \
    "$progress_message"
}

log() {
  case "$1" in
    debug)     [ "$LOG_LEVEL" -ge "4" ] && local log_type="DEBUG"     && local log_message="$2" ;;
    info)      [ "$LOG_LEVEL" -ge "3" ] && local log_type="INFO"      && local log_message="$2" ;;
    warning)   [ "$LOG_LEVEL" -ge "2" ] && local log_type="WARNING"   && local log_message="$2" ;;
    error)     [ "$LOG_LEVEL" -ge "1" ] && local log_type="ERROR"     && local log_message="$2" ;;
    critical)  [ "$LOG_LEVEL" -ge "0" ] && local log_type="CRITICAL"  && local log_message="$2" ;;
    *)         [ "$LOG_LEVEL" -ge "3" ] && local log_type="INFO"      && local log_message="$2" ;;
  esac
  [ -n "$log_message" ] && printf "%s %s: %s\n" "$(date -u +%Y-%m-%d:%H:%M:%S.%N)" "$log_type" "$log_message" >> "/tmp/$(basename $0).log"
}

end() {
  case "$1" in
    0) exit 0 ;; # exit successfully
    1) exit 1 ;; # exit with internal error
    2) printf "\n%s\n" "$USAGE" && exit 2 ;; # exit with user error
    *) exit 1 ;; # default exit with internal error
  esac
}

main "$@"
