#!/bin/bash

# Check if the SCHEDULE variable is set
if [ -z "$SCHEDULE" ]; then
    echo "Error: SCHEDULE environment variable is not set. No cleanup will be scheduled."
    echo "Running cleanup script ONCE, without a schedule."
    /cleaner.sh
    # Keep the container running, but without a cron job
    tail -f /dev/null
else
    # Create the cron file
    echo "$SCHEDULE /cleanup_script.sh" > /etc/crontabs/root > /proc/1/fd/1 2>&1
    echo "Cron job configured: $SCHEDULE /cleanup_script.sh"

    # Start the cron daemon in the foreground
    echo "Starting cron daemon..."
    crond -f
fi
