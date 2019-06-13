Analisis de la contaminación de NO<sub>2</sub> de Madrid
===========================================================
`#DataScience` `#Python` `#R` `#Forecast` `#Pollution`

## Objetivo ##
El objeto de este trabajo es el analisis de la contaminación en Madrid adapatado a la [`Orden TEC/351/72019`](state_of_art/Orden_TEC:351:2019.pdf). Para ello se han tomado datos de la contaminación horaria de años anteriores, y se ha predicho la polución a un año vista.

El resultado de este proyecto es la visulación de la contaminación con el fin de explicar la tendecia de la contaminación y la comparación de la polución entre las distintas zonas de la Madrid.

## Metodología ##

### Adquisición de datos
La información de la contaminación horaria es obtenida del portal web del [Ayuntamiento de Madrid](https://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=f3c0f7d512273410VgnVCM2000000c205a0aRCRD&vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD&vgnextfmt=default). Esta información es recopilada automáticamente mediante la técnica conocida en inglés como web scrapping, recogida en el documento [`ScrappingFile.ipynb`](ScrappingFile.ipynb). 

El resultado son ficheros .txt con los datos de contaminación de todas las estaciones de medición de contaminantes del ayuntamiento de Madrid. Este proceso se ha realizado empleando python. 
 
### Analisis exploratorio y limpieza de los datos
La información extraida de la página web es cargada en R Studio para ser tratada con el fin de ser la entrada para el modelo de predicción. 
Para la limpieza de los datos se empleará el fichero [`data_cleansing.R`](data_cleansing.R) Este tratamiento de la información de contaminación consistirá en un analisis de las estaciones y una estandarización de estos de forma que se puedan manipular en una dataframe, como en el que se muestra en la siguiente tabla. Debido a que la directiva europea en materia de contaminación estipula unos determinados contaminantes como dañinos, se van a seleccionar aquellos que se utilizan para obtener el Indice de Calidad del Aire (ICA)

|Estacion|Fecha|SO<sub>2</sub>|NO<sub>2</sub>|PM<sub>2.5</sub>|PM<sub>10</sub>|O<sub>3</sub>|
|--------|-----|---|---|-----|----|--|
|nº|aaaa-mm-dd hh|[ppm]|[ppm]|[ppm]|[ppm]|[ppm]|

Analizando las estaciones se observa que no todas ellas miden todos los contaminantes,por lo que se trabajará con los puntos de medida que recojan el NO<sub>2</sub>, que es agente recogido mayormente recogido por las estaciones.

[`TFM.Rproj`](TFM.Rproj) 

### Modelling


[`TimeSeries.R`](TimeSeries.R)

### Data analysis and visualization

### Especificaciones del software
R version 3.5.2 (2018-12-20) -- "Eggshell Igloo"
Copyright (C) 2018 The R Foundation for Statistical Computing
Platform: x86_64-apple-darwin15.6.0 (64-bit)
