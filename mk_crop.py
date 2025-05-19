# Script to rectify certain vegetation data and include
# fractional cropland distribution, in the wrfinput_d02
# (2nd domain only in my case) required to initialize wrf.exe

from netCDF4 import Dataset
import numpy as np
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Cropland fractional distribution from FR.nc:
fraction = Dataset('FR.nc','r',format='NETCDF4')
FR = fraction.variables['__xarray_dataarray_variable__'][:]

# Reading the following wrfinput variables - 
# CROPTYPE, LU_INDEX, IVGTYP, PLANTING, HARVEST :
wrfinput = Dataset('wrfinput_d02','r+',format='NETCDF4')
CROPTYPE = wrfinput.variables['CROPTYPE'][0,0,:,:]
LU_INDEX = wrfinput.variables['LU_INDEX'][0,:,:]
IVGTYP = wrfinput.variables['IVGTYP'][0,:,:]
PLANTING = wrfinput.variables['PLANTING'][0,:,:]
HARVEST = wrfinput.variables['HARVEST'][0,:,:]


# Modifying those variables
CROPTYPE[:, :] = np.where((FR > 0.1) | (LU_INDEX == 12), True, False)
LU_INDEX[:,:]=np.where(FR > 0.1, 12, LU_INDEX)
IVGTYP[:,:]=np.where(FR > 0.1, 12, IVGTYP)
PLANTING[:,:]=335 
HARVEST[:,:]=152

wrfinput.variables['LU_INDEX'][0, :, :] = LU_INDEX[:,:]
wrfinput.variables['CROPTYPE'][0,0,:,:] = CROPTYPE[:,:]           # for crop type = 1
wrfinput.variables['CROPTYPE'][0,4,:,:] = CROPTYPE[:,:]           # for crop type = 5
wrfinput.variables['IVGTYP'][0, :, :] = IVGTYP[:,:]
wrfinput.variables['HARVEST'][0,:,:]=HARVEST[:,:]
wrfinput.variables['PLANTING'][0,:,:]=PLANTING[:,:]

# Initializing croptype  LAI = 0 because it was showing some initial LAI
LAI = wrfinput.variables['LAI'][0, :, :]
LAI[:, :] = np.where(CROPTYPE == 1, False, LAI)

wrfinput.variables['LAI'][0, :, :] = LAI

wrfinput.close()
fraction.close()



############## (commented codes) ####################

# When FR > 0, set:
# 1. IVGTYP & LU_INDEX = 12 (cropland)
# 2. CROPTYPE[0,0,:,:] = 1, else 0.

# lat_indices, lon_indices = np.where(FR > 0)
# IVGTYP[lat_indices, lon_indices] = 12
# LU_INDEX[lat_indices, lon_indices] = 12
# CROPTYPE[lat_indices, lon_indices] = 1

######################################################
