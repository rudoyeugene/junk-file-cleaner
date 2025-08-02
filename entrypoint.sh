#!/bin/bash

# Check if the SCHEDULE variable is set
if [ -z "$SCHEDULE" ]; then
    echo "Error: SCHEDULE environment variable is not set. No cleanup will be scheduled."
    echo "Running cleanup script ONCE, without a schedule."
    /cleanup_script.sh
    # Keep the container running, but without a cron job
    tail -f /dev/null
else
    # Create the cron file
    echo "$SCHEDULE /cleanup_script.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root
    echo "Cron job configured: $SCHEDULE /cleanup_script.sh"

    # Start the cron daemon in the foreground
    echo "Starting cron daemon..."
    crond -f -L /var/log/cron.log
fi
