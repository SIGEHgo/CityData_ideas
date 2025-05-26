library(sf)
library(raster)
library(leaflet)
library(leaflet.extras)
library(leaflet.extras2)
library(leaflegend)
library(leafem)
library(htmltools)
library(htmlwidgets)



archivos = list.files(path = "Datos/Tuzobus/Alimentadoras/CityData_Filtracion/", pattern = ".csv", full.names = T)
datos = NULL
for (i in seq_along(archivos)) {
  leer = read.csv(archivos[i])
  cat("El tamaño es:", nrow(leer), "\n")
  datos = rbind(datos, leer)
}

datos = datos |> dplyr::filter(trip_duration_sec > 59, trip_distance_m > 29)

## A nivel punto
mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = datos ,lng = datos$overlap_origin_long, lat = datos$overlap_origin_lat, radius = 5, blur = 5, max = 1,intensity = datos$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/mapa_calor_nivel_punto.html",selfcontained = F,title = "Lugares de origen de usuarios de alimentadora")  


### A nivel manzana
conteo_manzana = datos |> dplyr::select(origin_geoid, trip_scaled_ratio) |>
  dplyr::group_by(origin_geoid) |>
  dplyr::summarise(conteo = dplyr::n(), suma_trip_scaled_ratio = sum(trip_scaled_ratio, na.rm = T))

shp = sf::read_sf("../../Importantes_documentos_usar/Continuo_estatal/Continuo_estatal.shp")
shp = shp |> dplyr::select(CVEGEO) |> sf::st_cast(to = "POLYGON")
shp = shp |> dplyr::group_by(CVEGEO) |> dplyr::slice_head(n = 1)
mun = sf::read_sf("../../Importantes_documentos_usar/Municipios/municipiosjair.shp")

conteo_manzana = conteo_manzana[conteo_manzana$origin_geoid != "", ]
conteo_manzana = merge(x = conteo_manzana, y = shp, by.x = "origin_geoid", by.y = "CVEGEO", all.x = T)
conteo_manzana = sf::st_as_sf(x = conteo_manzana)
sf::st_crs(conteo_manzana) = sf::st_crs(shp)
conteo_manzana = sf::st_centroid(x = conteo_manzana)
conteo_manzana = sf::st_transform(x = conteo_manzana, crs = sf::st_crs(mun))

coordenadas = sf::st_coordinates(conteo_manzana)
longitud = coordenadas[,1]
latitud = coordenadas[,2]

conteo_manzana$longitud = longitud
conteo_manzana$latitud = latitud

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = conteo_manzana,lng = conteo_manzana$longitud, lat = conteo_manzana$latitud, blur = 5, max = 1, radius = 5, intensity = conteo_manzana$suma_trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/mapa_calor_nivel_manzana.html",selfcontained = F,title = "Lugares de origen de usuarios de alimentadora")  





##### Version por meses
archivos = list.files(path = "Datos/Tuzobus/Alimentadoras/CityData_Filtracion/", pattern = ".csv", full.names = T)
datos = NULL
for (i in seq_along(archivos)) {
  leer = read.csv(archivos[i])
  cat("El tamaño es:", nrow(leer), "\n")
  datos = rbind(datos, leer)
}

datos = datos |> dplyr::filter(trip_duration_sec > 59, trip_distance_m > 29)
datos = datos |> dplyr::mutate(mes = substr(x = start_timestamp, start = 1, stop = 7))
datos$mes |> unique()

junio = datos |> dplyr::filter(mes == "2023-06") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = junio,lng = junio$overlap_origin_long, lat = junio$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = junio$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/junio_punto.html",selfcontained = F,title = "Lugares de origen de usuarios de alimentadora")  
# Octubre
octubre = datos |> dplyr::filter(mes == "2023-10") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = octubre,lng = octubre$overlap_origin_long, lat = octubre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = octubre$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/octubre_punto.html",selfcontained = F,title = "Lugares de origen de usuarios de alimentadora")  

# Diciembre

diciembre = datos |> dplyr::filter(mes == "2023-12") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = diciembre,lng = diciembre$overlap_origin_long, lat = diciembre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = diciembre$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/diciembre_punto.html",selfcontained = F,title = "Lugares de origen de usuarios de alimentadora")  

