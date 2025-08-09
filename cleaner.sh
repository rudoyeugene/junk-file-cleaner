#!/bin/bash

while true; do
  # Check if the LOCATIONS variable is set
  if [ -z "$LOCATIONS" ]; then
      echo "Error: LOCATIONS environment variable is not set. Nothing will be cleaned."
      exit 1
  fi

  # Number of days after which files are considered "old". Default to 30 days.
  RETENTION_DAYS=${RETENTION_DAYS:-30}
  echo "Files older than $RETENTION_DAYS days will be removed."

  # File extensions to target. If empty, all files are considered.
  # Example: "*.log,*.bak"
  EXTENSIONS=${EXTENSIONS:-}

  FIND_NAME_EXPRESSION=""
  if [ -n "$EXTENSIONS" ]; then
      echo "Filtering by extensions: $EXTENSIONS"
      IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
      FIRST=true
      for EXT in "${EXT_ARRAY[@]}"; do
          if [ "$FIRST" = true ]; then
              FIND_NAME_EXPRESSION="-name \"$EXT\""
              FIRST=false
          else
              FIND_NAME_EXPRESSION="$FIND_NAME_EXPRESSION -o -name \"$EXT\""
          fi
      done
      FIND_NAME_EXPRESSION="\\( $FIND_NAME_EXPRESSION \\)"
      # If there's only one extension, it will be like -name "*.log"
      # If multiple, it will be like \( -name "*.log" -o -name "*.bak" \)
  fi

  # Iterate through each location, separated by commas
  IFS=',' read -ra ADDR <<< "$LOCATIONS"
  for LOCATION_PATH in "${ADDR[@]}"; do
      echo "--- Starting cleanup for: $LOCATION_PATH ---"

      if [ ! -d "$LOCATION_PATH" ]; then
          echo "Warning: Directory $LOCATION_PATH does not exist or is not accessible. Skipping."
          continue
      fi

      echo "Searching for files older than $RETENTION_DAYS days in $LOCATION_PATH..."

      # Construct the find command dynamically
      FIND_COMMAND="find \"$LOCATION_PATH\" -type f"
      if [ -n "$FIND_NAME_EXPRESSION" ]; then
          FIND_COMMAND="$FIND_COMMAND $FIND_NAME_EXPRESSION"
      fi
      FIND_COMMAND="$FIND_COMMAND -mtime +$RETENTION_DAYS -print -delete"

      echo "Executing: $FIND_COMMAND"
      eval $FIND_COMMAND

      if [ "$CLEANUP_EMPTY_DIRS" = "true" ]; then
          echo "Deleting empty directories in $LOCATION_PATH..."
          # -depth: process directory contents before the directory itself
          # -empty: only empty directories
          # -print -delete: print the directory path and then delete it
          find "$LOCATION_PATH" -type d -empty -print -delete
      else
          echo "Skipping removal of empty directories in $LOCATION_PATH (CLEANUP_EMPTY_DIRS is not 'true')."
      fi

      echo "--- Cleanup for $LOCATION_PATH completed. ---"
  done

  echo "All specified locations processed."
  sleep "$REPEAT_EVERY"
done
