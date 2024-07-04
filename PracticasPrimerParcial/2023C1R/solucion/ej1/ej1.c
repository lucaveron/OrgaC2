#include "ej1.h"

uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, pago_t* arr_pagos){

    uint32_t *arr_acumulado = calloc(10, sizeof(uint32_t)); //creo los 10 
    
    for (int i = 0; i < cantidadDePagos; i++)
    {
        if (arr_pagos[i].aprobado == 1){
            arr_acumulado[arr_pagos[i].cliente] += arr_pagos[i].monto;
        }
    }

    return arr_acumulado;
    
}

uint8_t en_blacklist(char* comercio, char** lista_comercios, uint8_t n){
    uint8_t res = 0;
    for (int i = 0; i < n; i++)
    {
        if (strcmp(comercio, lista_comercios[i])){
            res = 1;
        }
    }
    
    return res;

}

pago_t** blacklistComercios(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios){

    int contador = 0;
    // recorrida para determinar tamanio del array que vamos a devolver
    for (int i = 0; i < cantidad_pagos; i++)
    {
        if (en_blacklist(arr_pagos[i].comercio,arr_comercios,size_comercios)){
            contador++;
        }
    }
    pago_t** blacklistComercios = malloc (contador * sizeof(pago_t*));

    // recorrida para agregar pagos al array reservado en heap
    int indexActualArrayBlacklist = 0; 

    for (int i = 0; i < cantidad_pagos; i++)
    {
        if (en_blacklist(arr_pagos[i].comercio,arr_comercios,size_comercios)){
            // reserva memoria en heap para el puntero al pago
            pago_t* pagoEnHeap = malloc(sizeof(pago_t)); //guardo espacio para la estructura pago, asi puedo devolver el puntero a la misma
            // setea valores del pago en heap
            pagoEnHeap->aprobado = arr_pagos[i].aprobado;
            pagoEnHeap->cliente = arr_pagos[i].cliente;
            pagoEnHeap->comercio = arr_pagos[i].comercio;
            pagoEnHeap->monto = arr_pagos[i].monto;

            blacklistComercios[indexActualArrayBlacklist] = pagoEnHeap;
            indexActualArrayBlacklist++;
        }
    }

    return blacklistComercios;
}


