setwd("C:/Users/SIGEH/Desktop/Lalo/Gob/Proyectos")

### Creacion de carpetas para iniciar con todo

archivos = list.files("CityData_ideas/Datos/Tuzobus/Alimentadoras/KMZ/", pattern = "\\.kmz$", full.names = TRUE)
nombres_archivos = basename(archivos)
ruta_salida_base = "CityData_ideas/Datos/Tuzobus/Alimentadoras/KMZ_Carpetas/"
for (i in seq_along(archivos)) {
  archivo = archivos[i]
  nombre = tools::file_path_sans_ext(nombres_archivos[i])
  ruta_destino = file.path(ruta_salida_base, nombre)
  
  # Crear carpeta si no existe
  if (!dir.exists(ruta_destino)) {
    dir.create(ruta_destino)
  }
  
  # Descomprimir el archivo .kmz 
  unzip(archivo, exdir = ruta_destino)
}


### Puntos
archivos = list.files("CityData_ideas/Datos/Tuzobus/Alimentadoras/KMZ_Carpetas/", pattern = "\\.kml$", full.names = TRUE, all.files = T,recursive = T)
archivos = grep("doc\\.kml$", archivos, value = TRUE)
nombres = basename(dirname(archivos))

todo = NULL
# i = 16
for (i in seq_along(archivos)) {
  nombre_capas = sf::st_layers(archivos[i])
  cat("Vamos en el archivo", nombres[i], "vamos a trabajar con la capa:" , nombre_capas$name[1], "\n")
  datos = sf::st_read(archivos[i], layer = "Paradas")   # nombre_capas$name[1]
  datos = sf::st_zm(x = datos)     # Eliminar la tercer coordenada
  
  # Quedarse con las rutas unicas sea ida o vuelta
  coords = sf::st_coordinates(datos)
  duplicados = duplicated(datos)
  quedarse = which(duplicados == FALSE)
  datos = datos[quedarse,]
  
  datos$Des = sub('.*"Dirección de Operación SITMAH"\\s*', '', datos$Description)
  datos$RA = nombres[i]
  datos = datos |> dplyr::select(RA, Name, Description, Des)
  todo = rbind(todo, datos)
}

sf::write_sf(todo, "CityData_ideas/Datos/Tuzobus/Alimentadoras/Completos/Puntos/alimentadoras_puntos.shp")


### Lineas

archivos = list.files("CityData_ideas/Datos/Tuzobus/Alimentadoras/KMZ_Carpetas/", pattern = "\\.kml$", full.names = TRUE, all.files = T,recursive = T)
archivos = grep("doc\\.kml$", archivos, value = TRUE)
nombres = basename(dirname(archivos))

todo = NULL
for (i in seq_along(archivos)) {
  nombre_capas = sf::st_layers(archivos[i])
  cat("Vamos en el archivo", i, "con nombre ",nombres[i], "vamos a trabajar con la capa:" , nombre_capas$name[2], "\n")
  datos = sf::st_read(archivos[i], layer = if (i == 19) "Rercorrido" else "Recorrido")
  cat("Las rutas que tiene son:", nrow(datos), "\n")
  datos = sf::st_zm(x = datos)
  datos$RA = nombres[i]
  datos$Des = sub('.*"Dirección de Operación SITMAH"\\s*', '', datos$Description)
  datos = datos |> dplyr::select(RA, Name, Description, Des)
  
  if (nrow(datos) > 1) {
    coordenadas = sf::st_coordinates(datos) 
    coordenadas = coordenadas[, -3]
    coordenadas_unicas = coordenadas |> unique()
    
    linestring = sf::st_linestring(coordenadas_unicas)
    sf_line = sf::st_sf(geometry = sf::st_sfc(linestring), crs = sf::st_crs(datos))
    sf_line$RA = nombres[i]
    sf_line$Name = nombres[i]
    sf_line$Description = nombres[i]
    sf_line$Des = nombres[i]
    datos = sf_line
    datos = datos |> dplyr::select(RA, Name, Description, Des)
  }
  todo = rbind(todo, datos)
}

rutas_aportacion = sf::read_sf("CityData_ideas/Datos/Tuzobus/Datos_como_se_enviaron/ruta_aportación/Rutas_de_aportacion.shp")
rutas_aportacion = sf::st_zm(x = rutas_aportacion)     # Eliminar la tercer coordenada
rutas_aportacion$geometry |> plot()

coordenadas = sf::st_coordinates(rutas_aportacion) 
coordenadas = coordenadas[, -3]
coordenadas_unicas = coordenadas |> unique()

linestring = sf::st_linestring(coordenadas_unicas)
sf_line = sf::st_sf(geometry = sf::st_sfc(linestring), crs = sf::st_crs(rutas_aportacion))
sf_line$RA = "Rutas de aportacion"
sf_line$Name = "Ruta de aportación CETRAM-CENTRAL-HOSPITALES"
sf_line$Description = "Ruta de aportación CETRAM-CENTRAL-HOSPITALES"
sf_line$Des = "Ruta de aportación CETRAM-CENTRAL-HOSPITALES"


rutas_aportacion = sf_line
rutas_aportacion = rutas_aportacion |> dplyr::select(RA, Name, Description, Des)

todo = rbind(todo, rutas_aportacion)

sf::write_sf(todo,"CityData/Tuzobus/Manual/Rutas Alimentadoras/Rutas_Alimentadoras_lineas_con_ruta_aportacion.shp")


