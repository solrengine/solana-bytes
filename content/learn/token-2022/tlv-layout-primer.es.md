---
name: Primer de diseño TLV
summary: Cómo Token-2022 almacena las extensiones on-chain — una cabecera Tipo-Longitud-Valor de 4 bytes seguida de la carga útil de cada extensión, recorrida de izquierda a derecha hasta un centinela de tipo 0.
---

## Qué es

Token-2022 amplía SPL Token sin romper su diseño añadiendo bloques **TLV** (Tipo-Longitud-Valor) después de la cuenta base. Cada función de Token-2022 —comisiones de transferencia, intereses, transferencias confidenciales, metadatos, transfer hooks, importes de UI escalados— es una extensión TLV que sigue la misma convención de cabecera de 4 bytes.

Una entrada TLV son exactamente 4 bytes de cabecera más una carga útil variable:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 2 | `extension_type` | `u16` LE | Qué extensión es (`1` TransferFeeConfig, `2` TransferFeeAmount, `3` MintCloseAuthority, `4` ConfidentialTransferMint, …). `0` significa Uninitialized y señala el fin de la lista. |
| 2 | 2 | `length` | `u16` LE | Longitud en bytes de la carga útil que sigue — **sin** incluir la cabecera de 4 bytes. |
| 4 | N | `payload` | varía | Datos codificados específicos de la extensión. |

## Por qué existe

La Mint de SPL Token mide exactamente 82 bytes y la TokenAccount 165. No puedes añadir campos sin romper cada token existente en Solana. Token-2022 es un programa paralelo que mantiene los diseños base idénticos byte a byte a SPL Token y añade funciones como bloques TLV pasado el offset 165, de modo que un decodificador que no conozca una extensión concreta aún puede leer correctamente el saldo y la autoridad base.

## Diseño de bytes de una cuenta Token-2022

Las cuentas Token-2022 siempre tienen este aspecto, ya sea una Mint mínima de 166 bytes o una de varios kilobytes con cinco extensiones apiladas:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 82 o 165 | base | base SPL Token | Idéntico byte a byte a la Mint (82) o TokenAccount (165) de SPL Token. |
| 82 | 83 | relleno (solo Mints) | bytes a cero | Las Mints se rellenan hasta 165 para que el discriminador y el TLV queden siempre en los mismos offsets sin importar el tipo base. |
| 165 | 1 | `account_type` | `u8` enum | `1` = Mint, `2` = TokenAccount. Única señal on-chain que los distingue — no puedes saberlo por el tamaño. |
| 166 | variable | entradas TLV | TLV[] | Una entrada por extensión activa, empaquetadas una tras otra. La lista termina con una entrada cuyo `extension_type == 0`. |

Esto significa que una Mint de Token-2022 con una extensión ocupa `82 (base) + 83 (relleno) + 1 (discriminador) + 4 (cabecera TLV) + N (carga útil)` bytes en total. Una Mint mínima sin extensiones mide exactamente 166 bytes; cualquier cosa mayor lleva extensiones.

## Cómo recorrer la lista TLV

El recorredor de referencia es un bucle ajustado — lo hace cada explorador, indexador y decodificador de Token-2022:

```text
posicion = 166
mientras posicion + 4 <= longitud(data):
  extension_type = leer_u16_le(data, posicion)
  si extension_type == 0:
    salir                          # Uninitialized — fin de la lista
  length = leer_u16_le(data, posicion + 2)
  payload = data[posicion + 4 .. posicion + 4 + length]
  emitir (extension_type, payload)
  posicion += 4 + length
```

Ese es todo el recorredor. La condición `+ 4 <= longitud` evita leer la cabecera más allá del final de un búfer truncado; los decodificadores de producción también comprueban los límites de `posicion + 4 + length` antes de cortar la carga útil.

## Dónde lo encuentras

Cualquier cosa propiedad de `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` con una longitud de datos superior a 166 bytes lleva al menos una extensión. Las respuestas parseadas de RPC `getMint` y `getTokenAccountBalance` desempaquetan esto por ti; `getAccountInfo` en bruto devuelve los bytes y los recorres tú.

## Errores comunes

- **`extension_type == 0` es el centinela, no la primera ranura.** Una zona de extensiones recién creada parece una entrada de tipo 0 — eso *es* el marcador de fin de lista. No intentes recorrer más allá.
- **`length` es la longitud de la carga útil, no la de la entrada.** El tamaño total de la entrada es `4 + length`. Olvidar la cabecera de 4 bytes es el error de decodificación más común aquí.
- **La distinción entre Mint y TokenAccount vive en el offset 165.** Ambos diseños base comparten el tamaño 165 (tras el relleno de la Mint) — solo el byte `account_type` te dice qué interpretación aplicar a los bytes 0–164.
- **Algunas extensiones son específicas de un tipo.** TransferFeeConfig es una extensión del lado Mint; TransferFeeAmount es su contraparte del lado TokenAccount. El formato TLV no impone la compatibilidad de tipos — lo hace el programa. Un decodificador ingenuo que lea cualquier TLV contra cualquier base producirá basura para entradas de tipo cruzado.
- **Las extensiones no usan internamente la codificación `COption` de SPL.** La mayoría usa `OptionalNonZeroPubkey` (32 bytes, todo a cero = None, sin etiqueta) o `Option<T>` de Borsh. Consulta [TransferFeeConfig](/learn/token-2022/transfer-fee-config) para ver el detalle en contexto.
