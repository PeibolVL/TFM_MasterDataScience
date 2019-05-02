
library(lubridate)
library(dplyr)
library(tidyr)
library(stringr)
library(graphics)

# Creación de un data frame donde se irán añadiendo los datos de calidad de aire para todas las fechas
# contempladas
CalidadAire <- data.frame("ESTACION"=integer(),
                          "FECHA"=as.POSIXlt(character()),
                          "SO2"=character(),
                          "SO2_Valido"=character(),
                          "NO2"=character(),
                          "NO2_Valido"=character(),
                          "PM2.5"=character(),
                          "PM2.5_Valido"=character(),
                          "PM10"=character(),
                          "PM10_Valido"=character(),
                          "O3"=character(),
                          "O3_Valido"=character(),
                          stringsAsFactors=FALSE)

data_transformation <- function (dato){

  
  ## Esta función tiene por objetivo realizar la limpieza y la adaptación de los conjuntos de datos de 
  ## calidad del aire para estandarizarlos y poder, más tarde, unirlos

  df <- read.csv(dato,header = T,sep=";")
  
  # Se añade una columna FECHA que agrupa el año, el mes y el día.
  df <-  df %>% unite(FECHA,c("ANO","MES","DIA"),sep="_",remove=TRUE)
  
  # Se modifica el dataframe para tener únicamente las variables de estacion, magnitud, fecha y 
  # valores de polución.
  # Se filtra la selección para tener unicamente las magnitudes de polución que nos interesa.
  # 1,8,9,10,14 que corresponden a los contaminantes: SO2 (1), NO2 (8), PM2.5 (9), PM10 (10) y  O3 (14)
  df <- df %>% 
    select(ESTACION,MAGNITUD,FECHA,everything()) %>% select(everything(),-c(4:6)) %>% 
    filter(MAGNITUD==1|MAGNITUD==8|MAGNITUD==9|MAGNITUD==10|MAGNITUD==14)
  
  # Union de las columnas de H(variable de hora y observación de contaminación) y V (Validacion de si el dato se 
  # ha grabado correctamente) para luego separalas en la variable "Hora", "Polución" y "Valido"
  hora_dia=c("01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24")
  for(i in hora_dia){
    variable_position <- which(str_sub(variable.names(df),2,3)==i)
    new_variable=paste("H",i,sep="")
    validation <- variable.names(df[variable_position[2]])
    df <- unite(df,!!new_variable,!!new_variable:!!validation,sep="_",remove=TRUE)
  }
  
  df <- gather(df,key="Hora",value="Contaminacion",-ESTACION,-MAGNITUD,-FECHA) 
    
  # Preparación de la columna Hora y union con la columna FECHA
  df$Hora <-  str_replace_all(df$Hora,"H","")
  df <- df %>%  unite("FECHA","FECHA":"Hora",sep="-",remove=TRUE)
  df$FECHA <- ymd_h(df$FECHA,tz="Europe/Madrid")
  df$MAGNITUD <- as.numeric(df$MAGNITUD)
  
  # Orden del df por estacion, magnitud y fecha
  df <- df[order(df$ESTACION,df$MAGNITUD,df$FECHA),]
  
  #Selección de las magnitudes: NO2 (8), O3 (14), SO2 (1), PM10 (10) y PM2.5 (9)
  #df <- df %>% filter(MAGNITUD==1|MAGNITUD==8|MAGNITUD==9|MAGNITUD==10|MAGNITUD==14) %>% select(1:4,-5)
  
  # FALTA POR VER QUÉ SE HACE CON LOS VALORES DE VALIDO = N
  
  df <- df %>% spread("MAGNITUD","Contaminacion")
 
  # Renombre de las variables de Magnitud
  colnames(df)[colnames(df)=="1"] <- "SO2"
  colnames(df)[colnames(df)=="8"] <- "NO2"
  colnames(df)[colnames(df)=="9"] <- "PM2.5"
  colnames(df)[colnames(df)=="10"] <- "PM10"
  colnames(df)[colnames(df)=="14"] <- "O3"
  
  
  df <- df %>% separate(SO2,c("SO2","SO2_Valido"),sep="_",remove=TRUE)
  df <- df %>% separate(NO2,c("NO2","NO2_Valido"),sep="_",remove=TRUE)
  df <- df %>% separate(PM2.5,c("PM2.5","PM2.5_Valido"),sep="_",remove=TRUE)
  df <- df %>% separate(PM10,c("PM10","PM10_Valido"),sep="_",remove=TRUE)
  df <- df %>% separate(O3,c("O3","O3_Valido"),sep="_",remove=TRUE)
  
  return(df)
}

# Creación de una variable donde se alojará el listado de datos para distintos meses y años en CSV

archivos <- list.files(path = "./data/source", pattern = ".csv", all.files = F,
           full.names = T, recursive = T,
           ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)

# Alojo la información tratado por la función "data_transformation" en el df CalidadAire, lo ordeno por
# estación y fecha, y lo guardo en la carpeta ./data con formato CSV 
for(i in archivos){
  matriz <- data_transformation(i)
  CalidadAire <- bind_rows(CalidadAire,matriz)
  
  }

CalidadAire <- CalidadAire[order(CalidadAire$ESTACION,CalidadAire$FECHA),]

#### Outliers ####
# En el siguiente bucle se va a leer si el valor de cada contaminante (Cont) ha sido registrado correctamente
# valido ("V") o no ("N"). Y se va a sobreescribir el valor no válido según varias casuisticas 

for (Est in unique(CalidadAire$ESTACION)){
  for (Mag in c("SO2","NO2","PM2.5","PM10","O3")){
    print(c(Est,Mag))
    #Se indica el indice de la columna del contaminante
    Cont <-  which(colnames(CalidadAire)==Mag)
    #Se indica el indice de la columna de validación del contaminante
    Cont_val <- which(colnames(CalidadAire)==paste(Mag,"_Valido",sep=""))
    
    for (iter in which(CalidadAire[CalidadAire[1]==Est,][,Cont_val]=="N")){
      if(is.na(CalidadAire[CalidadAire[1]==Est,][iter,Cont])){
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=(as.numeric(CalidadAire[CalidadAire[1]==Est,][iter-1,Cont])+as.numeric(CalidadAire[CalidadAire[1]==Est,][iter+1,4]))/2
        }
      if(iter==1){
        # Selecciono la posición del primera fila que tiene un valor valido
        posf <- first(which(CalidadAire[CalidadAire[1]==Est,][,Cont_val]=="V"))
        # Igualo el valor de contaminación del la primera fila al valor de contaminación del primer valor valido
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=CalidadAire[CalidadAire[1]==Est,][posf,Cont]
        
      }else{
        # Si el valor N está en medio de la serie temporal de la estacion
        if (isTRUE(CalidadAire[CalidadAire[1]==Est,][iter+1,Cont_val]=="N" | iter==nrow(CalidadAire[CalidadAire[1]==Est,]))){
          # Si el valor de la siguente fila tiene valor N, entonces coge el valor de la fila anterior
          CalidadAire[CalidadAire[1]==Est,][iter,Cont]=CalidadAire[CalidadAire[1]==Est,][iter-1,Cont]
          
        }else{
          # Si el valor de la siguente fila tiene valor V, entonces coge el valor de la fila anterior y el de la siguiente
          # y pon el valor de la media de: iter= ((iter+1)+(iter-1))/2
          CalidadAire[CalidadAire[1]==Est,][iter,Cont]=(as.numeric(CalidadAire[CalidadAire[1]==Est,][iter-1,Cont])+as.numeric(CalidadAire[CalidadAire[1]==Est,][iter+1,4]))/2
        }
      }
    }
  }
  }


write.csv(CalidadAire,"./data/CalidadAire.csv",quote=F,row.names=F)

# Se va a "extraer" los datos de cada estación y se van a alojar en un csv por estación
for (e in unique(CalidadAire$ESTACION)){
    name <- paste("Calidad_Estacion", e, sep = "")
    assign(name, CalidadAire %>% filter(ESTACION==e) %>% select(FECHA,SO2,NO2,PM2.5,PM10,O3))
    write.csv(get(name),paste("./data/",name,".csv",sep=""),quote=F,row.names=F)
  }


# ya tengo los datos de calidad del aire pero hay algunas estaciones que no recogen todos los datos,
# qué hacer entonces? 
#   - realizar interpolación entre datos comunes?
#   - realizar interpolación por cada contaminante, sacar ICA y luego realizar la predicción con ARIMA 
#     para los siguientes meses