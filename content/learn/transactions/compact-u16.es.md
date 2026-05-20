---
name: compact-u16 (shortvec)
summary: El entero de longitud variable de 1 a 3 bytes que prefija cada array en una transacción de Solana. Siete bits de valor por byte más un indicador de continuación — origen de la mayoría de los errores de parseo de transacciones.
---

## Qué es

`compact-u16` (también llamado *shortvec*) es una codificación de longitud variable para el prefijo de longitud de cada array dentro de una transacción de Solana — el recuento de firmas, el recuento de claves de cuenta, el recuento de instrucciones y las longitudes de cuentas y datos por instrucción. Codifica un valor de 0 a 65.535 en **1 a 3 bytes**.

## Por qué existe

Las transacciones tienen el tamaño limitado (1.232 bytes en el cable), así que gastar 2 o 4 bytes fijos en cada longitud de array es un desperdicio cuando la mayoría de los arrays son cortos. compact-u16 gasta un solo byte para longitudes menores de 128 —lo que cubre la inmensa mayoría de transacciones reales— y solo crece cuando hace falta.

## Diseño de bytes

Cada byte lleva 7 bits de valor en sus bits bajos; el bit alto (`0x80`) es un indicador de continuación que significa «sigue otro byte».

| Bytes usados | Rango de valor | Codificación |
|-------------:|----------------|--------------|
| 1 | 0 – 127        | `0vvvvvvv` — bit alto a 0, valor en los 7 bits bajos. |
| 2 | 128 – 16.383   | `1vvvvvvv 0vvvvvvv` — bit alto del primer byte a 1; siguientes 7 bits en el segundo byte. |
| 3 | 16.384 – 65.535 | `1vvvvvvv 1vvvvvvv 000000vv` — el tercer byte usa solo sus 2 bits bajos. |

La decodificación acumula 7 bits cada vez, desplazando a la izquierda 7 por cada byte posterior, y se detiene en el primer byte cuyo bit alto esté a 0.

```text
valor = 0
shift = 0
bucle:
  byte = siguiente_byte()
  valor |= (byte & 0x7F) << shift
  si (byte & 0x80) == 0: salir
  shift += 7
```

## Dónde lo encuentras

Antes de *cada* array en una [transacción heredada](/learn/transactions/legacy-transaction) y una transacción v0: el vector de firmas, el de claves de cuenta, el de instrucciones, el vector de índices de cuenta de cada instrucción y su vector de datos, y (en v0) los vectores de búsqueda en tablas de direcciones. Si parseas una transacción a mano y tus offsets se desvían, un compact-u16 mal leído suele ser el culpable.

## Errores comunes

- **No es LEB128, ni un u16 little-endian.** compact-u16 es su propio formato. Decodificarlo como un entero little-endian de 2 bytes funciona *por accidente* para valores 0–127 (un byte) y luego se rompe silenciosamente. Usa un decodificador shortvec de verdad.
- **El tercer byte solo tiene 2 bits de valor usables.** Como el valor máximo es u16 (65.535), el tercer byte se topa en `0b00000011` en sus bits bajos. Los codificadores deben rechazar cualquier cosa mayor.
- **Longitud, luego elementos.** El prefijo es el *recuento* de elementos, no una longitud en bytes. Para saltar un array debes decodificar el recuento y luego recorrer cada elemento (cuyo tamaño conoces por el contexto) — no puedes simplemente saltar N bytes.
- **Las codificaciones no canónicas son inválidas.** Codificar `5` como dos bytes (`0x85 0x00`) en lugar de uno (`0x05`) está malformado; los decodificadores estrictos lo rechazan. No rellenes.
