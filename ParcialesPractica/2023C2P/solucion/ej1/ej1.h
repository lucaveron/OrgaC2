#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>
#define USE_ASM_IMPL 1

/* Payments */
typedef struct
{
    uint8_t monto; // 0
    uint8_t aprobado; // 1
    char *pagador; // 8
    char *cobrador; // 16
} pago_t; // 24

typedef struct
{
    uint8_t cant_aprobados; // 0
    uint8_t cant_rechazados; // 1
    pago_t **aprobados; // 8
    pago_t **rechazados; // 16
} pagoSplitted_t; //24

/* List */

typedef struct s_listElem
{
    pago_t *data; // 0
    struct s_listElem *next; // 8
    struct s_listElem *prev; // 16
} listElem_t;

typedef struct s_list
{
    struct s_listElem *first; // 0
    struct s_listElem *last; // 8
} list_t;

list_t *listNew();
void listAddLast(list_t *pList, pago_t *data);
void listDelete(list_t *pList);

uint8_t contar_pagos_aprobados(list_t *pList, char *usuario);
uint8_t contar_pagos_aprobados_asm(list_t *pList, char *usuario);

uint8_t contar_pagos_rechazados(list_t *pList, char *usuario);
uint8_t contar_pagos_rechazados_asm(list_t *pList, char *usuario);

pagoSplitted_t *split_pagos_usuario(list_t *pList, char *usuario);

pagoSplitted_t *split_pagos_usuario_asm(list_t *pList, char *usuario);
