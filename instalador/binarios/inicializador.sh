#!/bin/bash

. ../libs/config.sh

ARCHIVO_LOG="../libs/log.sh"

#******************** FUNCIONES ********************

print()
{
    # muestra un mensaje obtenido en $1 por STDOUT

    mensaje=$1
    $ARCHIVO_LOG "Inicializador" "Info" "$mensaje"
    echo $mensaje
}

error()
{
    # muestra un mensaje obtenido en $1 por STDOUT

    mensaje=$1
    $ARCHIVO_LOG "Inicializador" "Error" "$mensaje"
    echo $mensaje
}

# $1 es el valor y $2 es el nombre de la variable
# valida si la variable tiene asignada algun valor, si no se termina el programa.
checkVar() {
    if [ -z "$1" ]
    then
        error "No se puede inicializar la variable $2."
        return 1
    fi
}

# se toman los valores de las variables del archivo de configuracion que se encuentran definidos por "="
setVariablesDeEntorno() {
    DIRBIN=`config_get $FILECONF BINARIOS`
    DIRMAE=`config_get $FILECONF MAESTROS`
    DIRREC=`config_get $FILECONF RECHAZADOS`
    DIROK=`config_get $FILECONF ACEPTADOS`
    DIRPROC=`config_get $FILECONF VALIDADOS`
    DIRINFO=`config_get $FILECONF REPORTES`
    DIRLOG=`config_get $FILECONF LOGS`
    DIRNOV=`config_get $FILECONF NOVEDADES`
    DIRLIBS=`readlink -m "../libs/"`
}

# inicializo variables
inicializarVariables() {
    PATH=$PATH:$DIRBIN
    export DIRBIN
    export DIRMAE
    export DIRREC
    export DIROK
    export DIRPROC
    export DIRINFO
    export DIRLOG
    export DIRNOV
    export DIRLIBS
}


# chequeo si las variables fueron seteadas
verificarVariables() {
    checkVar "$DIRBIN" "DIRBIN" || return 1
    checkVar "$DIRMAE" "DIRMAE" || return 1
    checkVar "$DIRREC" "DIRREC" || return 1
    checkVar "$DIROK" "DIROK" || return 1
    checkVar "$DIRPROC" "DIRPROC" || return 1
    checkVar "$DIRINFO" "DIRINFO" || return 1
    checkVar "$DIRLOG" "DIRLOG" || return 1
    checkVar "$DIRNOV" "DIRNOV" || return 1
}

# verifico los permisos
# si se retorna 0 es porque los archivos tienen los permisos adecuados, en caso contrario, se retorna 1
verificarPermisos() {

    permiso=0

    for script in $(ls $DIRMAE); do
        chmod +x "$DIRMAE/$script"

        if [[ ! -x "$DIRMAE/$script" ]]; then
            let permiso+=1
        fi
    done

    for file in $(ls $DIRMAE); do
        chmod u=rx "$DIRMAE/$file"
        if [[ ! -r "$DIRMAE/$file" ]]; then
            let permiso+=1
        fi
    done

    if [[ "$permiso" == 0 ]]; then
        # los archivos tienen permiso
        return 0
    else
        # los archivos no tienen permiso
        return 1
    fi
}

iniciarDemonio() {                                                                                  #VERIFICAR NOMBRE DEMONIO
    # llama al proceso que incia el demonio
    ${DIRBIN}/monitor.sh start
}


#******************** EJECUCION ********************

DIRCONF="`dirname $0`/../../dirconf"  # TODO: usar variables setteadas por el instalador
FILECONF="$DIRCONF/instalador.conf" #VERIFICAR NOMBRE
LIBS="`dirname $0`/../libs"  # TODO: usar variables setteadas por el instalador

# valida que se haya ingresado un parámetro
if [ "$FILECONF" == "" ]
then
    error "Debe indicar por parámetro un archivo de configuracion."
    return 1

# valida que el archivo de configuracion tenga permiso de lectura
elif ! test -r "$FILECONF"
then
    error "El archivo no puede ser leído."
    return 1
fi


# veo si ya fue iniciado el ambiente
if [ "$AMBIENTE_INICIALIZADO" = "true" ]
then
    print "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
    return 1 #retorna 1 para indicar error
fi


# seteo variables
setVariablesDeEntorno
inicializarVariables
print "Se setearon las variables de entorno."

# chequeo variables
if ! verificarVariables ; then
    error 'variables no incializadas'
    return 1
fi

# verifico permisos
verificarPermisos
resultado=$?
if [ $resultado != 0 ]; then
# se termina la ejecucion
    error "No se pueden dar los permisos a los archivos."
else
    print "Ambiente Inicializado."
fi

export AMBIENTE_INICIALIZADO="true"
print "El sistema se ha iniciado correctamente."

if "$LIBS/pregunta.sh" "¿Desea iniciar el Demonio?"
then
    print "S: Iniciando Demonio."
    iniciarDemonio
else
    print "N: No se inicia el Demonio. Saliendo de la aplicación."
    echo "Puede ejecutar el Demonio manualmente, con el comando ./Demonio"                        #VERIFICAR
fi
