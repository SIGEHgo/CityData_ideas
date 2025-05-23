| Proyecto | Descripción | Enlace |
|----------|-------------|--------|
| **[Lugares de orige de ususarios de alimentadoras](https://sigehgo.github.io/Documentacion-Codigos/Datos/Tuzobus/Alimentadoras/mapa_calor.html)** | A partir de las rutas alimentadoras del Tuzobús que nos pasaron en el archivo KMZ, se extrajeron solo las paradas. Algunas rutas incluían las paradas tanto de ida como de regreso, así que se unificaron para que quedara solo una lista por ruta.
Luego, con todas las paradas reunidas en un archivo SHP, se generó un buffer de 25 metros alrededor de cada una. Usando estas paradas con buffer, se filtró la base de datos de CityData para quedarnos únicamente con los viajes que terminan en una parada de ruta alimentadora.
Esta base de datos tiene una columna que indica la “manzana” donde inicia el viaje, y otra con el “ratio” del viaje. Entonces, agrupamos los inicios por manzana para generar el mapa de calor donde tiene de peso la suma de los “ratio”.
 | [🔗 Ver más](https://sigehgo.github.io/Documentacion-Codigos/Datos/Tuzobus/Alimentadoras/mapa_calor.html) |
