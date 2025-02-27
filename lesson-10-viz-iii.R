## -----------------------------------------------------------------------------
##
##' [PROJ: EDH 7916]
##' [FILE: Maps & Spatial Data (Feat. APIs)]
##' [INIT: March 5th 2023]
##' [AUTH: Matt Capaldi] @ttalVlatt
##
## -----------------------------------------------------------------------------

# ## ---------------------------
# ##' [libraries]
# ## ---------------------------
# 
# ## Install new packages
# install.packages(c("sf", "tidycensus", "tigris"))

library(tidyverse)
library(sf)
library(tidycensus)
library(tigris)

# ## ---------------------------
# ##' [set API key]
# ## ---------------------------
# 
# ## you only need to do this once: replace everything between the
# ## quotes with the key in the email you received
# ##
# ## eg. census_api_key("XXXXXXXXXXXXXXXXXX", install = T)
# census_api_key("<key>", install = T)

## ---------------------------
##' [Get ACS Data]
## ---------------------------

df_census <- get_acs(geography = "county",
                     state = "FL",
                     year = 2021,
                     variables = "DP02_0065PE", # Pop >=25 with Bachelors
                     output = "wide",
                     geometry = TRUE)


## show header of census data
head(df_census)

## view data frame without geometry data
df_census_view <- df_census |>
  st_drop_geometry()

head(df_census_view)



## ---------------------------------------------------------
##' [Making a map (finally)]
## ---------------------------------------------------------
## ---------------------------
##' [Layer one: base map]
## ---------------------------

## show CRS for dataframe
st_crs(df_census)

## transform the CRS to 4326
df_census <- df_census |>
  st_transform(crs = 4326)

## show CRS again; notice how it changed from NAD93 to EPSG:4326
st_crs(df_census) 

## create base map
base_map <- ggplot() +
  geom_sf(data = df_census,
          aes(fill = DP02_0065PE),
          color = "black",
          size = 0.1) +
  labs(fill = str_wrap("Percent Population with Bachelor's", 20)) +
  scale_fill_gradient(low = "#a6b5c0", high = "#00254d") +
  theme_minimal()

## call base map by itself
base_map



## ---------------------------
##' [Layer Two: Institutions]
## ---------------------------

## read in IPEDS data
df_ipeds <- read_csv("data/mapping-api-data.csv")

## show IPEDS data
head(df_ipeds)

## convert coordinates columns into a true geometry column; this is
## much more reliable than simply plotting them as geom_points as it
## ensures the CRS matches etc.
df_ipeds <- df_ipeds |> 
  st_as_sf(coords = c("LONGITUD", "LATITUDE"))

## show IPEDS data again
head(df_ipeds)

## check CRS for IPEDS data
st_crs(df_ipeds)

## add CRS to our IPEDS data
df_ipeds <- df_ipeds |> 
  st_set_crs(4326) # When you first add coordinates to geometry, it doesn't know
                   # what CRS to use, so we set to 4326 to match our base map data

## check CRS of IPEDS data again
st_crs(df_ipeds)

point_map <- base_map +
  geom_sf(data = df_ipeds |> filter(FIPS == 12), # Only want to plot colleges in FL
          aes(size = LPBOOKS),
          alpha = 0.8,
          shape = 23, # Get the diamond shape which stands out nicely on the map
          fill = "white", # This shape has a fill and color for the outline
          color = "black") + # FYI 21 is a circle with both fill and color
  labs(size = "Number of Books in Library")

## show new map
point_map



## ---------------------------------------------------------
##' [Supplemental using tigris directly]
## ---------------------------------------------------------

##' [TX School Districts]

df_school_dist_tx <- school_districts(cb = TRUE, state = "TX")


ggplot() +
  geom_sf(data = df_school_dist_tx,
          aes())

##' [States]

df_st <- states(cb = TRUE, resolution = "20m") |>
  filter(STATEFP <= 56) # keeping only the 50 states plus D.C.

## look at head of state data
head(df_st)

## quick plot of states
ggplot() +
  geom_sf(data = df_st,
          aes(),
          size = 0.1) # keep the lines thin, speeds up plotting processing

## replotting with shifted Hawaii and Alaska
ggplot() +
  geom_sf(data = shift_geometry(df_st),
          aes(),
          size = 0.1) # keep the lines thin, speeds up plotting processing

## change CRS to what we used for earlier map
ggplot() +
  geom_sf(data = shift_geometry(df_st) |> st_transform(4326),
          aes(),
          size = 0.1)



## change CRS to requirements for Peters projection
## h/t https://gis.stackexchange.com/questions/194295/getting-borders-as-svg-using-peters-projection
pp_crs <- "+proj=cea +lon_0=0 +x_0=0 +y_0=0 +lat_ts=45 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

ggplot() +
  geom_sf(data = shift_geometry(df_st) |> st_transform(pp_crs),
          aes(),
          size = 0.1)


## -----------------------------------------------------------------------------
##' *END SCRIPT*
## -----------------------------------------------------------------------------
