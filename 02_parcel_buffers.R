# ============================================================
# HURRICANE MICHAEL — PARCEL BUFFERS
# Author: Nazrina Haque
# Description: Loads parcel data, converts to spatial object,
#              creates acre-based buffers around each parcel
# ============================================================

library(sf)
library(maps)
library(ggplot2)
library(dplyr)
library(conflicted)
conflicted::conflicts_prefer(maps::map)
conflicted::conflicts_prefer(dplyr::filter)

# ============================================================
# LOAD BASE MAP
# ============================================================
us_map <- st_as_sf(map("state", plot = FALSE, fill = TRUE))

# ============================================================
# LOAD MICHAEL WINDSWATH
# ============================================================
michael_windswath <- st_read("AL142018_windswath.shp")
michael_windswath <- st_transform(michael_windswath, crs = st_crs(us_map))

# ============================================================
# LOAD PARCEL DATA
# ============================================================
csv_path <- "combined_data.csv"
if (!file.exists(csv_path)) stop("CSV file not found.")

parcel_data <- read.csv(csv_path)
if (nrow(parcel_data) == 0) stop("CSV file is empty.")

# ============================================================
# CLEAN COORDINATES & ACRES
# ============================================================
parcel_data <- parcel_data %>%
  mutate(
    latitude  = as.numeric(as.character(parcel_level_latitude)),
    longitude = as.numeric(as.character(parcel_level_longitude)),
    acres     = as.numeric(as.character(acres))
  ) %>%
  filter(!is.na(latitude) & !is.na(longitude) & !is.na(acres))

cat("✅ Parcels after cleaning:", nrow(parcel_data), "\n")

# ============================================================
# CONVERT TO SF OBJECT
# ============================================================
parcel_sf <- st_as_sf(
  parcel_data,
  coords = c("parcel_level_longitude", "parcel_level_latitude"),
  crs    = 4326
)

parcel_sf <- st_transform(parcel_sf, crs = st_crs(us_map))

# ============================================================
# CREATE ACRE-BASED BUFFERS
# 1 acre = 4046.86 m² → radius = sqrt(area / pi)
# ============================================================
parcel_sf$area_m2       <- parcel_sf$acres * 4046.86
parcel_sf$buffer_radius <- sqrt(parcel_sf$area_m2 / pi)

parcel_buffers <- st_buffer(parcel_sf, dist = parcel_sf$buffer_radius)
parcel_buffers <- st_simplify(parcel_buffers, dTolerance = 0.01)

cat("✅ Buffers created:", nrow(parcel_buffers), "\n")

# ============================================================
# PLOT MICHAEL WINDSWATH + PARCEL BUFFERS
# ============================================================
ggplot() +
  geom_sf(data = us_map,
          fill  = "white",  color = "black") +
  geom_sf(data = michael_windswath,
          aes(fill = STARTDTG), color = "black", alpha = 0.5) +
  geom_sf(data = parcel_buffers,
          fill  = "blue",   color = "blue",  alpha = 0.3) +
  theme_void() +
  theme(legend.position = "right",
        plot.title      = element_text(hjust = 0.5)) +
  labs(title = "Hurricane Michael with Parcel Buffers",
       fill  = "Date")

# ============================================================
# SAVE BUFFERS
# ============================================================
saveRDS(parcel_buffers, "parcel_buffers.rds")
cat("✅ Parcel buffers saved\n")
