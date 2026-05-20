---
name: Transacción v0 (Versionada)
summary: El formato de transacción versionado — un prefijo de versión de 1 byte, el mismo cuerpo de mensaje que una transacción heredada, más una sección de búsquedas en tablas de direcciones que referencia cuentas almacenadas en Address Lookup Tables.
---

## Qué es

Una transacción v0 es el formato versionado en el cable. Es una [transacción heredada](/learn/transactions/legacy-transaction) con dos añadidos: un prefijo de versión de 1 byte al inicio del mensaje, y una sección de búsquedas en tablas de direcciones al final que extrae cuentas extra de las [Address Lookup Tables](/learn/transactions/address-lookup-table) por índice en lugar de incrustar sus claves de 32 bytes.

## Por qué existe

Las transacciones heredadas incrustan cada cuenta como 32 bytes en bruto, y el límite de 1.232 bytes te topa en ~35 cuentas. Las rutas DeFi modernas (un swap de Jupiter por cinco pools) superan eso. Las transacciones v0 referencian cuentas almacenadas on-chain en tablas de búsqueda por índice de 1 byte, así que una transacción puede tocar cientos de cuentas manteniéndose bajo el límite de tamaño.

## Diseño de bytes

El vector de firmas y el cuerpo central del mensaje son idénticos a una transacción heredada. Las diferencias son el byte de versión inicial y la sección de búsquedas final.

| Sección | Campo | Tipo | Notas |
|---------|-------|------|-------|
| signatures | recuento + `signature[]` | `compact-u16` + 64 bytes c/u | Igual que en la heredada. |
| message | `prefix` | 1 byte | El bit alto a 1 (`0x80`) marca «versionada»; los 7 bits bajos son la versión (`0` para v0). Así que el primer byte del mensaje es `0x80`. |
| message | cabecera (3 bytes) | 3 × `u8` | `num_required_signatures`, `num_readonly_signed`, `num_readonly_unsigned` — igual que en la heredada. |
| message | recuento de claves + `account_keys[]` | `compact-u16` + 32 bytes c/u | Las claves incluidas *estáticamente* (firmantes + las que no vienen de una tabla). |
| message | `recent_blockhash` | 32 bytes | Igual que en la heredada. |
| message | recuento de instrucciones + `instructions[]` | `compact-u16` + … | Misma subestructura de instrucción que en la heredada. |
| message | recuento de búsquedas + `address_table_lookups[]` | `compact-u16` + … | Nuevo en v0 — ver abajo. |

Cada **búsqueda en tabla de direcciones** es:

| Campo | Tipo | Notas |
|-------|------|-------|
| `account_key` | 32 bytes | La cuenta Address Lookup Table de la que leer. |
| recuento escribible + `writable_indexes[]` | `compact-u16` + 1 byte c/u | Índices en la tabla de cuentas cargadas como **escribibles**. |
| recuento solo-lectura + `readonly_indexes[]` | `compact-u16` + 1 byte c/u | Índices en la tabla de cuentas cargadas como **solo lectura**. |

## Cómo funciona el espacio de índices de cuenta

Las instrucciones siguen referenciando cuentas por un solo índice, pero en v0 ese espacio de índices está *concatenado*: primero las `account_keys` estáticas, luego todas las cuentas escribibles extraídas de las tablas (en orden de búsqueda), luego todas las de solo lectura. Un decodificador debe resolver las búsquedas contra las tablas reales on-chain para saber a qué pubkey apunta realmente el índice de cuenta de una instrucción.

## Dónde lo encuentras

Cada swap moderno de Jupiter, orden de Drift, acción de Kamino y la mayoría de las rutas de agregadores. Las billeteras y `getTransaction` las devuelven constantemente; `maxSupportedTransactionVersion` en las llamadas RPC controla si las recibes decodificadas.

## Errores comunes

- **El prefijo de versión roba el bit alto.** Las transacciones heredadas empiezan con `num_required_signatures`, un número pequeño cuyo bit alto siempre está a 0. v0 pone el bit alto a 1, así que `0x80` como primer byte del mensaje = «v0». Ese único bit es todo el discriminador heredada-frente-a-versionada.
- **No puedes decodificar del todo una transacción v0 aislada.** Los índices de búsqueda no tienen sentido sin obtener las tablas de búsqueda referenciadas. Un blob de transacción solo no te dice cada cuenta que toca.
- **El orden de cuentas resuelto es estáticas-luego-escribibles-luego-solo-lectura.** Si te equivocas en este orden, los índices de cuenta de cada instrucción apuntan a las pubkeys equivocadas.
- **Los firmantes deben estar en las claves estáticas.** Las cuentas cargadas desde tablas de búsqueda nunca pueden ser firmantes — solo las claves listadas estáticamente pueden firmar. Las búsquedas son solo para cuentas no firmantes.
