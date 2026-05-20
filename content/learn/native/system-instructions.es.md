---
name: Instrucciones del System Program
summary: Diseños de datos de instrucción del System Program — CreateAccount, Transfer, Allocate, Assign y las instrucciones de nonce. Un discriminador enum little-endian de 4 bytes seguido de campos serializados con bincode.
---

## Qué es

El System Program es el propietario de cada cuenta antes que cualquier otro programa. Sus instrucciones crean cuentas, las financian, asignan espacio, asignan propiedad y gestionan cuentas de nonce duradero. La vida de cada cuenta empieza con una instrucción del System.

## Por qué existe

No puedes escribir en una cuenta que un programa no posee, y las cuentas nuevas empiezan siendo propiedad del System Program. Así que crear una cuenta, darle espacio y transferir la propiedad a tu programa son todas instrucciones del System — la capa de arranque bajo todo lo demás en Solana.

## Diseño de bytes

Los datos de instrucción del System se codifican con **bincode**: un discriminador enum `u32` little-endian de 4 bytes, luego los campos de la variante. Las variantes comunes:

| Discriminador (u32 LE) | Variante | Carga útil | Total |
|----:|----------|-----------|------:|
| `0` | `CreateAccount`     | `lamports: u64`, `space: u64`, `owner: Pubkey(32)` | 52 bytes |
| `1` | `Assign`            | `owner: Pubkey(32)` | 36 bytes |
| `2` | `Transfer`          | `lamports: u64` | 12 bytes |
| `3` | `CreateAccountWithSeed` | base, cadena seed, lamports, space, owner | variable |
| `4` | `AdvanceNonceAccount` | (ninguna) | 4 bytes |
| `8` | `Allocate`          | `space: u64` | 12 bytes |

La instrucción más común de toda la cadena es `Transfer`: bytes `02 00 00 00` seguidos de un importe de lamports de 8 bytes little-endian — 12 bytes en total.

## Dónde lo encuentras

Cada creación de cuenta, cada transferencia de SOL, cada par `createAccount` + `assign` que precede a la inicialización de una cuenta de programa. El «enviar SOL» de una billetera es un único System Transfer.

## Errores comunes

- **Discriminador de 4 bytes, no de 1.** System (y Stake y Vote) usan una etiqueta de enum `u32` de 4 bytes vía bincode — a diferencia de la etiqueta de 1 byte de SPL Token. Leer el ancho equivocado desplaza cada campo.
- **`lamports`, no SOL.** El importe de `Transfer` está en lamports (1 SOL = 1.000.000.000 lamports). Una transferencia de «1 SOL» es `02 00 00 00` + `00 ca 9a 3b 00 00 00 00`.
- **CreateAccount requiere que la cuenta sea firmante.** La dirección de la nueva cuenta debe firmar su propia creación (es un par de claves nuevo) — una sorpresa frecuente para quienes empiezan. Las PDA lo evitan vía `createAccountWithSeed`/CPI invoke_signed.
- **`owner` por defecto es System.** Tras CreateAccount, la cuenta es propiedad del `owner` que pasaste; si olvidas asignar tu programa, tu programa no puede escribir en ella.
