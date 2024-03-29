#### The purpose of this file is to visualize the assembled GTFS data.

# 1. Set up the environment
library(tidyverse)
library(ggplot2)
library(tigris)
library(sf)
library(here)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggspatial)
library(cartogram)
library(ggthemes)

gtfs_data <- here("assembled-data",
                  "final-data.csv") %>%
  read_csv() %>%
  select(-X1)

# 2. Visualisation 
## (1) To present agencies as points on map
agency_location <- here("assembled-data",
                        "agency-location.csv") %>%
  read_csv() %>%
  select(Company_Nm, agency, date, lon, lat) %>%
  mutate(adopted_year = as.numeric(str_sub(date, -2, -1)) + 2000) %>%
  filter(lon > -150 & lat < 60)

agency_pt <- st_as_sf(agency_location, coords = c("lon", "lat"), crs = 4326)

US_states <- ne_states(country = "United States of America", returnclass = "sf") %>%
  filter(name != "Alaska",
         name != "Hawaii")

### Adopted_year shown by the color of the points on map
ggplot() +
  geom_sf(data = US_states, fill = NA) +
  geom_sf(data = agency_pt,
          aes(color = adopted_year),
          size = 1) +
  theme_map() +
  theme(legend.direction = "horizontal")

here("figures", "map_adopted_year.jpeg") %>%
  ggsave(width = 12, height = 8, units = "cm")

### ridership shown by histogram and by the size of the points on map
ridership <- gtfs_data %>%
  select(Company_Nm, ridership) %>%
  inner_join(agency_location) %>%
  #### remove duplicate rows
  filter(!duplicated(Company_Nm),)

agency_ridership <- st_as_sf(ridership, coords = c("lon", "lat"), crs = 4326)

ggplot(ridership, aes(x = ridership)) +
  geom_histogram() +
  scale_x_log10()

here("figures", "histogram_ridership.jpeg") %>%
  ggsave(width = 9, height = 8, units = "cm")

ggplot() +
  geom_sf(data = US_states, fill = NA) +
  geom_sf(data = agency_ridership,
          aes(size = ridership),
          alpha = 0.5, color = "red") +
  scale_size_continuous(
    name = "Ridership",
    breaks = c(50000, 100000, 5000000, 10000000, 1000000000)) +
  theme_map() +
  theme(legend.direction = "horizontal")

here("figures", "map_ridership.jpeg") %>%
  ggsave(width = 12, height = 8, units = "cm")

### VRM_UZA_share shown by the size of the points on map
vrm_share <- gtfs_data %>%
  select(Company_Nm, VRM_UZA_share) %>%
  inner_join(agency_location) %>%
  filter(!duplicated(Company_Nm),)

vrm_uza_share <- st_as_sf(vrm_share, coords = c("lon", "lat"), crs = 4326)

ggplot() +
  geom_sf(data = US_states, fill = NA) +
  geom_sf(data = vrm_uza_share,
          aes(size = VRM_UZA_share),
          alpha = 0.5, color = "green") +
  scale_size_continuous(
    name = "VRM Share in Urbanized Area") +
  theme_map() +
  theme(legend.direction = "horizontal")

here("figures", "map_vrm_share.jpeg") %>%
  ggsave(width = 12, height = 8, units = "cm")

## (2) 
### The percentage increase of GTFS adoption rate from 2005 to 2020
ggplot(gtfs_data, 
       aes(x = year, y = `Percent adoption of GTFS data standard`)) +
  geom_smooth() +
  annotate("segment",
           x = 2008, xend = 2008,
           y = 0.085, yend = 0.135,
           color = "gray") +
  annotate("text", 
           x = 2008, 
           y = 0.15,
           label = "8.60%",
           size = 4) +
  annotate("segment",
           x = 2018, xend = 2018,
           y = 0.655, yend = 0.685,
           color = "gray") +
  annotate("text",
           x = 2018,
           y = 0.7,
           label = "65.29%",
           size = 4)

here("figures", "line_adooption_rate.jpeg") %>%
  ggsave(width = 9, height = 8, units = "cm")

### The number increase of GTFS adoption agencies from 2005 to 2020 & The number change of total agencies from 2005 to 2020
ggplot(gtfs_data) +
  geom_smooth(aes(x = year, y = num_adopted)) +
  geom_smooth(aes(x = year, y = num_agencies)) 

here("figures", "line_adooption_number.jpeg") %>%
  ggsave(width = 9, height = 8, units = "cm")

## (3) Use Tigris package to get urbanized area shapefile. But it is too big and does not plot on my computer. 
options(tigris_class = "sf")
options(tigris_cache_dir = TRUE)

uza <- urban_areas()

uza_ie <- uza %>%
  filter(NAME10 == "Dixon, IL" | NAME10 == "Escanaba, MI")

ggplot(uza_ie) +
  geom_sf()

### Percentage of renter-occupied households shown on map
rented <- gtfs_data %>%
  select("Urbanized Area", pct_rented)%>%
  filter(!duplicated(`Urbanized Area`),)

ggplot(rented, aes(x = pct_rented)) +
  geom_histogram() +
  scale_x_continuous(name = "Percentage of Renter-occupied Households")
here("figures", "histogram_renter_percentage.jpeg") %>%
  ggsave(width = 9, height = 8, units = "cm")

#### Since I cannot draw uza in r, I write the csv with needed data and draw the map with ArcGIS Pro. 
write.csv(rented, file = "/Users/limengyao/Desktop/OneDrive - Harvard University/OD_Projects/202206_Carole_GTFS/pct-renter.csv")
