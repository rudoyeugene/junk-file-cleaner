# junk-file-cleaner
## As simple as possible:
* runs by cron schedule as per **SCHEDULE**
* searching the junks in **LOCATIONS**: "/archive,/logs"
  * which you must also mount with volumes 
* then removes all the files older than **RETENTION_DAYS**
* or only the files with **EXTENSIONS**: "*.log,*.tmp"

#### Created because of lack of any kind of housekeeping functionality on home NAS by QNAP: such as old syslogs, HDD scans, etc.