#### Libraries ####
library(forecast)
library(tseries)
library(fpp2)
# Se crea la serie temporal, cogiendo las columnas que nos interesan e indicando el año de inicio y la 
# frecuencia que es nuestro caso son las horas anuales
E8_ts <- ts(Calidad_Estacion8[,3:7], start = c(2018), frequency = 8760)

# Se dibuja la serie para ver qué tenemos
autoplot(E8_ts,facets=T)

# Se pueden ver los datos también por temporada
ggseasonplot(E8_ts,facets=F)

#para detectar el outlier de la serie
which.max()

#Comprobar si la series es estacionaria
adf.test() #p-value < 0.05 indicates the TS is stationary
kpss.test()

#C