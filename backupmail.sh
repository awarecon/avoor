#!/bin/bash
MOUNTPOINT=/media/backup
BACKUPDIR=$(date +%b-%d-%y)
ARCHIVEPATH=/media/backup/mailsbackup
AVPATH=/home/vmail/vmail1/avoornetworks.com

mount UUID=4de4c4a6-c27d-4e85-8021-cc14c59b0a6b ${MOUNTPOINT}

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
umount ${MOUNTPOINT}
