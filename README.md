# ExtractRectangleFromRaster
R code to extract a rectangular area from a raster file.

 - Works for single-layer raster files with discrete grid values, e.g. for land cover maps. Returns the number of grid cells per grid value covered by the rectangle.
 - Can easily be adapted to raster maps of floating point values (e.g. precipitation amount) by changing to the aggregation function in the extraction function call.

Example call:

```
GridCodeCounts <- ExtractRectangleFromRaster(
    RasterFilePath = PathToMyRasterFile,
    NorthWest_Lat_EPSG4326 = 53.486955540968104,
    NorthWest_Lon_EPSG4326 = 9.277421704336476,
    SouthEast_Lat_EPSG4326 = 53.34844327692954,
    SouthEast_Lon_EPSG4326 = 9.62381416065174
  )
```
