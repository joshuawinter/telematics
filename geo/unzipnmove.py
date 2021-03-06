#!/usr/bin/env python

###jwp 08/12/2013
###bigdata poc
###convert shp files to sql and load into postgres gis db"

import tarfile, os, sys, shutil, subprocess


rootdir = '/home/n0083510/workspace/telematics/geo/testharness/'
dstdir = rootdir+'ZShapeFiles/'
sqldir = rootdir+'ZSqlFiles/'
bpath = '/usr/pgsql-9.2/bin/'
shpfile = 'Streets.shp'
shpfiles = ['Streets.shp','Streets.cpg','Streets.dbf','Streets.prj']##,'Streets.shx']
dbname = 'geodata'
dbuser = 'postgres'

abbr  = ['AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN', \
'IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM', \
'NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY']

for dirs in sorted(os.listdir(rootdir)):
	##print dirs[:2]

	for gzs in os.listdir(rootdir+dirs+'/'):
		if gzs.endswith('.gz'):
			##print gzs	
			f = tarfile.open(rootdir+dirs+'/'+gzs,'r:gz') 
			##print gzs.name
			for files in shpfiles:
				f.extract(files, rootdir+'/'+dirs)
			f.close()
			
	if os.path.exists(rootdir+dirs+'/'+shpfile):
		for st in abbr:
			if st == dirs[:2]:
				i = st
				##print st
				for files in shpfiles:
					shutil.copy(rootdir+dirs +'/' + shpfile, dstdir + i +'_' + files)
				
				cmd1 = bpath + "shp2pgsql -s 4326 -d -S -I -G " + dstdir + i +"_" + shpfile +  \
				" > " + sqldir + i + "_streets.sql"
				print cmd1
				'''
				p = subprocess.Popen(cmd1, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				cmdout, err = p.communicate()
				'''
				cmd2 = bpath + "psql -d " + dbname + " -U " + dbuser + " -f " + sqldir + i + "_streets.sql"
				print cmd2
				'''
				p = subprocess.Popen(cmd2, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				cmdout, err = p.communicate()
				'''


			

				

			





