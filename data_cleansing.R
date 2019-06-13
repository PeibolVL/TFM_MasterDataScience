library(lubridate)
library(dplyr)
library(tidyr)
library(stringr)
library(graphics)


#### Import ####

# Creación de un data frame donde se irán añadiendo los datos de calidad de aire para todas las fechas
# contempladas
CalidadAire <- data.frame("ESTACION"=integer(),
                          "FECHA"=as.POSIXlt(character()),
                          "SO2"=numeric(),
                          "SO2_Valido"=character(),
                          "NO2"=numeric(),
                          "NO2_Valido"=character(),
                          "PM2.5"=numeric(),
                          "PM2.5_Valido"=character(),
                          "PM10"=numeric(),
                          "PM10_Valido"=character(),
                          "O3"=numeric(),
                          "O3_Valido"=character(),
                          stringsAsFactors=FALSE)

# Creación de una variable donde se alojará el listado de datos para distintos meses y años en CSV

archivos <- list.files(path = "./data/source", pattern = ".txt", all.files = F,
                       full.names = T, recursive = T,
                       ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)



#### Cleansing ####

data_transformation <- function (dato){
  
  # Esta función tiene por objetivo realizar la limpieza y la adaptación de los conjuntos de datos de 
  # calidad del aire para estandarizarlos.
  
  #Se definen el nombre y la clase de cada una de las series que tendrá el dataframe
  columnas <- c("PROVINCIA",'MUNICIPIO','ESTACION','MAGNITUD','TECNICA','PERIODO_ANALISIS','ANO','MES','DIA','H01','V01','H02','V02','H03','V03','H04','V04','H05','V05','H06','V06','H07','V07','H08','V08','H09','V09','H10','V10','H11','V11','H12','V12','H13','V13','H14','V14','H15','V15','H16','V16','H17','V17','H18','V18','H19','V19','H20','V20','H21','V21','H22','V22','H23','V23','H24','V24')
  Classes <- c(rep("integer",9),rep(c("numeric","character"),each=1,len=48))
  
  #Se aloja los datos en un dataframe 
  df <- read.table(dato, header=FALSE, sep = ",", dec=".", fill=TRUE,col.names = columnas,colClasses = Classes ) %>% as.data.frame()
  
  # Se añade una columna FECHA que agrupa el año, el mes y el día.
  df <-  df %>% unite(FECHA,c("ANO","MES","DIA"),sep="_",remove=TRUE)
  
  # Se modifica el dataframe para tener únicamente las variables de estacion, magnitud, fecha y 
  # valores de polución.
  # Se filtra la selección para tener unicamente las magnitudes de polución que nos interesa.
  # 1,8,9,10,14 que corresponden a los contaminantes: SO2 (1), NO2 (8), PM2.5 (9), PM10 (10) y  O3 (14)
  df <- df %>% 
    select(ESTACION,MAGNITUD,FECHA,everything(),-c(PROVINCIA,MUNICIPIO,TECNICA,PERIODO_ANALISIS)) %>% 
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
  df <- df %>%  unite("FECHA","FECHA":"Hora",sep="_",remove=TRUE)
  df$FECHA <- ymd_h(df$FECHA,locale = "es_ES.UTF-8")
  df$MAGNITUD <- as.character(df$MAGNITUD)
  
  # Orden del df por estacion, magnitud y fecha
  df <- df[order(df$ESTACION,df$MAGNITUD,df$FECHA),]

  df <- reshape(df, timevar="MAGNITUD",idvar=c("ESTACION","FECHA"),direction="wide")
  #df <- spread(df,key = "MAGNITUD",value = "Contaminacion")

  # Renombre de las variables de Magnitud
  names(df)[names(df)=="Contaminacion.1"] <- "SO2"
  names(df)[names(df)=="Contaminacion.8"] <- "NO2"
  names(df)[names(df)=="Contaminacion.9"] <- "PM2.5"
  names(df)[names(df)=="Contaminacion.10"] <- "PM10"
  names(df)[names(df)=="Contaminacion.14"] <- "O3"
  
  # Se separa la columna de los contaminantes en dos, una de valores y otra de la validez del dato
  df <- separate(df,SO2,c("SO2","SO2_Valido"),sep="_",remove=TRUE,convert = TRUE)
  df <- separate(df,NO2,c("NO2","NO2_Valido"),sep="_",remove=TRUE,convert = TRUE)
  df <- separate(df,PM2.5,c("PM2.5","PM2.5_Valido"),sep="_",remove=TRUE,convert = TRUE)
  df <- separate(df,PM10,c("PM10","PM10_Valido"),sep="_",remove=TRUE,convert = TRUE)
  df <- separate(df,O3,c("O3","O3_Valido"),sep="_",remove=TRUE,convert = TRUE)
  
  return(df)
}

#### Outliers ####
# En el siguiente bucle se va a leer si el valor de cada contaminante (Cont) ha sido registrado correctamente
# valido ("V") o no ("N"). Y se va a sobreescribir el valor no válido según varias casuisticas 
#funcion para quitar outliers y n 

remove_outliers <- function(Station){
  # Esta función tiene por objetivo realizar la limpieza y la adaptación de los conjuntos de datos de 
  # calidad del aire para estandarizarlos y poder, más tarde, unirlos
  
  for (Mag in c("SO2","NO2","PM2.5","PM10","O3")){
    print(Mag)
    #Se indica el indice de la columna del contaminante
    Cont <-  which(colnames(Station)==Mag)
    #Se indica el indice de la columna de validación del contaminante
    Cont_val <- which(colnames(Station)==paste(Mag,"_Valido",sep=""))
    outliers_na <- which(is.na(Station[,Cont])==TRUE)
    outliers_N <- which(Station[,Cont_val]=="N")
    outliers <- append(outliers_N,outliers_na) %>% unique() %>% sort()
    if(length(which(is.na(Station[,Cont])==TRUE))==length(Station[,Cont])){
      #print('ha pasado')
      next
    }
    for (iter in outliers){
      if(iter==1){
        # Selecciono la posición del primera fila que tiene un valor valido
        posf <- first(which(Station[,Cont_val]=="V"))
        # Igualo el valor de contaminación del la primera fila al valor de contaminación del primer valor valido
        Station[iter,Cont]=Station[posf,Cont]
        #print('era el primero')
      }else if(isTRUE(isTRUE(Station[iter,Cont_val]=="N" & Station[iter+1,Cont_val]=="N")| iter==nrow(Station))){
        # Si el valor N está en medio de la serie temporal de la estacion
        # Si el valor de la fila actual es N y el de la siguente fila tiene valor N, entonces coge el valor de la fila anterior
        Station[iter,Cont]=Station[iter-1,Cont]
        #print('el siguiente era N')
      }else if(isTRUE(Station[iter,Cont_val]=="N" & Station[iter+1,Cont_val]=="V")){
        # Si el valor de la fila actual es N y el de la siguente fila tiene valor V, entonces coge el valor de la fila anterior y el de la siguiente
        # y pon el valor de la media de: iter= ((iter+1)+(iter-1))/2
        Station[iter,Cont]=(as.numeric(Station[iter-1,Cont])+as.numeric(Station[iter+1,Cont]))/2
        #print('media a la N')
      }
    }
  }

  return(Station)
}

# Alojo la información tratado por la función "data_transformation" en el df CalidadAire, lo ordeno por
# estación y fecha, y lo guardo en la carpeta ./data con formato CSV 
for(i in archivos){
  matriz <- data_transformation(i)
  CalidadAire <- bind_rows(CalidadAire,matriz)
  }

CalidadAire <- CalidadAire[order(CalidadAire$ESTACION,CalidadAire$FECHA),]

#### Export ####

write.csv(CalidadAire,"./data/CalidadAire.csv",quote=F,row.names=F)

# Se va a "extraer" los datos de cada estación y se van a alojar en un csv por estación
Estaciones <- c(4,8,11,16,18,35,36,38,39,40,47,48,49,50,56)
for (e in Estaciones){#unique(CalidadAire$ESTACION)){
    name <- paste("Calidad_Estacion", e, sep = "")
    Estacion <- CalidadAire %>% filter(ESTACION==e) %>% remove_outliers() %>% select(FECHA,SO2,NO2,PM2.5,PM10,O3)
    Estacion[is.na(Estacion)] <- 0
    assign(name,Estacion)
    write.csv(get(name),paste("./data/",name,".csv",sep=""),quote=F,row.names=F)
  }


#### NA treatment ####
for (Est in unique(CalidadAire$ESTACION)){
  for (Mag in c("SO2","NO2","PM2.5","PM10","O3")){
    print(c(Est,Mag))
    #Se indica el indice de la columna del contaminante
    Cont <-  which(colnames(CalidadAire)==Mag)
    #Se indica el indice de la columna de validación del contaminante
    Cont_val <- which(colnames(CalidadAire)==paste(Mag,"_Valido",sep=""))
    outliers_na <- which(is.na(CalidadAire[CalidadAire[1]==Est,][,Cont])==TRUE)
    outliers_N <- which(CalidadAire[CalidadAire[1]==Est,][,Cont_val]=="N")
    outliers <- append(outliers_N,outliers_na) %>% unique() %>% sort()
    
    if(length(which(is.na(CalidadAire[CalidadAire[1]==Est,][,Cont])==TRUE))==length(CalidadAire[CalidadAire[1]==Est,][,Cont])){
      print('ha pasado')
      next
    }
    
    for (iter in outliers){
      if(iter==1){
        # Selecciono la posición del primera fila que tiene un valor valido
        posf <- first(which(CalidadAire[CalidadAire[1]==Est,][,Cont_val]=="V"))
        # Igualo el valor de contaminación del la primera fila al valor de contaminación del primer valor valido
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=CalidadAire[CalidadAire[1]==Est,][posf,Cont]
        print('era el primero')
      }else if(isTRUE(isTRUE(CalidadAire[CalidadAire[1]==Est,][iter,Cont_val]=="N" & CalidadAire[CalidadAire[1]==Est,][iter+1,Cont_val]=="N")| iter==nrow(CalidadAire[CalidadAire[1]==Est,]))){
        # Si el valor N está en medio de la serie temporal de la estacion
        # Si el valor de la fila actual es N y el de la siguente fila tiene valor N, entonces coge el valor de la fila anterior
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=CalidadAire[CalidadAire[1]==Est,][iter-1,Cont]
        print('el siguiente era N')
      }else if(isTRUE(CalidadAire[CalidadAire[1]==Est,][iter,Cont_val]=="N" & CalidadAire[CalidadAire[1]==Est,][iter+1,Cont_val]=="V")){
        # Si el valor de la fila actual es N y el de la siguente fila tiene valor V, entonces coge el valor de la fila anterior y el de la siguiente
        # y pon el valor de la media de: iter= ((iter+1)+(iter-1))/2
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=(as.numeric(CalidadAire[CalidadAire[1]==Est,][iter-1,Cont])+as.numeric(CalidadAire[CalidadAire[1]==Est,][iter+1,Cont]))/2
        print('media a la N')
      }else if(isTRUE(is.na(CalidadAire[CalidadAire[1]==Est,][iter,Cont])==TRUE & is.na(CalidadAire[CalidadAire[1]==Est,][iter+1,Cont])==TRUE)){
        # Si el valor de la fila actual es NA y el de la siguente fila tiene valor NA, coge el valor anterior
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=CalidadAire[CalidadAire[1]==Est,][iter-1,Cont]
        print('ha cambiado na')
      }else{
        CalidadAire[CalidadAire[1]==Est,][iter,Cont]=(as.numeric(CalidadAire[CalidadAire[1]==Est,][iter-1,Cont])+as.numeric(CalidadAire[CalidadAire[1]==Est,][iter+1,Cont]))/2
        print('ha cambiado na con media')
      }
    }
  }
}
