library(GISTools)
library(rgdal)
library(sp)
library(dplyr)

flood50 <- readOGR(dsn = "./data", layer = "flood50", encoding="utf8")
flood50 <- spTransform(flood50, CRS("+proj=tmerc +lat_0=0 +lon_0=121 +k=0.9999 +x_0=250000 +y_0=0 +ellps=GRS80 +units=m +no_defs"))
Taipei_Vill <- readOGR(dsn = "./data", layer = "Taipei_Vill", encoding="utf8")
Taipei_Vill$CENSUS <- as.numeric(as.character(Taipei_Vill$CENSUS))
Taipei_Vill$AREA <- poly.areas(Taipei_Vill)#計算村里面積
flood50.attr <- data.frame(flood50)
Taipei_Vill.attr <- data.frame(Taipei_Vill)

Overlay_Layer <- gIntersection(Taipei_Vill, flood50, byid = T)
plot(Overlay_Layer, lwd = 1)

name_list <- strsplit(names(Overlay_Layer), " ")
Vill.id <- as.numeric(unlist(lapply(name_list, function(x) x[1]))) #村里代號
flood.id <- as.numeric(unlist(lapply(name_list, function(x) x[2]))) #淹水代號

df <- data.frame(Vill.id, flood.id)

for (i in 1:nrow(df)){ #length = ncol
  df$grid_code[i] <- flood50$grid_code[df$flood.id[i] + 1]#對上淹水規模
  df$cencus[i] <- Taipei_Vill$CENSUS[df$Vill.id[i] + 1]#對上村里人口
  df$area1[i] <- Taipei_Vill$AREA[df$Vill.id[i] + 1]#對上村里面積
}

Overlay_LayerNew<- SpatialPolygonsDataFrame(Overlay_Layer, data=df,match.ID = F)#轉成spatial dataframe
Overlay_LayerNew$area2 <- poly.areas(Overlay_LayerNew)#計算各個交集的面積
Overlay_LayerNew$flood_pct <- as.numeric(Overlay_LayerNew$area2/Overlay_LayerNew$area1)#計算淹水面積比例
Overlay_LayerNew$flood_count <- as.integer(Overlay_LayerNew$flood_pct * Overlay_LayerNew$cencus)#計算淹水影響人數(整數)

xtabs(flood_count~grid_code, Overlay_LayerNew)#整理成報表
