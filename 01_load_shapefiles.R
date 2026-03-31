# Hurricane_Michael# ============================================================
# HURRICANE MICHAEL — LOAD & VISUALIZE SHAPEFILES
# Author: Nazrina Haque
# Description: Loads Hurricane Michael windswath and severity
#              zone shapefiles and plots them on a US map
# ============================================================

library(sf)
library(maps)
library(ggplot2)
library(conflicted)
conflicted::conflicts_prefer(maps::map)

# ============================================================
# LOAD HURRICANE MICHAEL SEVERITY ZONES
# ============================================================
Sys.setenv(SHAPE_RESTORE_SHX = "YES")

michael_severity <- st_read("hurricane_michael_severity_zones.shp")
print(head(michael_severity))
st_crs(michael_severity)

# ============================================================
# LOAD US BASE MAP & MATCH CRS
# ============================================================
us_map <- st_as_sf(map("state", plot = FALSE, fill = TRUE))

michael_severity <- st_transform(michael_severity, crs = st_crs(us_map))

# ============================================================
# PLOT MICHAEL SEVERITY ZONES
# ============================================================
ggplot() +
  geom_sf(data = us_map,        fill = "white", color = "black") +
  geom_sf(data = michael_severity,
          aes(fill = ident),    color = "black", alpha = 0.5) +
  theme_void() +
  theme(legend.position   = "right",
        plot.title        = element_text(hjust = 0.5)) +
  labs(title = "Hurricane Michael Severity Zones",
       fill  = "Severity")

# ============================================================
# LOAD MICHAEL WINDSWATH (AL142018)
# ============================================================
michael_windswath <- st_read("AL142018_windswath.shp")
michael_windswath <- st_transform(michael_windswath, crs = st_crs(us_map))

ggplot() +
  geom_sf(data = us_map,         fill = "white", color = "black") +
  geom_sf(data = michael_windswath,
          aes(fill = STARTDTG),  color = "black", alpha = 0.5) +
  theme_void() +
  theme(legend.position   = "right",
        plot.title        = element_text(hjust = 0.5)) +
  labs(title = "Hurricane Michael Wind Swath",
       fill  = "Date")

cat("✅ Shapefiles loaded and plotted\n")
