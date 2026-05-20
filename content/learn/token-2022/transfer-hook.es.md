---
name: TransferHook (extensión)
summary: Extensión del lado Mint de Token-2022 que llama a un programa personalizado en cada transferencia. El programa de tokens hace una CPI a la instrucción Execute del hook, habilitando listas de permitidos, aplicación de regalías y lógica por transferencia.
---

## Qué es

`TransferHook` hace que el programa de tokens llame a un programa personalizado en **cada transferencia** del token. Tras mover los tokens, el programa Token-2022 hace una CPI a la instrucción `Execute` del programa hook, permitiendo que se ejecute lógica on-chain arbitraria — comprobaciones de lista de permitidos, cobro de regalías, registro de transferencias, limitación de tasa. El programa hook implementa la SPL Transfer Hook Interface.

## Por qué existe

`TransferFeeConfig` cubre las comisiones y `NonTransferable` cubre la condición soulbound, pero los emisores querían un comportamiento de transferencia *programable*: «solo las direcciones de esta lista pueden recibir», «cobrar una regalía dinámica», «registrar cada transferencia en una cuenta de auditoría». En lugar de incorporar cada política al programa de tokens, Token-2022 delega en un programa proporcionado por el usuario en cada transferencia.

## Diseño de bytes

Esta es la carga útil de una entrada TLV TransferHook (`extension_type = 14`, `length = 64`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`  | `OptionalNonZeroPubkey` | Puede actualizar el id del programa hook. Todo a cero = None — hook congelado. |
| 32 | 32 | `program_id` | `OptionalNonZeroPubkey` | El programa hook al que se hace CPI en cada transferencia. Todo a cero = None — no se ejecuta ningún hook. |

Carga útil total: **64 bytes**.

## Cómo fluye una transferencia

En `TransferChecked`, el programa de tokens: (1) mueve los tokens, (2) lee los metadatos de cuentas extra que el programa hook publicó (mediante una PDA propiedad del hook), (3) hace una CPI al `Execute` del hook con esas cuentas. Si `Execute` da error, toda la transferencia se revierte. La extensión del lado cuenta `TransferHookAccount` (tipo 15) lleva un indicador de transferencia en curso que el hook puede comprobar para saber que se le llama a mitad de una transferencia y no directamente.

## Dónde lo encuentras

Tokens controlados por lista de permitidos, NFT con regalías aplicadas (un hook que exige una cuenta de pago de regalías en la transferencia) y tokens de cumplimiento que registran o filtran cada movimiento. Es la extensión de Token-2022 más flexible — y la que más integración requiere.

## Errores comunes

- **Las transferencias necesitan cuentas extra.** Un hook normalmente requiere cuentas más allá del conjunto de transferencia normal (su PDA de configuración, una cuenta de lista de permitidos, etc.). Los clientes deben resolverlas mediante la PDA de metadatos de cuentas extra del hook *antes* de construir la transferencia, o falla. Este es el bug de integración de transfer-hook número 1.
- **Un hook que falla revierte la transferencia.** El `Execute` del hook es parte de la transacción. Si da error (dirección no en la lista, regalía no pagada), la transferencia no ocurre. Muestra los fallos del hook de forma distinta a los fallos de saldo/comisión.
- **El programa hook es código arbitrario.** Trata un token con transfer hook como portador de lógica de terceros en cada movimiento — audita el programa hook antes de integrar, igual que verificarías cualquier programa al que hagas CPI.
- **`program_id = None` significa que no se ejecuta ningún hook** aunque la extensión exista. La presencia de la extensión no basta; el id del programa debe estar fijado.
