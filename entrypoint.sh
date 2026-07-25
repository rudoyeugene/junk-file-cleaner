#!/bin/bash
set -euo pipefail

RETENTION_DAYS=${RETENTION_DAYS:-7} # Changed default retention to 7 days
REPEAT_EVERY=${REPEAT_EVERY:-24h}

# Validate REPEAT_EVERY format (e.g., 10s, 5m, 2h, 1d)
if ! echo "$REPEAT_EVERY" | grep -Eq '^[0-9]+[smhd]$'; then
    echo "Error: Invalid REPEAT_EVERY format. Must be like '10s', '5m', '2h', or '1d'."
    exit 1
fi

# Validate RETENTION_DAYS is a positive integer
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || [ "$RETENTION_DAYS" -le 0 ]; then
    echo "Error: RETENTION_DAYS must be a positive integer."
    exit 1
fi

# Validate LOCATIONS variable and ensure it's not empty
if [ -z "${LOCATIONS:-}" ]; then
    echo "Error: LOCATIONS environment variable is not set. Nothing will be cleaned."
    exit 1
fi

# Signal handling for graceful shutdown in Docker
trap 'echo "Stopping cleaner service..."; exit 0' SIGTERM SIGINT

while true; do
  FORMATTED_DELAY=$(echo "$REPEAT_EVERY" | sed -E 's/([0-9]+)s/\1 seconds/; s/([0-9]+)m/\1 minutes/; s/([0-9]+)h/\1 hours/; s/([0-9]+)d/\1 days/')
  NEXT_RUN=$(date -d "+$FORMATTED_DELAY" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Error calculating next run time. Check REPEAT_EVERY format.")
  echo "================================"
  echo "$(date +'%Y-%m-%d %H:%M:%S')"
  echo "Next run at: $NEXT_RUN"
  echo "Files older than $RETENTION_DAYS days will be removed."

  EXT_ARGS=()
  if [ -n "${EXTENSIONS:-}" ]; then
      echo "Filtering by extensions: $EXTENSIONS"
      IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
      for i in "${!EXT_ARRAY[@]}"; do
          EXT=$(echo "${EXT_ARRAY[$i]}" | xargs)
          if [ $i -gt 0 ]; then
              EXT_ARGS+=("-o")
          fi
          EXT_ARGS+=("-name" "$EXT")
      done
  fi

  # Iterate through each location, separated by commas
  IFS=',' read -ra ADDR <<< "$LOCATIONS"
  for LOCATION_PATH in "${ADDR[@]}"; do
      LOCATION_PATH=$(echo "$LOCATION_PATH" | xargs)
      echo "--- Starting cleanup for: $LOCATION_PATH ---"

      if [ ! -d "$LOCATION_PATH" ]; then
          echo "Warning: Directory '$LOCATION_PATH' does not exist or is not accessible. Skipping cleanup for this path."
          continue
      fi

      echo "Searching for files older than $RETENTION_DAYS days in $LOCATION_PATH..."

      FIND_CMD=("find" "$LOCATION_PATH" "-type" "f")
      if [ ${#EXT_ARGS[@]} -gt 0 ]; then
          FIND_CMD+=("\(" "${EXT_ARGS[@]}" "\)")
      fi
      FIND_CMD+=("-mtime" "+$RETENTION_DAYS" "-print" "-delete")

      echo "Executing cleanup..."
      "${FIND_CMD[@]}"

      if [ "${CLEANUP_EMPTY_DIRS:-}" = "true" ]; then
          echo "Deleting empty subdirectories in $LOCATION_PATH..."
          find "$LOCATION_PATH" -mindepth 1 -type d -empty -print -delete
      elif [ -n "${CLEANUP_EMPTY_DIRS:-}" ]; then # Only show this message if the variable is explicitly set to (not just empty) other than "true"
          echo "Skipping removal of empty directories in $LOCATION_PATH (CLEANUP_EMPTY_DIRS is not 'true')."
      fi

      echo "--- Cleanup for $LOCATION_PATH completed. ---"
  done

  echo "All specified locations processed."
  sleep "$(echo "$REPEAT_EVERY" | sed -E 's/([0-9]+)s/\1/; s/([0-9]+)m/\1*60/; s/([0-9]+)h/\1*3600/; s/([0-9]+)d/\1*86400/' | bc)"
done
