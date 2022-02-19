ExtractRectangleFromRaster <- function(
  RasterFilePath,
  NorthWest_Lat_EPSG4326,
  NorthWest_Lon_EPSG4326,
  SouthEast_Lat_EPSG4326,
  SouthEast_Lon_EPSG4326
) {
  
  library(raster)
  library(exactextractr)
  library(sp)

  
  #Read MyRasterObject raster file
  if ( !file.exists(RasterFilePath) ) {
    stop("!file.exists(RasterFilePath) ")
  }
  MyRasterObject <- raster(RasterFilePath)
  
  
  #Prepare rectangle and reproject to MyRasterObject CRS
  Lon <- c(NorthWest_Lon_EPSG4326, SouthEast_Lon_EPSG4326, SouthEast_Lon_EPSG4326, NorthWest_Lon_EPSG4326, NorthWest_Lon_EPSG4326)
  Lat <- c(NorthWest_Lat_EPSG4326, NorthWest_Lat_EPSG4326, SouthEast_Lat_EPSG4326, SouthEast_Lat_EPSG4326, NorthWest_Lat_EPSG4326)
  tmp <- sp::Polygon(cbind(Lon,Lat))
  tmp <- sp::Polygons(list(tmp), ID = "MyFirstPolygon")
  spPolygonsRectangle = SpatialPolygons(list(tmp))
  proj4string(spPolygonsRectangle) = CRS("+init=epsg:4326")
  #Reproject to MyRasterObject CRS
  spPolygonsRectangle_Reproj <- sp::spTransform(
    x = spPolygonsRectangle,
    CRSobj = raster::crs(MyRasterObject)
  )
  
  #Extract data
  #exactextractr::exact_extract is 100x faster than raster:extract
  Extracted <- exactextractr::exact_extract(
    x = MyRasterObject,
    y = spPolygonsRectangle_Reproj
  )

  #Aggregate number of cells per cell value
  CellCount <- as.data.frame(Extracted[[1]]) %>%
    rename(
      grid_code = value
    ) %>%
    group_by(grid_code) %>%
    summarise(
      nCells = sum(coverage_fraction)
    ) %>%
    ungroup()
  
  return(CellCount)
}
