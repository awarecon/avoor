#!/bin/bash
MOUNTPOINT=/media/backup

mount UUID=da02a621-2f12-41ce-9d64-1099d084a210 ${MOUNTPOINT}
mysqldump -h 5.5.5.7 --all-databases > ${MOUNTPOINT}/dbdump/mysqldump.sql_`date +%b-%d-%y`

umount ${MOUNTPOINT}
