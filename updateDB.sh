#!/bin/bash

if [ "$(id -u)" != "0" ]
then
	echo "This script must be run as root"
	exit 1
fi

if [ $# != 1 ] 
then 
    echo "Usage: user_name"
    exit -1
fi

USER_NAME=$1

UTILS_PATH=$(cd $(dirname $0) && pwd)
ROOT_PATH=${UTILS_PATH:0:(${#UTILS_PATH}-6)}
GEODATA_PATH=$ROOT_PATH/geodata
HIST_PATH=$ROOT_PATH/hist

if [ ! -d $GEODATA_PATH ]; then echo "Path '$GEODATA_PATH' is not found"; exit -1; fi
if [ ! -d $HIST_PATH ]; then echo "Path '$HIST_PATH' is not found"; exit -1; fi

if [ ! $(getent passwd $USER_NAME ) ]; then echo "User '$USER_NAME' does not exist in the system"; exit -1; fi
PASSWORD="password"
DB_NAME="geodata"

INI_FILE=$UTILS_PATH/dbConfig.ini
echo "dbtype=PostgreSQL" > $INI_FILE
echo "host=" >> $INI_FILE
echo "port=" >> $INI_FILE
echo "user=$USER_NAME" >> $INI_FILE
echo "password=$PASSWORD" >> $INI_FILE
echo "dbname=$DB_NAME" >> $INI_FILE

chmod 755 $UTILS_PATH/dca2sql.sh
chmod 755 $UTILS_PATH/dbf2sql
chmod 755 $UTILS_PATH/historical
chmod 755 $UTILS_PATH/timetable
chmod -R 0777 $UTILS_PATH
chmod -R 0777 $GEODATA_PATH
chmod -R 0777 $HIST_PATH

echo ""
echo "### INSTALL MAP DATA TO DATABASE ###"
sudo -u $USER_NAME psql -d $DB_NAME -c 'DELETE FROM dca'
for i in $GEODATA_PATH/*
do
sudo -u $USER_NAME $UTILS_PATH/dca2sql.sh $i $HIST_PATH ${i:(1+${#GEODATA_PATH})}
done
