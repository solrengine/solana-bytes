---
name: Borsh frente a bincode
summary: Las dos serializaciones binarias dominantes en Solana. Borsh (Anchor, SPL, la mayoría de las apps) y bincode (los programas nativos System/Stake/Vote) difieren en el ancho de la etiqueta de enum y algunas convenciones — lo suficiente para romper un decodificador que asuma la equivocada.
---

## Qué es

La mayoría de los datos binarios en Solana se serializan con uno de dos esquemas: **Borsh** (usado por Anchor, SPL Token, Metaplex y la mayoría de las apps) o **bincode** (usado por los programas nativos System, Stake y Vote). Coinciden en mucho — enteros little-endian, colecciones con prefijo de longitud — pero difieren en formas que importan cuando decodificas a mano.

## Por qué existe

bincode llegó primero y los programas nativos lo usan. Borsh («Binary Object Representation Serializer for Hashing») se diseñó para blockchains: determinista, canónico y simple, de modo que los mismos datos siempre se serializan a los mismos bytes (crítico para hashing y firmas). Los programas nuevos se estandarizaron en Borsh; los viejos nativos mantuvieron bincode.

## Diseño de bytes

Dónde coinciden y dónde difieren:

| Aspecto | Borsh | bincode (como lo usan los programas nativos) |
|---------|-------|----------------------------------------------|
| Enteros | little-endian, ancho fijo | little-endian, ancho fijo |
| Etiqueta de `enum` | **1 byte** (índice de variante `u8`) | **4 bytes** (índice de variante `u32`) |
| `Option<T>` | etiqueta de 1 byte + valor si es Some | etiqueta de 1 byte + valor si es Some |
| `Vec<T>` / `String` | longitud LE de 4 bytes + elementos | longitud LE de 8 bytes (por defecto en bincode) |
| structs | campos en orden de declaración, sin relleno | campos en orden, sin relleno |
| bool | 1 byte (0/1) | 1 byte (0/1) |

La diferencia principal para decodificar instrucciones es el **ancho de la etiqueta de enum**: un enum de Borsh (p. ej. una instrucción de Anchor, aunque Anchor usa en realidad un discriminador hash de 8 bytes) etiqueta las variantes en 1 byte, mientras que una [instrucción de System](/learn/native/system-instructions) nativa las etiqueta en 4 bytes (`02 00 00 00` = Transfer).

## Dónde lo encuentras

- Borsh: estado de SPL Token, [metadatos de Metaplex](/learn/metaplex/token-metadata), cuentas y argumentos de Anchor.
- bincode: datos de instrucción de System/Stake/Vote y algún estado de cuenta nativo.

## Errores comunes

- **El ancho de la etiqueta de enum es la trampa.** Decodifica una instrucción nativa esperando una etiqueta de 1 byte y leerás mal el discriminador y cada campo posterior. System/Stake/Vote usan etiquetas de 4 bytes; SPL Token usa una etiqueta de 1 byte (es estilo Borsh pero con `Pack`).
- **La longitud de colección de bincode es de 8 bytes por defecto.** Borsh usa 4. Si parseas datos nativos con un Vec, no asumas una longitud de 4 bytes.
- **SPL Token no es Borsh puro.** Usa un trait `Pack` de diseño fijo a medida con [COption](/learn/encoding/coption-vs-option) (etiquetas de 4 bytes) — ni Borsh de manual ni bincode. Trata el diseño de cada programa como documentado, no como asumido.
- **Anchor añade un discriminador hash de 8 bytes sobre Borsh.** Una instrucción de Anchor no es `[etiqueta enum de 1 byte][args]` — es `[etiqueta sha256 de 8 bytes][args Borsh]` (ver [discriminador de instrucción](/learn/anchor/instruction-discriminator)).
