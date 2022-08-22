import subprocess
import re
import os
class GdalRender:
    def __init__(self):
        pass
    def translate(self,nc,):
        exe = "D:/C/vcpkg/packages/gdal_x64-windows/tools/gdal/gdal_translate"
        cmd = f"{exe} {nc}.nc {nc}.tif "
        cmd = f'{exe} -of GTiff "{nc}.nc" "{nc}.tif"'
        cmd = f'{exe} -a_srs EPSG:4326 NETCDF:"{nc}.nc" -of Gtiff {nc}.geotiff'
        print(f"cmd {cmd}")
        subprocess.call(cmd.split())


gdal = GdalRender()
Base = "D:/share/nc/"
file = "ASTGTMV003_N27E088_dem"

gdal.translate(Base + file)

