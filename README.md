Analisis de la contaminación de NO2 de Madrid
===========================================================
`#DataScience` `#Python` `#R` `#Forecast` `#Pollution`

## Objetivo ##
El objeto de este trabajo es el analisis de la contaminación en Madrid. Para ello se han tomado datos de la contaminación horaria de años anteriores, y se ha predicho la polución a un año vista.

El resultado de este proyecto es la visulación de la contaminación con el fin de explicar la tendecia de la contaminación y la comparación de polución entre las distintas zonas de la Madrid.

## Metodología ##

### Adquisición de datos
La información de la contaminación horaria es obtenida del portal web del ayuntamiento de Madrid X-X-X-X. Esta información es recopilada automáticamente mediante la técnica conocida en inglés como web scrapping. El resultado son ficheros .txt con los datos de contaminación de todas las estaciones de medición de contaminantes del ayuntamiento de Madrid. Este proceso se ha realizado empleando python. 

[`ScrappingFile.ipynb`](ScrappingFile.ipynb)
 
### Analisis exploratorio y limpieza de los datos
La información extraida de la página web

[`TFM.Rproj`](TFM.Rproj) [`data_cleansing.R`](data_cleansing.R)

### Modelling


[`TimeSeries.R`](TimeSeries.R)

### Data analysis and visualization

