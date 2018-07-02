#!/bin/bash

if [ "$(id -u)" != "0" ]
then
	echo "This script must be run as root"
	exit 1
fi

if [ $# != 2 ] 
then 
    echo "Usage: user_name work_path"
    exit -1
fi

USER_NAME=$1
WORK_PATH=$2

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

if [ ! -d $WORK_PATH/ToMapMatch ]; then echo "Path '$WORK_PATH/ToMapMatch' is not found"; exit -1; fi
if [ ! -d $WORK_PATH/ToScore ];    then echo "Path '$WORK_PATH/ToScore' is not found"; exit -1; fi
if [ ! -d $WORK_PATH/MapMatched ]; then echo "Path '$WORK_PATH/MapMatched' is not found"; exit -1; fi
if [ ! -d $WORK_PATH/Scored ];     then echo "Path '$WORK_PATH/Scored' is not found"; exit -1; fi

chmod 755 $UTILS_PATH/dca2sql.sh
chmod 755 $UTILS_PATH/dbf2sql
chmod 755 $UTILS_PATH/historical
chmod 755 $UTILS_PATH/timetable
chmod -R 0777 $UTILS_PATH
chmod -R 0777 $GEODATA_PATH
chmod -R 0777 $HIST_PATH
chmod -R 0777 $WORK_PATH

function create_folder()
{
    sudo -u $USER_NAME mkdir -p $1;
    if [ ! -d $1 ]; then exit -1; fi    
}
	
create_folder $WORK_PATH/Archived
create_folder $WORK_PATH/Processed
create_folder $WORK_PATH/TempFiles
create_folder $WORK_PATH/Utils

cp $UTILS_PATH/dbConfig.ini $WORK_PATH/Utils
cp $UTILS_PATH/monitoring $WORK_PATH/Utils
cp $UTILS_PATH/scoring $WORK_PATH/Utils
cp $UTILS_PATH/snapping $WORK_PATH/Utils

chmod 666 $WORK_PATH/Utils/dbConfig.ini
chmod 755 $WORK_PATH/Utils/monitoring
chmod 755 $WORK_PATH/Utils/scoring
chmod 755 $WORK_PATH/Utils/snapping

if [ -r $UTILS_PATH/VIDList_all.txt ]
then 
    cp $UTILS_PATH/VIDList_all.txt $WORK_PATH/Utils
    chmod 666 $WORK_PATH/Utils/VIDList_all.txt
fi

echo "program_path=$WORK_PATH/Utils" > $WORK_PATH/Utils/dmnConfig.ini
echo "local_path=$WORK_PATH" >> $WORK_PATH/Utils/dmnConfig.ini
    
echo ""
echo "### DOWNLOAD PG-RPM FILE ###"
wget http://yum.postgresql.org/9.0/redhat/rhel-5-i386/pgdg-centos90-9.0-5.noarch.rpm
rpm -i pgdg-centos90-9.0-5.noarch.rpm
unlink pgdg-centos90-9.0-5.noarch.rpm
echo ""
echo "### INSTALL POSTGRESQL & POSTGIS ###"
yum install postgresql90.i386 postgresql90-devel.i386 postgresql90-server.i386 postgresql90-libs.i386 postgis90.i386 postgis90-debuginfo.i386 postgis90-docs.i386 postgis90-utils.i386
GIS_FILE1=/usr/pgsql-9.0/share/contrib/postgis-1.5/postgis.sql
GIS_FILE2=/usr/pgsql-9.0/share/contrib/postgis-1.5/spatial_ref_sys.sql
if [ ! -r $GIS_FILE1 ]; then echo "Error: File '$GIS_FILE1' is not found"; exit -1; fi
if [ ! -r $GIS_FILE2 ]; then echo "Error: File '$GIS_FILE2' is not found"; exit -1; fi
echo ""
echo "### START POSTGRESQL SERVICE ###"
/etc/init.d/postgresql-9.0 initdb
/etc/init.d/postgresql-9.0 start
echo ""
echo "### CREATE USER AND DATABASE FOR POSTGRESQL ###"
sudo -u postgres psql -c "DROP DATABASE $DB_NAME" 1> /dev/null 2> /dev/null
sudo -u postgres psql -c "DROP USER $USER_NAME" 1> /dev/null 2> /dev/null
sudo -u postgres psql -c "CREATE USER $USER_NAME WITH CREATEDB CREATEUSER PASSWORD '$PASSWORD'" 2> /dev/null
sudo -u $USER_NAME createdb $DB_NAME -E 'LATIN1' -O $USER_NAME 2> /dev/null
sudo -u $USER_NAME psql -d $DB_NAME -f $GIS_FILE1 1> /dev/null 2> $UTILS_PATH/errors.txt
sudo -u $USER_NAME psql -d $DB_NAME -f $GIS_FILE2 1> /dev/null 2> $UTILS_PATH/errors.txt
echo ""
echo "### INSTALL MAP DATA TO DATABASE ###"
sudo -u $USER_NAME psql -d $DB_NAME -c 'CREATE TABLE dca ("id" SERIAL PRIMARY KEY, "name" VARCHAR(50) NOT NULL, "table_prefix" VARCHAR(10) NOT NULL UNIQUE, "bbox" BOX2D NULL )'
for i in $GEODATA_PATH/*
do
sudo -u $USER_NAME $UTILS_PATH/dca2sql.sh $i $HIST_PATH ${i:(1+${#GEODATA_PATH})}
done
sudo -u $USER_NAME /$WORK_PATH/Utils/monitoring
