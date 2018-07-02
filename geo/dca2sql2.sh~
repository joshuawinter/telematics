#!/bin/bash

if [ $# != 3 ]
then
	echo "Usage: dca_path historical_path table_name"
	exit -1
fi
BPATH=/usr/pgsql-9.2/bin
UTILS_PATH=$(cd $(dirname $0) && pwd)
DCA_PATH=$1
HIST_PATH=$2
TABLE_PREFIX=$3

function read_ini()
{
	local _inifile=$1
	local _key=$2
	if [ ! -r $_inifile ]
	then
		echo "file '$_inifile' is not found"
		exit 1
	fi

	exec < $_inifile

	IFS='='
	while read key value; do
		if [ $key = $_key ];
		then
			echo $value
			exit 0;
		fi
	done
	echo "key '$_key' is not found"
	exit 2;
}

val=`read_ini $UTILS_PATH/dbConfig.ini user`
if [ $? != 0 ]; then echo "Error: $val"; exit -1; else DB_USER=$val; fi
val=`read_ini $UTILS_PATH/dbConfig.ini dbname`
if [ $? != 0 ]; then echo "Error: $val"; exit -1; else DB_NAME=$val; fi

echo "Creating table '"$TABLE_PREFIX"_streets'"
$BPATH/shp2pgsql -s 4326 -d -S -I -G $DCA_PATH/Streets.shp $TABLE_PREFIX"_streets" > $DCA_PATH/_streets.sql
$BPATH/psql -d $DB_NAME -U $DB_USER -f $DCA_PATH/_streets.sql 1> /dev/null
unlink $DCA_PATH/_streets.sql

echo "Creating table cdms"
$UTILS_PATH/pgdbf $DCA_PATH/Cdms.dbf | $BPATH/psql -d $DB_NAME -U $DB_USER
$BPATH/psql -d $DB_NAME -U $DB_USER -c "ALTER TABLE Cdms RENAME TO $TABLE_PREFIX"_Cdms";"

echo "Creating table rdms"
$UTILS_PATH/pgdbf $DCA_PATH/Rdms.dbf | $BPATH/psql -d $DB_NAME -U $DB_USER
$BPATH/psql -d $DB_NAME -U $DB_USER -c "ALTER TABLE Rdms RENAME TO $TABLE_PREFIX"_Rdms";"

echo "Creating table timezone1"
$UTILS_PATH/pgdbf $DCA_PATH/MtdArea.dbf | $BPATH/psql -d $DB_NAME -U $DB_USERE
$BPATH/psql -d $DB_NAME -U $DB_USER -c "ALTER TABLE MtdArea RENAME TO $TABLE_PREFIX"_MtdArea";"

echo "Creating table timezone2"
$UTILS_PATH/pgdbf $DCA_PATH/MtdDST.dbf | $BPATH/psql -d $DB_NAME -U $DB_USER
$BPATH/psql -d $DB_NAME -U $DB_USER -c "ALTER TABLE MtdDST RENAME TO $TABLE_PREFIX"_MtdDST";"

:'
function create_historical_table()
{
	echo "Creating table "historical_"$1"
	$UTILS_PATH/historical $DCA_PATH/Traffic.dbf $HIST_PATH/USA_$1.csv $TABLE_PREFIX"_historical_"$1
}
create_historical_table "mr"
create_historical_table "f"
create_historical_table "ss"
'

function create_table_index()
{
	echo "Creating index '"$2"' for table '"$1"'"
	$BPATH/psql -d $DB_NAME -U $DB_USER -c 'CREATE INDEX '$1'_'$2'_idx ON '$1' USING hash ('$2')'
}

create_table_index $TABLE_PREFIX"_streets" "link_id"
create_table_index $TABLE_PREFIX"_streets" "nref_in_id"
create_table_index $TABLE_PREFIX"_streets" "ref_in_id"
create_table_index $TABLE_PREFIX"_cdms" "link_id"
create_table_index $TABLE_PREFIX"_rdms" "link_id"
create_table_index $TABLE_PREFIX"_MtdArea" "area_id"
create_table_index $TABLE_PREFIX"_MtdDST" "area_id"

:'
create_table_index $TABLE_PREFIX"_historical_mr" "link_id"
create_table_index $TABLE_PREFIX"_historical_f" "link_id"
create_table_index $TABLE_PREFIX"_historical_ss" "link_id"
'

echo "Update table 'dca'"
$BPATH/psql -d $DB_NAME -U $DB_USER -c "INSERT INTO dca (name, table_prefix) VALUES ('$TABLE_PREFIX', '$TABLE_PREFIX')"
$BPATH/psql -d $DB_NAME -U $DB_USER -c "UPDATE dca SET bbox = ( SELECT st_extent( st_geomfromwkb( st_asbinary(geog) ) ) FROM "$TABLE_PREFIX"_streets ) WHERE table_prefix = '$TABLE_PREFIX'"

