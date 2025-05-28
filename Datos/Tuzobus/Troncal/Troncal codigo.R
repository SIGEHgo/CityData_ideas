### Pasar estaciones a un shp

nombre_capas = sf::st_layers("Datos/Tuzobus/Troncal/ESTACIONES.kml")
datos = sf::st_read("Datos/Tuzobus/Troncal/ESTACIONES.kml")

datos$Name[datos$Name == "26 Niños Héroes"] = "26 - Niños Héroes"
datos = sf::st_zm(x = datos)     # Eliminar la tercer coordenada
datos = datos |> dplyr::mutate(Descripcion = sub(x = Name, pattern = ".*-\\s*", replacement = ""),
                               Descripcion = stringr::str_trim(Descripcion)) |>
  dplyr::select(Name, Description, Descripcion)

sf::write_sf(datos, "Datos/Tuzobus/Troncal/Estaciones shp/estaciones.shp")

# Pasar rutas a shp

archivos = list.files("Datos/Tuzobus/Troncal/Rutas/Kmz/", pattern = "\\.kml$", full.names = TRUE, all.files = T,recursive = T)
nombres = basename(archivos)
nombres = sub(x = nombres, pattern = "\\.kml$", replacement = "")

todo = NULL
for (i in seq_along(archivos)) {
  cat("Vamos en el archivo", i, "con nombre ",nombres[i])
  nombre_capas = sf::st_layers(archivos[i])
  datos = sf::st_read(archivos[i], layer = "Recorrido")
  datos = sf::st_zm(x = datos)
  datos = datos |> dplyr::mutate(Nombre = nombres[i]) |> 
    dplyr::select(Nombre, Name, Description,geometry)
  todo = rbind(todo, datos)
}

todo = todo |> dplyr::select(Nombre)

sf::write_sf(todo, "Datos/Tuzobus/Troncal/Rutas/rutas.shp")


### Buffer
datos = sf::read_sf("Datos/Tuzobus/Troncal/Estaciones shp/estaciones.shp")

datos_buffer = sf::st_transform(datos, crs = sf::st_crs("EPSG:32614"))
datos_buffer = sf::st_buffer(datos_buffer, dist = 25)

datos = sf::st_transform(datos_buffer, crs = sf::st_crs(datos))

sf::write_sf(datos, "Datos/Tuzobus/Troncal/Estaciones shp/estaciones_buffer_25mts.shp")


#### No fue efectivo, se prefirio usar Python
# Se ocupa tener install.packages("R.utils")

lista = list.files(recursive = T, pattern = "cityflow")
lista = lista[grepl("\\.csv\\.gz$", lista)]
nombres = basename(lista)
nombres = sub(x = nombres, pattern = "\\.csv\\.gz$", replacement = "")
estaciones = sf::read_sf("Datos/Tuzobus/Troncal/Estaciones shp/estaciones_buffer_25mts.shp")
lista

for (i in seq_along(nombres)) {
  cat("Vamos en el archivo", i, "que tiene nombre:", nombres[i], "\n")
  datos = data.table::fread(lista[i])
  guardar = datos
  
  datos = sf::st_as_sf(x = datos, coords = c("overlap_destination_long" ,"overlap_destination_lat"), crs = sf::st_crs(estaciones))
  
  interseccion = sf::st_intersects(x = estaciones, y = datos)
  interes = unlist(x = interseccion)
  guardar = guardar[interes,]
  
  write.csv(guardar, file.path("Datos/Tuzobus/Troncal/Citydata_filtracion/", paste0(nombres[i], ".csv")), row.names = F, fileEncoding = "UTF-8")
}




### Mapas web
library(sf)
library(raster)
library(leaflet)
library(leaflet.extras)
library(leaflet.extras2)
library(leaflegend)
library(leafem)
library(htmltools)
library(htmlwidgets)


archivos = list.files(path = "Datos/Tuzobus/Troncal/Citydata_filtracion/", pattern = ".csv", full.names = T)
datos = NULL
for (i in seq_along(archivos)) {
  leer = read.csv(archivos[i])
  cat("El tamaño es:", nrow(leer), "\n")
  datos = rbind(datos, leer)
}

datos = datos |> dplyr::filter(trip_duration_sec > 59, trip_distance_m > 29)
rutas = sf::read_sf("Datos/Tuzobus/Troncal/Rutas/rutas.shp")


# A nivel punto
mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = datos ,lng = datos$overlap_origin_long, lat = datos$overlap_origin_lat, radius = 5, blur = 5, max = 1,intensity = datos$trip_scaled_ratio, group = "Sitio de Origen Usuarios") |>
  addPolylines(data = rutas[1,], label = rutas$Nombre[1], color = "green", group = "T-01", weight = 3) |>
  addPolylines(data = rutas[2,], label = rutas$Nombre[2], color = "purple", group = "T-02", weight = 3) |>
  addPolylines(data = rutas[3,], label = rutas$Nombre[3], color = "orange", group = "T-04", weight = 3) |>
  addPolylines(data = rutas[4,], label = rutas$Nombre[4], color = "red", group = "T-05", weight = 3) |>
  addLayersControl(baseGroups = c("Sitio de Origen Usuarios"), overlayGroups = c("T-01", "T-02", "T-04", "T-05"),position = "topright",  options = layersControlOptions(collapsed = F)) |>
  hideGroup(group = c("T-01", "T-02", "T-04", "T-05")) |>
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      map.on('zoomend', function() {
        var zoom = map.getZoom();
        map.eachLayer(function(layer) {
          if (layer instanceof L.Polyline) {
            if (zoom > 11 && zoom <= 16) {
              layer.setStyle({weight: 5});
            } else if (zoom > 16) {
              layer.setStyle({weight: 10});
            } else {
              layer.setStyle({weight: 3});
            }
          }
        });
      });
    }
  ")

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Troncal/Mapas web/todos_datos_punto.html", selfcontained = F,title = "Lugares de origen de usuarios de troncal")  

write.csv(datos, "Datos/Tuzobus/Troncal/Csv_meses/Todos_juntos.csv", row.names = F, fileEncoding = "UTF-8")




### Versiones por meses

archivos = list.files(path = "Datos/Tuzobus/Troncal/Citydata_filtracion/", pattern = ".csv", full.names = T)
datos = NULL
for (i in seq_along(archivos)) {
  leer = read.csv(archivos[i])
  cat("El tamaño es:", nrow(leer), "\n")
  datos = rbind(datos, leer)
}

datos = datos |> dplyr::filter(trip_duration_sec > 59, trip_distance_m > 29)
datos = datos |> dplyr::mutate(mes = substr(x = start_timestamp, start = 1, stop = 7))


# Junio
junio = datos |> dplyr::filter(mes == "2023-06") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = junio,lng = junio$overlap_origin_long, lat = junio$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = junio$trip_scaled_ratio) |>
  addPolylines(data = rutas[1,], label = rutas$Nombre[1], color = "green", group = "T-01", weight = 3) |>
  addPolylines(data = rutas[2,], label = rutas$Nombre[2], color = "purple", group = "T-02", weight = 3) |>
  addPolylines(data = rutas[3,], label = rutas$Nombre[3], color = "orange", group = "T-04", weight = 3) |>
  addPolylines(data = rutas[4,], label = rutas$Nombre[4], color = "red", group = "T-05", weight = 3) |>
  addLayersControl(baseGroups = c("Sitio de Origen Usuarios"), overlayGroups = c("T-01", "T-02", "T-04", "T-05"),position = "topright",  options = layersControlOptions(collapsed = F)) |>
  hideGroup(group = c("T-01", "T-02", "T-04", "T-05")) |>
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      map.on('zoomend', function() {
        var zoom = map.getZoom();
        map.eachLayer(function(layer) {
          if (layer instanceof L.Polyline) {
            if (zoom > 11 && zoom <= 16) {
              layer.setStyle({weight: 5});
            } else if (zoom > 16) {
              layer.setStyle({weight: 10});
            } else {
              layer.setStyle({weight: 3});
            }
          }
        });
      });
    }
  ")

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Troncal/Mapas web/junio_punto.html", selfcontained = F,title = "Junio lugares de origen de usuarios de troncal")  
write.csv(junio, "Datos/Tuzobus/Troncal/Csv_meses/Junio.csv", row.names = F, fileEncoding = "UTF-8")

# Octubre
octubre = datos |> dplyr::filter(mes == "2023-10") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = octubre,lng = octubre$overlap_origin_long, lat = octubre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = octubre$trip_scaled_ratio) |>
  addPolylines(data = rutas[1,], label = rutas$Nombre[1], color = "green", group = "T-01", weight = 3) |>
  addPolylines(data = rutas[2,], label = rutas$Nombre[2], color = "purple", group = "T-02", weight = 3) |>
  addPolylines(data = rutas[3,], label = rutas$Nombre[3], color = "orange", group = "T-04", weight = 3) |>
  addPolylines(data = rutas[4,], label = rutas$Nombre[4], color = "red", group = "T-05", weight = 3) |>
  addLayersControl(baseGroups = c("Sitio de Origen Usuarios"), overlayGroups = c("T-01", "T-02", "T-04", "T-05"),position = "topright",  options = layersControlOptions(collapsed = F)) |>
  hideGroup(group = c("T-01", "T-02", "T-04", "T-05")) |>
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      map.on('zoomend', function() {
        var zoom = map.getZoom();
        map.eachLayer(function(layer) {
          if (layer instanceof L.Polyline) {
            if (zoom > 11 && zoom <= 16) {
              layer.setStyle({weight: 5});
            } else if (zoom > 16) {
              layer.setStyle({weight: 10});
            } else {
              layer.setStyle({weight: 3});
            }
          }
        });
      });
    }
  ")

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Troncal/Mapas web/octubre_punto.html", selfcontained = F,title = "Octubre lugares de origen de usuarios de troncal")  
write.csv(octubre, "Datos/Tuzobus/Troncal/Csv_meses/Octubre.csv", row.names = F, fileEncoding = "UTF-8")

# Diciembre
diciembre = datos |> dplyr::filter(mes == "2023-12") |> dplyr::select(-mes)

mapa_web = leaflet() |>
  addTiles() |>
  addHeatmap(data = diciembre,lng = diciembre$overlap_origin_long, lat = diciembre$overlap_origin_lat, blur = 5, max = 1, radius = 5, intensity = diciembre$trip_scaled_ratio) |>
  addPolylines(data = rutas[1,], label = rutas$Nombre[1], color = "green", group = "T-01", weight = 3) |>
  addPolylines(data = rutas[2,], label = rutas$Nombre[2], color = "purple", group = "T-02", weight = 3) |>
  addPolylines(data = rutas[3,], label = rutas$Nombre[3], color = "orange", group = "T-04", weight = 3) |>
  addPolylines(data = rutas[4,], label = rutas$Nombre[4], color = "red", group = "T-05", weight = 3) |>
  addLayersControl(baseGroups = c("Sitio de Origen Usuarios"), overlayGroups = c("T-01", "T-02", "T-04", "T-05"),position = "topright",  options = layersControlOptions(collapsed = F)) |>
  hideGroup(group = c("T-01", "T-02", "T-04", "T-05")) |>
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      map.on('zoomend', function() {
        var zoom = map.getZoom();
        map.eachLayer(function(layer) {
          if (layer instanceof L.Polyline) {
            if (zoom > 11 && zoom <= 16) {
              layer.setStyle({weight: 5});
            } else if (zoom > 16) {
              layer.setStyle({weight: 10});
            } else {
              layer.setStyle({weight: 3});
            }
          }
        });
      });
    }
  ")

mapa_web

saveWidget(mapa_web,"Datos/Tuzobus/Troncal/Mapas web/diciembre_punto.html", selfcontained = F,title = "Diciembre lugares de origen de usuarios de troncal")  
write.csv(diciembre, "Datos/Tuzobus/Troncal/Csv_meses/Diciembre.csv", row.names = F, fileEncoding = "UTF-8")

