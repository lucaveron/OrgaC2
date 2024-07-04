#include "ej1.h"

list_t* listNew(){
  list_t* l = (list_t*) malloc(sizeof(list_t));
  l->first=NULL;
  l->last=NULL;
  return l;
}

void listAddLast(list_t* pList, pago_t* data){
    listElem_t* new_elem= (listElem_t*) malloc(sizeof(listElem_t));
    new_elem->data=data;
    new_elem->next=NULL;
    new_elem->prev=NULL;
    if(pList->first==NULL){
        pList->first=new_elem;
        pList->last=new_elem;
    } else {
        pList->last->next=new_elem;
        new_elem->prev=pList->last;
        pList->last=new_elem;
    }
}


void listDelete(list_t* pList){
    listElem_t* actual= (pList->first);
    listElem_t* next;
    while(actual != NULL){
        next=actual->next;
        free(actual);
        actual=next;
    }
    free(pList);
}

uint8_t contar_pagos_aprobados(list_t* pList, char* usuario){
    uint8_t cont=0;
    listElem_t* actual= (pList->first);
    while(actual != NULL){
        if(strcmp(actual->data->cobrador,usuario)==0){ //si estamo en un pago que justo es del user
            if(actual->data->aprobado == 1){ //si el estado es aprobado
                cont++;
            }
        }
        actual=actual->next;
    }
    return cont;
}

uint8_t contar_pagos_rechazados(list_t* pList, char* usuario){
    uint8_t cont=0;
    listElem_t* actual= (pList->first);
    while(actual != NULL){
        if(strcmp(actual->data->cobrador,usuario)==0){ //si estamo en un pago que justo es del user
            if(actual->data->aprobado == 0){ //si el estado es rechazado
                cont++;
            }
        }
        actual=actual->next;
    }
    return cont;
}

pagoSplitted_t* split_pagos_usuario(list_t* pList, char* usuario){
    //la idea es armar un structu pagoSplitted_t para cada usuario

    pagoSplitted_t* pagos = (pagoSplitted_t*) malloc(sizeof(pagoSplitted_t)); //guardo espacio para el puntero al pago_splitted
        
    uint8_t cant_aprobados = contar_pagos_aprobados(pList,usuario);
    uint8_t cant_rechazados = contar_pagos_rechazados(pList,usuario);

    pagos->cant_aprobados = cant_aprobados;
    pagos->cant_rechazados = cant_rechazados;

    //faltan los arreglos a cada  uno de ellos,para eso hay que guardar espacio tambien

    pago_t** aprobados = (pago_t**) malloc( cant_aprobados *  sizeof(pago_t*));
    pago_t** rechazados = (pago_t**) malloc( cant_rechazados *  sizeof(pago_t*));

    int indice_aprobados = 0;
    int indice_rechazados = 0;

    listElem_t* actual= (pList->first);
    while(actual != NULL){
        if(strcmp(actual->data->cobrador,usuario)==0){ //si estamo en un pago que justo es del user
            if(actual->data->aprobado == 0){ //si el estado es rechazado
                rechazados[indice_rechazados] = actual->data; //el puntero al pago
                indice_rechazados++;
            }else {
                aprobados[indice_aprobados] = actual->data; //el puntero al pago
                indice_aprobados++;
            }
        }
        actual=actual->next;
    }

    pagos->aprobados = aprobados;
    pagos->rechazados = rechazados;

    return pagos;
}