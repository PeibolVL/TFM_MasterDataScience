#### Libraries ####
library(ggplot2)
library(fma)
library(expsmooth)
library(forecast)
library(tseries)
library(fpp2)
library(zoo)

# La regresión empleando el modelo ARIMA se realizará sobre el contaminante NO2. Para las estaciones:
# 4,8,11,16,18,35,36,38,39,40,47,48,49,50,56

# Se crea la serie temporal, cogiendo las columnas que nos interesan e indicando el año de inicio y la 
# frecuencia que es nuestro caso son las horas anuales
Estaciones <- c(4,8,11,16,18,35,36,38,39,40,47,48,49,50,56)
horizon <- 24*365
NO2 <- data.frame("FECHA"=as.POSIXlt(character()))

for (fest in Estaciones){
 station <- paste('Calidad_Estacion',fest,sep='')
 punto <- paste('Estacion',fest,sep='')
 
 # Se coge la primera fecha que no sea NA y se pasa a decimal para poder introducirla en el modelo
 fechainicio <- decimal_date(first(na.omit(get(station)$FECHA))) 
 fechafinal <- decimal_date(last(na.omit(get(station)$FECHA)))
 
 # Se crea una serie temportal del contaminante de la columna 3, que corresponde a NO2
 data <- ts(get(station)[,c(3)],start = fechainicio, end=fechafinal,frequency = 8760)
 
 # Se realiza el modelo que consiste en una descomposición Loess + autoarima
 data %>% mstl() %>% autoplot()
 
 data_forecast <- stlf(data,method="arima",h=horizon,s.window="periodic",robust=TRUE,level=c(95),lambda = "auto")
 
 checkresiduals(data_forecast)
 
 
 # Tanto la serie de datos como la serie de predicción se pasan a dataframe
 df_data <- data.frame(FECHA=round_date(date_decimal(index(data)),unit='hour'),punto=as.numeric(data))
 dataforecast_time <- as.numeric(time(data_forecast$mean)) %>% date_decimal() %>% round_date(unit='hour')
 df_dataforecast <- data.frame(FECHA=dataforecast_time,punto=as.numeric(data_forecast$mean))
 
 # Se unen ambos dataframe para tener los datos completos de esa estación para ese contaminante
 station_forecast <- rbind(df_data,df_dataforecast)
 names(station_forecast)[names(station_forecast)=="punto"] <- punto
 
 if (length(NO2$FECHA)==0){
   NO2 <- station_forecast
 }else{
   NO2 <- merge(NO2,station_forecast,by="FECHA")
 }
}

write.csv(NO2,"./data/NO2_estaciones.csv",quote=F,row.names=F)
