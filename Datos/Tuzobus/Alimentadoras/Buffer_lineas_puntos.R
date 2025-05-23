### Buffer

#Puntos
setwd("C:/Users/SIGEH/Desktop/Lalo/Gob/Proyectos")

datos = sf::read_sf("CityData_ideas/Datos/Tuzobus/Alimentadoras/Completos/Puntos/alimentadoras_puntos.shp")

sf::st_crs(datos)
sf::st_crs(datos)$units_gdal

datos_buffer = sf::st_transform(datos, crs = sf::st_crs("EPSG:32614"))
datos_buffer = sf::st_buffer(datos_buffer, dist = 25)

datos = sf::st_transform(datos_buffer, crs = sf::st_crs(datos))
sf::write_sf(datos, "CityData_ideas/Datos/Tuzobus/Alimentadoras/Completos/Puntos/alimentadoras_puntos25mts.shp")
