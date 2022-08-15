import matplotlib.pyplot as plt
import xarray
import os

# Some depencencies in addition to maplotlib and xarray:
# nc-time-axis (allows matplotlib to plot dates correctly from netCDF files)
# cftime (allows xarray to properly convert the noleap calendar that ELM uses)

# This needs to be set to the actual output data file from the Docker run.
# This assumes the files have already been combined with `ncrcat *.h0.*.nc ELM_output.nc` and moved to somewhere accessible from this script
output_file='/home/jovyan/output/cime_run_dirs/OLMT_AK-K64G_ICB20TRCNPRDCTCBC/run/ELM_output.nc'

# Load model output data into xarray format. squeeze removes an empty grid cell dimension assuming this is a single point run
output=xarray.open_dataset(output_file).squeeze()

# Carbon and nitrogen budgets
# Set up a figure with three axes
f,a=plt.subplots(nrows=3,ncols=2,clear=True,num='Carbon budgets',figsize=(8,8))

# Vegetation C
ax=a[0,0]
output['TOTVEGC'].plot(ax=ax,linestyle='-',color='black',label='Total vegetation C')
output['LEAFC'].plot(ax=ax,linestyle='-',color='green',label='Leaf C')
output['FROOTC'].plot(ax=ax,linestyle='-',color='orange',label='Fine root C')
(output['DEADSTEMC']+output['LIVESTEMC']+output['DEADCROOTC']+output['LIVECROOTC']).plot(ax=ax,linestyle='-',color='brown',label='Woody C')
ax.legend()
ax.set(title='Veg carbon pools',xlabel='Year',ylabel='Carbon stock (g C m$^{-2}$)')

# Vegetation N
ax=a[0,1]
output['TOTVEGN'].plot(ax=ax,linestyle='-',color='black',label='Total vegetation C')
output['LEAFN'].plot(ax=ax,linestyle='-',color='green',label='Leaf C')
output['FROOTN'].plot(ax=ax,linestyle='-',color='orange',label='Fine root C')
# This is showing a negative N content for live coarse roots, which seems like a model issue we should check on...
(output['DEADSTEMN']+output['LIVESTEMN']+output['DEADCROOTN']+output['LIVECROOTN']).plot(ax=ax,linestyle='-',color='brown',label='Woody C')
ax.set(title='Veg nitrogen pools',xlabel='Year',ylabel='Nitrogen stock (g N m$^{-2}$)')

# Soil C
ax=a[1,0]
output['TOTSOMC'].plot(ax=ax,label='Soil C')
ax.set(title='Soil C',xlabel='Year',ylabel='Carbon stock (g C m$^{-2}$)')

# Soil N
ax=a[1,1]
output['TOTSOMN'].plot(ax=ax,label='Soil N')
ax.set(title='Soil N',xlabel='Year',ylabel='Nitrogen stock (g C m$^{-2}$)')

# C fluxes. Just plotting 5 years
timerange=slice('2005-01-01','2010-01-01')
ax=a[2,0]
(output['NEE']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='black',label='Net ecosystem exchange')
(output['NPP']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='green',label='Net primary production')
(output['HR']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='brown',label='Ecosystem respiration')
ax.legend()
ax.set(title='C fluxes',xlabel='Year',ylabel='C flux (g C m$^{-2}$ day$^{-1}$)')

# N fluxes
ax=a[2,1]
(output['NET_NMIN']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='blue',label='Net Nmin')
(output['GROSS_NMIN']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='--',color='blue',label='Gross Nmin')
(output['SMINN_TO_PLANT']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='green',label='Plant N uptake')
(output['PLANT_NDEMAND']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='--',color='green',label='Plant N demand')

# Skipping N dep because it's very small
# (output['NDEP_TO_SMINN']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='C0',label='Atmospheric N dep')
(output['NFIX_TO_SMINN']*24*3600).sel(time=timerange).plot(ax=ax,linestyle='-',color='C1',label='N fixation')
ax.legend()
ax.set(title='N fluxes',xlabel='Year',ylabel='N flux (g N m$^{-2}$ day$^{-1}$)')

f.savefig('/home/jovyan/work/C_and_N_budgets.png',dpi=250)

# Soil temperature and freezing
f,a=plt.subplots(nrows=3,num='Soil temperature and ice',clear=True,figsize=(8,8))

timerange=slice('1950-01-01','2010-01-01')
# Decided to skip plotting these for now
# ax=a[0]
# output['ALTMAX'].sel(time=timerange).plot(ax=ax,label='Maximum active layer thickness',color='C1')
# output['ZWT'].sel(time=timerange).plot(ax=ax,label='Water table depth',color='blue')
# output['ZWT_PERCH'].sel(time=timerange).plot(ax=ax,label='Perched water table depth',color='blue',linestyle='--')
# ax.set(title='Active layer and water table',xlabel='Year',ylabel='Depth (m)')
# ax.legend()

ax=a[0]
output['SNOW_DEPTH'].sel(time=timerange).plot(ax=ax,label='Snow depth')
ax.set(title='Snow depth',xlabel='Year',ylabel='Depth (m)')

ax=a[1]
(output['TSOI']-273.15).sel(time=timerange).T.plot(ax=ax,cbar_kwargs={'label':'Soil temperature (C)'},center=0,vmin=-10,vmax=10,cmap='coolwarm')
output['ALTMAX'].sel(time=timerange).plot(ax=ax,label='Maximum active layer thickness',color='k',linestyle=':',linewidth=0.5)
ax.set(title='Soil temperature',xlabel='Year',ylabel='Depth (m)',ylim=(20,0))

ax=a[2]
(output['SOILICE']/(output['SOILLIQ']+output['SOILICE'])).sel(time=timerange).T.plot(ax=ax,cbar_kwargs={'label':'Soil frozen water fraction'},cmap='Blues_r')
ax.set(title='Soil moisture',xlabel='Year',ylabel='Depth (m)',ylim=(3,0))

f.savefig('/home/jovyan/work/Temperature_and_ice.png',dpi=250)

plt.show()