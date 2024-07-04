#include "ej1.h"

uint32_t cuantosTemplosClasicos_c(templo *temploArr, size_t temploArr_len){
    uint32_t cuantos = 0;
    for (int i = 0; i < temploArr; i++)
    {
        if((temploArr[i].colum_corto * 2) + 1 == temploArr[i].colum_largo){
            cuantos++;
        }
    }

    return cuantos;
    
}
  
templo* templosClasicos_c(templo *temploArr, size_t temploArr_len){

    uint32_t cuantos = cuantosTemplosClasicos_c(temploArr, temploArr_len);
    //pido memoria ahora

    templo* templosClasicos = malloc(sizeof(templo) * cuantos);

    int indice = 0;
    for (int i = 0; i < temploArr_len; i++)
    {
        if((temploArr[i].colum_corto * 2) + 1 == temploArr[i].colum_largo){
            templosClasicos[indice] = temploArr[i];
            indice++;
        }
    }

    return templosClasicos;
    
}
 