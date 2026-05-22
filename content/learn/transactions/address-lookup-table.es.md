---
name: Address Lookup Table
summary: Almacena un array de pubkeys que las transacciones v0 referencian por índice de 1 byte. Cabecera fija de 56 bytes + direcciones de 32 bytes empaquetadas, hasta 256 entradas.
---

## Qué es

Una Address Lookup Table (ALT) permite a las transacciones v0 referenciar cuentas por un índice de 1 byte en lugar de incrustar cada pubkey de 32 bytes, elevando el techo de ~35 cuentas de las transacciones heredadas.

## Por qué existe

Las transacciones heredadas de Solana incrustan cada dirección de cuenta como 32 bytes en bruto. Con un límite rígido de 1.232 bytes por transacción, eso limitaba la componibilidad — los swaps multisalto y las rutas DeFi complejas chocaban contra el muro. Las ALT se almacenan on-chain; una transacción v0 nombra una o más tablas de búsqueda en su cabecera y luego referencia las cuentas de esas tablas por índice de 1 byte. La transacción se mantiene pequeña, pero el runtime ve el conjunto completo de pubkeys.

## Diseño de bytes

Una cabecera fija de 56 bytes seguida de pubkeys de 32 bytes empaquetadas.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0   | 4   | `discriminator`              | `u32` enum     | `1` = LookupTable. |
| 4   | 8   | `deactivation_slot`          | `u64` LE       | `u64::MAX` si sigue activa. |
| 12  | 8   | `last_extended_slot`         | `u64` LE       | Último slot en que se ejecutó un Extend. |
| 20  | 1   | `last_extension_start_index` | `u8`           | Índice donde el último Extend empezó a añadir. |
| 21  | 1   | etiqueta de `authority`      | `u8` Option    | `0` None (congelada para siempre), `1` Some. |
| 22  | 32  | `authority`                  | `Pubkey`       | A cero cuando la etiqueta Option es None. |
| 54  | 2   | relleno                      | —              | Ceros para alinear las direcciones al offset 56. |
| 56  | 32 × N | `addresses[]`             | `Pubkey[]`     | Hasta 256 entradas. Tamaño total: `56 + 32 × addresses.len()`. |

Tamaño máximo total: **8.248 bytes** (56 de cabecera + 256 × 32).

## Dónde lo encuentras

Cada swap moderno de Jupiter, operación de Drift, actualización de posición de Kamino y acción de multisig de Squads recorre una o más ALT. Te topas con ALT siempre que simulas o decodificas una transacción v0, o compones una desde cero vía `@solana/web3.js` ≥ 1.95 o `anchor-cli`.

## Errores comunes

- **Las ALT son mutables hasta que se congelan.** Cualquiera con `authority` puede llamar a ExtendLookupTable para añadir nuevas direcciones; poner la Option de authority en None hace la tabla inmutable para siempre.
- **La desactivación es en dos fases.** DeactivateLookupTable fija `deactivation_slot`; la tabla queda inutilizable tras ese slot pero no puede cerrarse (`CloseLookupTable`) hasta ~513 slots después (el «enfriamiento») para evitar romper transacciones en vuelo.
- **El índice de 1 byte limita una sola ALT a 256 entradas**, pero una transacción v0 puede referenciar múltiples ALT para componer conjuntos de cuentas más grandes.
- **`size` es dinámico.** A diferencia de Mint (82) o Token Account (165), el tamaño de una ALT depende de cuántas direcciones se hayan añadido con Extend.
