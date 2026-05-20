---
name: Instrucciones de Compute Budget
summary: Datos de instrucción del Compute Budget Program — fija el límite de unidades de cómputo y la comisión de prioridad por CU. Un discriminador de 1 byte más un entero pequeño; las palancas tras las comisiones de prioridad.
---

## Qué es

El Compute Budget Program no mueve datos — configura los *recursos* que se permite consumir a una transacción y la comisión de prioridad que está dispuesta a pagar. Dos instrucciones importan más: fijar el límite de unidades de cómputo y fijar el precio por unidad de cómputo.

## Por qué existe

Cada transacción recibe un presupuesto de cómputo por defecto (200k CU × número de instrucciones, con tope). Las transacciones complejas necesitan más, y durante la congestión pujas por la inclusión pagando una comisión de prioridad por unidad de cómputo. Estas instrucciones son cómo un cliente declara «necesito tanto cómputo» y «pagaré tanto por unidad».

## Diseño de bytes

Los datos de instrucción de Compute Budget usan un **discriminador de 1 byte** seguido de un entero pequeño de ancho fijo:

| Discriminador (u8) | Variante | Carga útil | Total |
|----:|----------|-----------|------:|
| `1` | `RequestHeapFrame`              | `bytes: u32` | 5 bytes |
| `2` | `SetComputeUnitLimit`           | `units: u32` | 5 bytes |
| `3` | `SetComputeUnitPrice`           | `micro_lamports: u64` | 9 bytes |
| `4` | `SetLoadedAccountsDataSizeLimit`| `bytes: u32` | 5 bytes |

El valor de `SetComputeUnitPrice` está en **micro-lamports por unidad de cómputo** — la comisión de prioridad. Comisión de prioridad total = `límite_de_unidades_de_cómputo × precio / 1.000.000` lamports.

## Dónde lo encuentras

Casi toda transacción moderna antepone una o dos instrucciones de Compute Budget. Las billeteras y los agregadores las añaden automáticamente para fijar un límite de CU realista y una comisión de prioridad competitiva durante la congestión.

## Errores comunes

- **Discriminador de 1 byte, a diferencia de System/Stake/Vote.** Compute Budget se aparta de la convención bincode de 4 bytes — es una etiqueta de 1 byte. No asumas que todos los programas nativos comparten una codificación.
- **El precio es micro-lamports por CU, no lamports.** `SetComputeUnitPrice(1000)` son 1000 micro-lamports/CU = 0,001 lamports/CU. Multiplica por el límite de CU para obtener la comisión de prioridad total.
- **Fijar un límite demasiado bajo aborta la transacción.** Si la ejecución excede `SetComputeUnitLimit`, la transacción falla con «exceeded CUs» — pero igual pagas la comisión base. Estima vía simulación primero.
- **Solo cuenta la primera de cada tipo.** Dos instrucciones `SetComputeUnitLimit` en una transacción es un error; el runtime espera como máximo una de cada.
