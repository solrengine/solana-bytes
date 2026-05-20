---
name: Master Edition
summary: La cuenta que marca un NFT como único (1-de-1) y autoriza la impresión de ediciones numeradas de él. Almacena el suministro de impresiones actual y un máximo opcional.
---

## Qué es

Una cuenta Master Edition convierte un NFT normal de [metadatos](/learn/metaplex/token-metadata) de Metaplex en un «maestro» que puede acuñar impresiones numeradas (ediciones) de sí mismo — como el maestro firmado de un artista del que se imprime una tirada limitada. Su existencia es también lo que hace que un token sea un verdadero no fungible 1-de-1 (suministro topado en 1, 0 decimales).

## Por qué existe

Los casos de uso de NFT necesitan tanto piezas únicas 1-de-1 como ediciones limitadas («100 impresiones de esta obra»). La cuenta Master Edition certifica la no fungibilidad y a la vez rastrea cuántas ediciones se han impreso frente a un tope opcional. Una mint con una Master Edition es demostrablemente un NFT, no un token divisible.

## Diseño de bytes

MasterEditionV2 se codifica con Borsh. Su cuenta es una PDA de la mint con el sufijo de semilla `"edition"`.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `key`        | `u8` enum   | `6` = MasterEditionV2. |
| 1 | 8 | `supply`     | `u64` LE    | Número de ediciones impresas hasta ahora. |
| 9 | 1+8 | `max_supply` | `Option<u64>` | Option de Borsh: etiqueta de 1 byte (`0` None = ilimitado, `1` Some) + tope `u64` cuando está presente. |

Total: **18 bytes** cuando `max_supply` está fijado, **10 bytes** cuando es None (impresiones ilimitadas).

## Dónde lo encuentras

Cada NFT 1-de-1 (donde `max_supply = Some(0)` — sin impresiones permitidas) y cada drop de edición limitada (donde `max_supply = Some(N)`). Los marketplaces leen la Master Edition para confirmar que un activo es un NFT genuino y para mostrar «edición X de N».

## Errores comunes

- **`max_supply = Some(0)` significa un 1-de-1 puro.** Cero impresiones permitidas — el propio maestro es la única copia. `Some(100)` permite 100 impresiones numeradas; `None` permite ilimitadas.
- **`supply` cuenta impresiones, no el maestro.** Empieza en 0 y se incrementa al imprimir ediciones mediante el seguimiento de [EditionMarker](/learn/metaplex/edition-marker).
- **Es una PDA sembrada con `"edition"`.** Dirección = `findProgramAddress(["metadata", program_id, mint, "edition"])`. La misma derivación localiza la cuenta Edition de una edición impresa.
- **Option de Borsh (etiqueta de 1 byte), no COption de SPL.** `max_supply` es `Option<u64>` — un solo byte `0` para None. No apliques la convención [COption de 4 bytes](/learn/encoding/coption-vs-option) aquí.
