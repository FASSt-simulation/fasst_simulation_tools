#! /usr/bin/env python3
#######
#  NOTES:
#
#
#
# Authors: Shawn P. Serbin
# Adapted from original source provided by Andy Fox
#
######

#  Import libraries
import sys
import os,argparse
from os.path import expanduser,basename
from getpass import getuser
import string
import subprocess
import configparser
import numpy as np
import xarray as xr

def mprint(mstr):
    vnum=sys.version_info[0]
    if vnum == 3:
        print(mstr)
    if vnum == 2:
        print(mstr)

'''
#------------------------------------------------------------------#
#---------------------  Instructions  -----------------------------#
#------------------------------------------------------------------#
This script is used to derive domain, surface, and datm7 single point
driver files for CLM/ELM and HLM-FATES simulations. The script uses
locally availible CESM driver datasets to extract single X-Y lat/long
locations from the domain, surface, and  
atm_forcing.datm7.GSWP3.0.5d.v1.c170516 source files. To run the 
script, create or modify the provided config.cfg to provide desired 
options.  These include the desired source files for domain
and surface files, as well as other options related to the selected
grid cell, including dominant PFT, PFT fraction, etc.

This script is python3 compliant

More options to come later.
'''

# TODO
# need to switch all path to os.path.join() because it can handle different OS platforms, e.g. Win vs Mac vs Linux
# Make it easy for user-selectable domain/surf files
# allow for other key options
# enable automatic downloading of missing files from CESM source

#####  Set script controls here
#-- setup config file here
parser = argparse.ArgumentParser()
parser.add_argument('--config', help='path to configuration file to use', 
    required=True)
args = parser.parse_args()
print(f'Config file: {args.config}')
config = configparser.ConfigParser()
#config.read("config.cfg")
config_file = args.config
config.read(config_file)
print(" ")

#-- Specify site name
site_name = config.get("sitevars", "site_name")
mprint("Site name: "+site_name)
mprint(" ")

#--  Specify point to extract
plon = float(config.get("sitevars", "plon"))
plat = float(config.get("sitevars", "plat"))

#--  Create regional CLM domain file
create_domain   = eval(config.get("surfacevars", "create_domain"))
#--  Create CLM surface data file
create_surfdata = eval(config.get("surfacevars", "create_surfdata"))
#--  Create CLM land-use data file - doesnt work yet
create_landuse  = eval(config.get("surfacevars", "create_landuse"))
#--  Create single point DATM atmospheric forcing data
create_datm     = eval(config.get("surfacevars", "create_datm"))

#-- what met driver?
met_driver = config.get("drivervars", "met_driver")

#-- What years to generate drivers for?
datm_syr = int(config.get("drivervars", "datm_syr"))
datm_eyr = int(config.get("drivervars", "datm_eyr"))

#--  Modify landunit structure
overwrite_single_pft = eval(config.get("landvars", "overwrite_single_pft"))
dominant_pft         = int(config.get("landvars", "dominant_pft"))
zero_nonveg_pfts     = eval(config.get("landvars", "zero_nonveg_pfts"))
uniform_snowpack     = eval(config.get("landvars", "uniform_snowpack"))
no_saturation_excess = eval(config.get("landvars", "no_saturation_excess"))

#--  Specify input and output directories
cesm_input_datasets = config.get("drivervars", "cesm_input_datasets")
dir_output = config.get("outputvars", "dir_output")

# need to redo this part and not re-use dir_output
dir_output = os.path.join(dir_output,site_name)
os.makedirs(os.path.dirname(dir_output), exist_ok=True)

# -- input datm
dir_input_datm = os.path.join(cesm_input_datasets,'atm/datm7/',met_driver)
dir_output_datm = os.path.join(dir_output,'datmdata',met_driver)
os.makedirs(dir_output_datm, exist_ok=True)

#--  Set input and output filenames
tag=str(plon)+'_'+str(plat)

#--  Set time stamp
command='date "+%y%m%d"'
x2=subprocess.Popen(command,stdout=subprocess.PIPE,shell='True')
x=x2.communicate()
timetag = x[0].strip()

#--  Specify land domain file  ---------------------------------
fdomain  = os.path.join(cesm_input_datasets,'share/domains/',config.get("surfacevars", "fdomain"))
fdomain2 = os.path.join(dir_output, os.path.splitext(basename(fdomain))[0]+'_'+site_name+'.nc')

#--  Specify surface data file  --------------------------------
fsurf = os.path.join(cesm_input_datasets,'lnd/clm2/surfdata_map/',config.get("surfacevars", "fsurf"))
fsurf2 = os.path.join(dir_output,os.path.splitext(basename(fsurf))[0]+'_'+site_name+'.nc')

#--  Specify landuse file  -------------------------------------  NEEDS UPDATING!!
fluse    = os.path.join(cesm_input_datasets,'lnd/clm2/surfdata_map/',config.get("surfacevars", "lufile"))
fluse2   = os.path.join(dir_output,os.path.splitext(basename(fluse))[0]+'_'+site_name+'.nc')

#--  Specify datm domain file  ---------------------------------
fdatmdomain = os.path.join(dir_input_datm,config.get("surfacevars", "fdatmdomain"))
fdatmdomain2  = os.path.join(dir_output_datm, basename(fdatmdomain))

#--  Create CTSM domain file
if create_domain:
    mprint('**** Open '+fdomain)
    f1  = xr.open_dataset(fdomain)
    lon0 = np.asarray(f1['xc'][0,:])
    lat0 = np.asarray(f1['yc'][:,0])
    lon = xr.DataArray(lon0,name='lon',dims='ni',coords={'ni':lon0})
    lat = xr.DataArray(lat0,name='lat',dims='nj',coords={'nj':lat0})
    f2 = f1.assign({'lon':lon,'lat':lat})
    f2 = f2.reset_coords(['xc','yc'])

    # extract gridcell closest to plon/plat
    f3 = f2.sel(ni=plon,nj=plat,method='nearest')

    # expand dimensions
    f3 = f3.expand_dims(['nj','ni'])

    # mode 'w' overwrites file
    print('**** Write domain file to output directory')
    f3.to_netcdf(path=fdomain2, mode='w')
    mprint('created file '+fdomain2)
    f1.close(); f2.close(); f3.close()

#--  Create CTSM surface data file
if create_surfdata:
    mprint('**** Open '+fsurf)
    f1  = xr.load_dataset(fsurf)
    # create 1d variables
    lon0=np.asarray(f1['LONGXY'][0,:])
    lon=xr.DataArray(lon0,name='lon',dims='lsmlon',coords={'lsmlon':lon0})
    lat0=np.asarray(f1['LATIXY'][:,0])
    lat=xr.DataArray(lat0,name='lat',dims='lsmlat',coords={'lsmlat':lat0})
    f2=f1.assign({'lon':lon,'lat':lat})
    # extract gridcell closest to plon/plat
    f3 = f2.sel(lsmlon=plon,lsmlat=plat,method='nearest')
    # expand dimensions
    f3 = f3.expand_dims(['lsmlat','lsmlon'])
 
    # modify surface data properties
    if overwrite_single_pft:
        atemp = f3.PCT_NAT_PFT.attrs
        f3['PCT_NAT_PFT'] = xr.where(f3['PCT_NAT_PFT']>0, 0, 0)
        f3.PCT_NAT_PFT.attrs = atemp
        f3['PCT_NAT_PFT'][:,:,dominant_pft] = 100
        del atemp
    if zero_nonveg_pfts:
        f3.PCT_NATVEG.data = np.array([[100]])
        f3.PCT_CROP.data = np.array([[0]])
        f3.PCT_LAKE.data = np.array([[0.]])
        f3.PCT_WETLAND.data = np.array([[0.]])
        atemp = f3.PCT_URBAN.attrs
        f3['PCT_URBAN'] = xr.where(f3['PCT_URBAN']>0, 0, 0)
        f3.PCT_URBAN.attrs = atemp
        f3.PCT_GLACIER.data = np.array([[0.]])
        del atemp
    if uniform_snowpack:
        f3.STD_ELEV.data = np.array([[20.]])
    if no_saturation_excess:
        f3.FMAX.data = np.array([[0.]])

    # specify dimension order 
    #f3 = f3.transpose(u'time', u'cft', u'natpft', u'lsmlat', u'lsmlon')
    #f3 = f3.transpose('time', 'cft', 'lsmpft', 'natpft', 'nglcec', 'nglcecp1', 'nlevsoi', 'nlevurb', 'numrad', 'numurbl', 'lsmlat', 'lsmlon')
    f3 = f3.transpose('time', 'lsmpft', 'natpft', 'nglcec', 'nglcecp1', 'nlevsoi', 'nlevurb', 'numrad', 'numurbl', 'lsmlat', 'lsmlon')
    # mode 'w' overwrites file
    print('**** Write surfdata file to output directory')
    f3.to_netcdf(path=fsurf2, mode='w')
    mprint('created file '+fsurf2)
    f1.close(); f2.close(); f3.close()

    ''' this is buggy; can't re-write a file within the same session
    # modify new surface data file
    if overwrite_single_pft:
        f1  = xr.open_dataset(fsurf2)
        f1['PCT_NAT_PFT'][:,:,:] = 0
        f1['PCT_NAT_PFT'][:,:,dominant_pft] = 100
        f1.to_netcdf(path='~/junk.nc', mode='w')
        #f1.to_netcdf(path=fsurf2, mode='w')
        f1.close()
    if zero_nonveg_pfts:
        #f1  = xr.open_dataset(fsurf2)
        f1  = xr.open_dataset('~/junk.nc')
        f1['PCT_NATVEG']  = 100
        f1['PCT_CROP']    = 0
        f1['PCT_LAKE']    = 0.
        f1['PCT_WETLAND'] = 0.
        f1['PCT_URBAN']   = 0.
        f1['PCT_GLACIER'] = 0.
        #f1.to_netcdf(path=fsurf2, mode='w')
        f1.to_netcdf(path='~/junk2.nc', mode='w')
        f1.close()
    '''


#--  Create CTSM transient landuse data file
if create_landuse:
    f1  = xr.open_dataset(fluse)
    # create 1d variables
    lon0=np.asarray(f1['LONGXY'][0,:])
    lon=xr.DataArray(lon0,name='lon',dims='lsmlon',coords={'lsmlon':lon0})
    lat0=np.asarray(f1['LATIXY'][:,0])
    lat=xr.DataArray(lat0,name='lat',dims='lsmlat',coords={'lsmlat':lat0})
    f2=f1.assign({'lon':lon,'lat':lat})
    #f2=f1.assign()
    #f2['lon'] = lon
    #f2['lat'] = lat
    # extract gridcell closest to plon/plat
    f3 = f2.sel(lsmlon=plon,lsmlat=plat,method='nearest')

    # expand dimensions
    f3 = f3.expand_dims(['lsmlat','lsmlon'])
    # specify dimension order 
    #f3 = f3.transpose('time','lat','lon')
    f3 = f3.transpose('time', 'cft', 'natpft', 'lsmlat', 'lsmlon')
    #f3['YEAR'] = f3['YEAR'].squeeze()

    # revert expand dimensions of YEAR
    year = np.squeeze(np.asarray(f3['YEAR']))
    x = xr.DataArray(year, coords={'time':f3['time']}, dims='time', name='YEAR')
    x.attrs['units']='unitless'
    x.attrs['long_name']='Year of PFT data'
    f3['YEAR'] = x
    #print(x)
    #mprint(f3)
    #stop
    # mode 'w' overwrites file
    f3.to_netcdf(path=fluse2, mode='w')
    mprint('created file '+fluse2)
    f1.close(); f2.close(); f3.close()

#--  Create single point atmospheric forcing data
if create_datm:
    mprint('**** Open '+fdatmdomain)
    #--  create datm domain file
    f1  = xr.open_dataset(fdatmdomain)
    # create 1d coordinate variables to enable sel() method
    lon0=np.asarray(f1['xc'][0,:])
    lat0=np.asarray(f1['yc'][:,0])
    lon=xr.DataArray(lon0,name='lon',dims='ni',coords={'ni':lon0})
    lat=xr.DataArray(lat0,name='lat',dims='nj',coords={'nj':lat0})

    f2=f1.assign({'lon':lon,'lat':lat})
    f2 = f2.reset_coords(['xc','yc'])

    # extract gridcell closest to plon/plat
    f3 = f2.sel(ni=plon,nj=plat,method='nearest')
    # expand dimensions
    f3 = f3.expand_dims(['nj','ni'])

    # mode 'w' overwrites file
    print('**** Write domain.lnd file to output directory')
    f3.to_netcdf(path=fdatmdomain2, mode='w')
    mprint('created file '+fdatmdomain2)
    f1.close(); f2.close(); f3.close()

    #--  specify subdirectory names and filename prefixes
    solrdir = 'Solar'
    precdir = 'Precip'
    tpqwldir = 'TPHWL'
    # !!! these should be found automatically. Replace this with a command to find the common filenames !!!
    prectag = 'clmforc.GSWP3.c2011.0.5x0.5.Prec.'
    solrtag = 'clmforc.GSWP3.c2011.0.5x0.5.Solr.'
    tpqwtag = 'clmforc.GSWP3.c2011.0.5x0.5.TPQWL.'

    #--  create data files  
    infile=[]
    outfile=[]
    for y in range(datm_syr,datm_eyr+1):
      ystr=str(y)
      for m in range(1,13):
         mstr=str(m) 
         if m < 10:
            mstr='0'+mstr

         dtag=ystr+'-'+mstr

         # setup inputs and create outputs - removed insertion of lat/long into filename to make it easier to use with CLM 
         #fsolar=dir_input_datm+solrdir+solrtag+dtag+'.nc'
         fsolar = os.path.join(dir_input_datm, solrdir, solrtag+dtag+'.nc')
         #fsolar2=dir_output_datm+solrtag+tag+'.'+dtag+'.nc'
         fsolar2 = os.path.join(dir_output_datm,solrdir,solrtag+dtag+'.nc')
         os.makedirs(os.path.dirname(fsolar2), exist_ok=True)
         #fprecip=dir_input_datm+precdir+prectag+dtag+'.nc'
         fprecip = os.path.join(dir_input_datm, precdir, prectag+dtag+'.nc')
         #fprecip2=dir_output_datm+prectag+tag+'.'+dtag+'.nc'
         fprecip2 = os.path.join(dir_output_datm,precdir,prectag+dtag+'.nc')
         os.makedirs(os.path.dirname(fprecip2), exist_ok=True)
         #ftpqw=dir_input_datm+tpqwldir+tpqwtag+dtag+'.nc'
         ftpqw = os.path.join(dir_input_datm, tpqwldir, tpqwtag+dtag+'.nc')
         #ftpqw2=dir_output_datm+tpqwtag+tag+'.'+dtag+'.nc'
         ftpqw2 = os.path.join(dir_output_datm,tpqwldir,tpqwtag+dtag+'.nc')
         os.makedirs(os.path.dirname(ftpqw2), exist_ok=True)

         infile+=[fsolar,fprecip,ftpqw]
         outfile+=[fsolar2,fprecip2,ftpqw2]

    nm=len(infile)
    for n in range(nm):
        mprint(outfile[n]+'\n')
        file_in = infile[n]
        file_out = outfile[n]
    
        f1  = xr.open_dataset(file_in)
        # create 1d coordinate variables to enable sel() method
        lon0=np.asarray(f1['LONGXY'][0,:])
        lat0=np.asarray(f1['LATIXY'][:,0])
        lon=xr.DataArray(lon0,name='lon',dims='lon',coords={'lon':lon0})
        lat=xr.DataArray(lat0,name='lat',dims='lat',coords={'lat':lat0})
        #f2=f1.assign({'lon':lon,'lat':lat})
        f2=f1.assign()
        f2['lon'] = lon
        f2['lat'] = lat
        f2.reset_coords(['LONGXY','LATIXY'])
        # extract gridcell closest to plon/plat
        f3  = f2.sel(lon=plon,lat=plat,method='nearest')
        # expand dimensions
        f3 = f3.expand_dims(['lat','lon'])
        # specify dimension order 
        f3 = f3.transpose('scalar','time','lat','lon')

        # mode 'w' overwrites file
        print('**** Write drivers files to datmdata output directory')
        f3.to_netcdf(path=file_out, mode='w')
        f1.close(); f2.close(); f3.close()

      
    mprint('datm files written to: '+dir_output_datm)