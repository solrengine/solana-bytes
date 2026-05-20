---
name: Instrucciones de SPL Token
summary: Diseños de datos de instrucción del programa SPL Token — Transfer, MintTo, Burn, Approve y las variantes Checked. Un discriminador de 1 byte seguido de un importe u64 (y decimales en las Checked).
---

## Qué es

Las instrucciones del programa SPL Token mueven y gestionan saldos de tokens: transferir, emitir, quemar, aprobar un delegado, congelar, cerrar. Operan sobre cuentas [Mint](/learn/spl-token/mint) y [Token Account](/learn/spl-token/token-account). Token-2022 comparte el mismo diseño de instrucciones más añadidos específicos de cada extensión.

## Por qué existe

Cada acción sobre un token —enviar USDC, emitir un NFT, quemar suministro, aprobar a un DEX para gastar— es una de estas instrucciones. Están entre las instrucciones más ejecutadas de Solana.

## Diseño de bytes

Los datos de instrucción de SPL Token usan un **discriminador de 1 byte** seguido de los campos de la variante:

| Discriminador (u8) | Variante | Carga útil | Total |
|----:|----------|-----------|------:|
| `3`  | `Transfer`        | `amount: u64` | 9 bytes |
| `4`  | `Approve`         | `amount: u64` | 9 bytes |
| `7`  | `MintTo`          | `amount: u64` | 9 bytes |
| `8`  | `Burn`            | `amount: u64` | 9 bytes |
| `9`  | `CloseAccount`    | (ninguna) | 1 byte |
| `12` | `TransferChecked` | `amount: u64`, `decimals: u8` | 10 bytes |
| `14` | `MintToChecked`   | `amount: u64`, `decimals: u8` | 10 bytes |
| `15` | `BurnChecked`     | `amount: u64`, `decimals: u8` | 10 bytes |

`Transfer` son los bytes `03` + un importe de 8 bytes little-endian. `TransferChecked` añade un byte `decimals` y exige la mint como cuenta para que el programa pueda verificar la suposición de decimales del invocador.

## Dónde lo encuentras

Cada movimiento de tokens en Solana. Los envíos desde billetera, los swaps de DEX (que aprueban + transfieren), las operaciones de emisión y las quemas de suministro se decodifican todos en estas instrucciones.

## Errores comunes

- **Prefiere las variantes Checked.** `Transfer` (3) no verifica los decimales, así que un cliente que use los decimales equivocados puede mover 1000× el importe previsto. `TransferChecked` (12) aporta la mint y `decimals` para que el programa rechace una discrepancia. El código nuevo debería usar las Checked.
- **`amount` está en unidades atómicas, no en unidades de visualización.** Transferir «1 USDC» (6 decimales) es `amount = 1_000_000`. La instrucción nunca ve el número legible.
- **Discriminador de 1 byte, a diferencia de los programas nativos de 4 bytes.** SPL Token, SPL Associated Token Account y la mayoría de los programas SPL usan una etiqueta de un solo byte.
- **La autoridad viene de las cuentas, no de los datos.** Quién puede transferir (propietario o delegado) lo determina qué cuenta firma, no los datos de la instrucción. Los datos son solo el discriminador + el importe.
