import xarray as xr
import numpy as np
import os
from datetime import datetime
import pandas as pd
import geopandas as gpd
#import rioxarray
os.environ['PROJ_LIB'] = '/Users/udistrobach/miniconda3/envs/xmitgcm/share/proj'
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from shapely.geometry import Polygon


a = gpd.read_file('agri/AgriParcelsForDashboard.shp')
# there are four kinds of wheat fields in the shp file: 
# (a) wheat for grains
# (b) wheat for leafs
# (c) wheat for hay
# (d) wheat for silage
# The next line selects the polygons of these four wheat fields
b=a[(a['GrowthName']=='חיטה לגרעינים') |
    (a['GrowthName']=='חיטה לעלים') |
    (a['GrowthName']=='חיטה לשחת') |
    (a['GrowthName']=='חיטה לתחמיץ')  ]
c=b.dissolve()

#read grid information
x=xr.open_dataset("geo_em.d02.nc")
nlat,nlon=x.LANDMASK[0].shape # size of domain
lat=x.XLAT_M[0,:,0].values # latitudes
lon=x.XLONG_M[0,0,:].values # longitudes

#create empty array
FR = xr.DataArray(data=np.zeros((nlat,nlon)), dims=["lat", "lon"],
    coords=dict(
        lon=lon,
        lat=lat) )

#get the area of the polygons
df1 = gpd.GeoDataFrame({'geometry': c.geometry, 'df1':[1], 'area': c.area})
# for each of the WRF grid cells I am chosing the for corners lats and longs and put them
# in coords. Then I calculate the overlap with the wheat polygons:
for i in range(0,nlon):
    for j in range(0,nlat):
        if x.LANDMASK[0][j,i]==1:
            # coordinates of the corners of the  WRF grid polygon
            coords=((x.XLONG_U[:,j,i].values,x.XLAT_V[:,j,i].values),
                    (x.XLONG_U[:,j,i].values,x.XLAT_V[:,j+1,i].values),
                    (x.XLONG_U[:,j,i+1].values,x.XLAT_V[:,j+1,i].values),
                    (x.XLONG_U[:,j,i+1].values,x.XLAT_V[:,j,i].values),
                    (x.XLONG_U[:,j,i].values,x.XLAT_V[:,j,i].values))
            P=Polygon(coords)
            df2 = gpd.GeoDataFrame({'geometry': P, 'df2':[1]})
            df2["area"]=df2.area
            df2.crs=("EPSG:4326") # lat-lon coordinates
            df2=df2.to_crs(df1.crs)

            uni=gpd.overlay(df1,df2, how='intersection')
            if uni.empty:
                FR[j,i]=0
            else:
                FR[j,i]=(uni.area.values/df2.area.values)[0]
        else:
            FR[j,i]=0
        print(str(i)+" "+str(j)+" : "+str(FR[j,i].values))

FR.to_netcdf('FR.nc')

##########################################################################################
# plotting the output
##########################################################################################

fig = plt.figure(figsize=(5,6),dpi=500)

m = Basemap(projection='cyl', resolution='h',lon_0=35, \
            llcrnrlon=34,llcrnrlat=31,urcrnrlon=36.0,urcrnrlat=33.5)
s=0.75
fontsize=8

levels=np.arange(0,0.66,0.01)
cs=m.contourf(x.XLONG_M[0].values,x.XLAT_M[0].values,FR.values,
                       levels=levels,cmap=plt.get_cmap('gist_earth_r'))
#ax.set_title('')

cbar=plt.colorbar(shrink=s,spacing='proportional',
                  orientation="horizontal",pad=0.05,ticks=levels[::10])
cbar.ax.set_xlabel(r'Wheat fractional area',size=10,color='k')
#cbar.set_ticks(levels[::10])

m.drawcoastlines()
m.drawparallels(np.arange(29.5,34.,.5),labels=[1,0,0,0],textcolor='k',fontsize=fontsize,linewidth=0.5)
m.drawmeridians(np.arange(34.,40.,.5),labels=[0,0,0,1],textcolor='k',fontsize=fontsize,linewidth=0.5)

gdf = gpd.read_file('border/border01.shp')
gdf2=gdf.to_crs("EPSG:4326")
gdf3=gdf2.iloc[[3,4,6,7,8,9,10]].dissolve() # Israel + PA
gdf4=gdf2.iloc[[3,4,7,8,9,10]].dissolve() # Israel

xy=np.array(gdf3.iloc[0].geometry.exterior.coords.xy)
lon=xy[0,:]
lat=xy[1,:]

xy=np.array(gdf4.iloc[0].geometry.exterior.coords.xy)
lon2=xy[0,:]
lat2=xy[1,:]

x1, y1 = m(lon, lat)
x2, y2 = m(lon2, lat2)
m.plot(x1, y1, '-k', markersize=5, linewidth=0.5)
m.plot(x2, y2, '-k', markersize=5, linewidth=0.5) 

plt.savefig("wheat.png")




            
