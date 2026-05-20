---
name: Edition Marker
summary: Un campo de bits de 32 bytes que rastrea qué ediciones numeradas de una Master Edition ya se han impreso. Cada bit es un número de edición; un marcador cubre 248 ediciones.
---

## Qué es

Un Edition Marker es un campo de bits compacto que registra qué números de edición de una [Master Edition](/learn/metaplex/master-edition) se han impreso. En lugar de almacenar un indicador por edición en cuentas separadas, Metaplex empaqueta 248 indicadores de edición en un único ledger de 31 bytes.

## Por qué existe

Imprimir ediciones limitadas necesita una forma de evitar imprimir dos veces la edición n.º 42. Almacenar un booleano por edición en su propia cuenta sería un desperdicio; un campo de bits permite que una pequeña cuenta rastree cientos de ediciones, creándose nuevas cuentas marcador solo a medida que los números de edición suben más allá de cada bloque de 248.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1  | `key`    | `u8` enum    | `7` = EditionMarker. |
| 1 | 31 | `ledger` | `[u8; 31]`   | Campo de bits: 31 bytes × 8 bits = 248 ranuras de edición. Bit a 1 = ese número de edición está impreso. |

Total: **32 bytes**.

## Cómo se mapean los números de edición a bits

El número de edición `N` vive en el bloque marcador `N / 248`; dentro de ese marcador, es el bit `N % 248`, direccionado como byte `(N % 248) / 8` y bit `(N % 248) % 8`. La propia cuenta marcador es una PDA sembrada con el bloque del número de edición, así que las ediciones 1–248 comparten un marcador, 249–496 el siguiente, y así sucesivamente.

## Dónde lo encuentras

Detrás de cada drop de NFT de edición limitada. Cuando imprimes la edición n.º 5 de un maestro, el programa pone a 1 el bit 5 en el Edition Marker correspondiente para que el n.º 5 no pueda volver a imprimirse.

## Errores comunes

- **Un marcador cubre 248 ediciones, no todas.** Las ediciones grandes abarcan múltiples cuentas marcador, cada una una PDA separada. No esperes que un solo marcador contenga toda la tirada.
- **Es un campo de bits, no un contador.** El contador `supply` vive en la [Master Edition](/learn/metaplex/master-edition); el marcador solo registra *qué números concretos* están ocupados. Los dos se actualizan juntos al imprimir.
- **El orden de bits importa.** El bit de la edición `N` está en el byte `(N % 248) / 8`, MSB primero dentro del byte en el esquema de Metaplex. Un error de uno aquí imprime la ranura equivocada.
- **EditionMarkerV2 existe para ediciones muy grandes** en versiones más nuevas de Metaplex; el EditionMarker clásico de 32 bytes (key 7) es lo que verás en la mayoría de las colecciones.
