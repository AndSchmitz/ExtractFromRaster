ExtractCircleFromRaster <- function(
    RasterFilePath,
    Center_Lat_EPSG4326,
    Center_Lon_EPSG4326,
    Radius_m
) {
  
  library(raster)
  library(exactextractr)
  library(sp)
  library(sf)

  #This function will extract raster values in radius "Radius_m" around the
  #center coordinates. The function to perform the circular buffer extraction
  #does only work accurately, if the raster is in a metric coordinate system
  #(like UTM) and not in lat-lon degree coords. However, projecting the entire
  #(potentially very large) raster to a different coordinate system takes too
  #much time and memory. Therefore, as a preparatory step, a quadratic
  #sub-raster is extracted around the center coordinates. Then only this
  #sub-raster is converted to a metric coordinate system (and subsequently the
  #circular buffer is extracted from that reprojected sub-raster). This variable
  #defines the length of one edge of the quadratic sub-raster. The minimum size
  #is 2x the radius (one radius to each side). Use 4x radius to have sufficient
  #buffer in all directions.
  SubRasterEdgeLength_m <- Radius_m * 4
  
  #Read Raster-----
  if ( !file.exists(RasterFilePath) ) {
    stop("!file.exists(RasterFilePath) ")
  }
  MyRasterObject <- raster(RasterFilePath)
  
  
  #Target location as SpatialPoints object-----
  Center_EPSG4326 <- SpatialPoints(
    coords = data.frame(lon = Center_Lon_EPSG4326, lat = Center_Lat_EPSG4326),
    proj4string = CRS("EPSG:4326")
  )
  
  
  #Reproject target location-----------
  #To metric system ETRS89 / UTM zone 32N, such that metric distances can be
  #added/substratced to/from coordinates
  Center_UTM32N <- spTransform(
    x = Center_EPSG4326,
    CRSobj = CRS("EPSG:25832")
  )
  
  #Extract sub-raster-----
  
  #_Define sub-raster extent------
  Center_lon_UTM32N <- Center_UTM32N@coords[1]
  Center_lat_UTM32N <- Center_UTM32N@coords[2]
  West_Lon_UTM32N <- Center_lon_UTM32N - SubRasterEdgeLength_m/2
  North_Lat_UTM32N <- Center_lat_UTM32N + SubRasterEdgeLength_m/2
  East_Lon_UTM32 <- Center_lon_UTM32N + SubRasterEdgeLength_m/2
  South_Lat_UTM32 <- Center_lat_UTM32N - SubRasterEdgeLength_m/2
  Lon <- c(West_Lon_UTM32N, East_Lon_UTM32, East_Lon_UTM32, West_Lon_UTM32N, West_Lon_UTM32N)
  Lat <- c(North_Lat_UTM32N, North_Lat_UTM32N, South_Lat_UTM32, South_Lat_UTM32, North_Lat_UTM32N)
  tmp <- sp::Polygon(cbind(Lon,Lat))
  tmp <- sp::Polygons(list(tmp), ID = "SomePolygonID")
  SubRasterAsPolygon = SpatialPolygons(list(tmp))
  proj4string(SubRasterAsPolygon) = CRS("EPSG:25832")
  
  
  #_Reproject sub-raster extent to raster CRS------
  SubRasterAsPolygon_Reproj <- sp::spTransform(
    x = SubRasterAsPolygon,
    CRSobj = raster::crs(MyRasterObject)
  )
  
  #_Cut sub-raster out of raster-----
  CurrentSubRaster <- crop(
    x = MyRasterObject,
    y = SubRasterAsPolygon_Reproj
  )
  
  #_Reproject sub-raster to metric system-----
  #This is feasable (time, memory) because sub-raster is much smaller than
  #original raster.
  CurrentSubRasterProjected <- projectRaster(
    from = CurrentSubRaster,
    #method must be nearest neighbour (ngb) to conserve integer land use codes.
    #otherwise projectRaster applies interpolation, resulting in non-integer
    #raster values.
    method = "ngb",
    #Metric system ETRS89 / UTM zone 32N
    crs = CRS("EPSG:25832")
  )


  #Circular buffer around center------
  sp_buffer <-st_buffer(
    x = st_as_sf(Center_UTM32N),
    dist = Radius_m
  ) 
  
  #Extract circular buffer-----
  Extracted <- exactextractr::exact_extract(
    x = CurrentSubRasterProjected,
    y = sp_buffer
  )
  
  
  #Aggregate buffer-----
  CellCount <- as.data.frame(Extracted[[1]]) %>%
    rename(
      grid_code = value
    ) %>%
    group_by(grid_code) %>%
    summarise(
      nCells = sum(coverage_fraction)
    ) %>%
    ungroup()
  
  
  #Return-----
  return(CellCount)
}
