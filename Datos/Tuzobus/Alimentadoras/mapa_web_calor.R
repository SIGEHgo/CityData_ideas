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
rutas = sf::read_sf("Datos/Tuzobus/Alimentadoras/Completos/Rutas/alimentadoras_rutas.shp")
rutas_unicas = unique(rutas$RA)
length(rutas_unicas)

## A nivel punto
mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = datos ,lng = datos$overlap_origin_long, lat = datos$overlap_origin_lat, radius = 5, blur = 5, max = 1,intensity = datos$trip_scaled_ratio) |>
  addPolygons(data = rutas |> dplyr::filter(RA == rutas_unicas[1]), label = rutas_unicas[1], group = rutas_unicas[1], weight = 1) |>
  addPolygons(data = rutas |> dplyr::filter(RA == rutas_unicas[2]), label = rutas_unicas[2], group = rutas_unicas[2], weight = 1) |>
  addLayersControl(baseGroups = c("Sitio de Origen Usuarios"), overlayGroups = c(rutas_unicas[1], rutas_unicas[2]),position = "topright",  options = layersControlOptions(collapsed = F)) |>
  hideGroup(group = c(rutas_unicas[1], rutas_unicas[2]))

mapa_web


saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/Mapas de calor/mapa_calor_nivel_punto.html",selfcontained = F, title = "Lugares de origen de usuarios de alimentadora")  
write.csv(datos, "Datos/Tuzobus/Alimentadoras/Csv_meses/todo_juntos.csv", row.names = F, fileEncoding = "UTF-8")


### A nivel punto optimizado

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(
    data = datos,
    lng = ~overlap_origin_long,
    lat = ~overlap_origin_lat,
    radius = 5,
    blur = 5,
    max = 1,
    intensity = ~trip_scaled_ratio
  )

#  walk(), útil para iterar sobre listas sin devolver un valor
walk(rutas_unicas, function(ruta) {
  mapa_web <<- mapa_web |>    # <<- se usa para modificar la variable global mapa_web desde dentro de la función.
    addPolylines(
      data = rutas |> dplyr::filter(RA == ruta),
      label = ruta,
      group = ruta,
      weight = 1
    )
})

# Añadir control de capas
mapa_web = mapa_web |>
  addLayersControl(
    baseGroups = c("Sitio de Origen Usuarios"),
    overlayGroups = rutas_unicas,
    position = "topright",
    options = layersControlOptions(collapsed = FALSE)
  ) |>
  hideGroup(group = rutas_unicas)

mapa_web




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

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/Mapas de calor/mapa_calor_nivel_manzana.html",selfcontained = F,title = "Manzana lugares de origen de usuarios de alimentadora")  
write.csv(conteo_manzana ,"Datos/Tuzobus/Alimentadoras/Csv_meses/todo_juntos_manzana.csv", row.names = F, fileEncoding = "UTF-8")





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

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/Mapas de calor/junio_punto.html",selfcontained = F,title = "Junio lugares de origen de usuarios de alimentadora")  
write.csv(junio ,"Datos/Tuzobus/Alimentadoras/Csv_meses/Junio.csv", row.names = F, fileEncoding = "UTF-8")

# Octubre
octubre = datos |> dplyr::filter(mes == "2023-10") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = octubre,lng = octubre$overlap_origin_long, lat = octubre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = octubre$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/Mapas de calor/octubre_punto.html",selfcontained = F,title = "Octubre lugares de origen de usuarios de alimentadora")  
write.csv(octubre ,"Datos/Tuzobus/Alimentadoras/Csv_meses/Octubre.csv", row.names = F, fileEncoding = "UTF-8")

# Diciembre

diciembre = datos |> dplyr::filter(mes == "2023-12") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = diciembre,lng = diciembre$overlap_origin_long, lat = diciembre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = diciembre$trip_scaled_ratio) # intensity = datos$trip_scaled_ratio

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Alimentadoras/Mapas de calor/diciembre_punto.html",selfcontained = F,title = "Diciembre lugares de origen de usuarios de alimentadora")  
write.csv(diciembre ,"Datos/Tuzobus/Alimentadoras/Csv_meses/Diciembre.csv", row.names = F, fileEncoding = "UTF-8")




































####
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

junio = junio |> 
  dplyr::select(device_id, origin_geoid, destination_geoid, overlap_origin_lat, 
                overlap_origin_long, overlap_destination_lat, overlap_destination_long, 
                start_timestamp, end_timestamp, trend_time, trip_duration_sec,
                trip_distance_m, trip_speed_mps, travel_mode, trip_id, trip_scaled_ratio)


write.csv(junio, "../../../../junio_prueba.csv", row.names = F, fileEncoding = "UTF-8")

lapply(junio, class)
