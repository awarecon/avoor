#!/bin/bash
MOUNTPOINT=/media/backup
BACKUPDIR=$(date +%b-%d-%y)
ARCHIVEPATH=/media/backup/mailsbackup
AVPATH=/home/vmail/vmail1/avoornetworks.com
SOURCE=/home/shared

mount UUID=da02a621-2f12-41ce-9d64-1099d084a210 ${MOUNTPOINT}

if ! [ -e ${MOUNTPOINT}/dummy ]
then
        echo "Backup disk not connected on `date`" >> /var/www/logs/didnothappen
        echo "Backup disk not connected on `date`" | mail -s "Backup disk notification" redalert@aware.co.in
        exit
fi

/etc/init.d/postfix stop
/etc/init.d/crond stop
killall fetchmail

mkdir ${ARCHIVEPATH}/${BACKUPDIR}

mkdir -p ${ARCHIVEPATH}/${BACKUPDIR}/avoor/{receive,sent}

find ${AVPATH} -type d -name "*received*" > /tmp/avreceivelist
find ${AVPATH} -type d -name "*sent*" > /tmp/avsentlist

for i in `cat /tmp/avreceivelist`
do
        j=`echo ${i} | awk -F"/" '{print $9}' | cut -f 1 -d"-"`
        cd ${i}
        tar -pcvzf ${j}-received-Maildir.tar.gz Maildir
        rsync -av --stats ${j}-received-Maildir.tar.gz ${ARCHIVEPATH}/${BACKUPDIR}/avoor/receive/
        rm ${j}-received-Maildir.tar.gz
        rm ${i}/Maildir/new/*
        rm ${i}/Maildir/cur/*
        rm ${i}/Maildir/tmp/*
done

for i in `cat /tmp/avsentlist`
do
        j=`echo ${i} | awk -F"/" '{print $9}' | cut -f 1 -d"-"`
        cd ${i}
        tar -pcvzf ${j}-sent-Maildir.tar.gz Maildir
        rsync -av --stats ${j}-sent-Maildir.tar.gz ${ARCHIVEPATH}/${BACKUPDIR}/avoor/sent/
        rm ${j}-sent-Maildir.tar.gz
        rm ${i}/Maildir/new/*
        rm ${i}/Maildir/cur/*
        rm ${i}/Maildir/tmp/*
done

/etc/init.d/postfix start
/etc/init.d/crond start
rsync --stats -av --numeric-ids --delete /etc/ /media/backup/etcbackup/ > /media/backup/etcbackup/etcsync.log
echo "Monthly backup successfully completed at Avoor Consultants" | mail -s "Avoor backup" support@aware.co.in


if [ -d $MOUNTPOINT/backup.5 ]
then
        rm -rf $MOUNTPOINT/backup.5
fi

# now, shift the middle backups
if [ -d $MOUNTPOINT/backup.4 ]
then
        mv $MOUNTPOINT/backup.4 $MOUNTPOINT/backup.5
fi

if [ -d $MOUNTPOINT/backup.3 ]
then
        mv $MOUNTPOINT/backup.3 $MOUNTPOINT/backup.4
fi

if [ -d $MOUNTPOINT/backup.2 ]
then
        mv $MOUNTPOINT/backup.2 $MOUNTPOINT/backup.3
fi

if [ -d $MOUNTPOINT/backup.1 ]
then
        mv $MOUNTPOINT/backup.1 $MOUNTPOINT/backup.2
fi


# make a hard link copy of latest snapshot
if [ -d $MOUNTPOINT/backup.0 ]
then
        cp -al $MOUNTPOINT/backup.0 $MOUNTPOINT/backup.1
fi

rsync --stats -av --numeric-ids --delete ${SOURCE} ${MOUNTPOINT}/backup.0/ > /var/www/logs/sync-`date +%F`.log

umount ${MOUNTPOINT}
