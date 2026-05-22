---
name: Use Authority Record
summary: Un pequeño registro de delegado que permite a una dirección distinta del propietario del NFT consumir «usos» de un NFT usable, con su propia cuota. El permiso detrás de los NFT canjeables/consumibles.
---

## Qué es

Un Use Authority Record delega la capacidad de consumir «usos» de un NFT usable a una dirección distinta del propietario, con un tope dado por su propia cuota `allowed_uses`. Es el permiso detrás de los NFT canjeables — entradas de conciertos, consumibles de juegos, activos estilo cupón que se «gastan».

## Por qué existe

La función `Uses` de Metaplex permite que un NFT lleve un número finito de usos (un pase de 5 usos, una entrada de canje único). A menudo un tercero —un escáner de un local, un servidor de juego— necesita consumir un uso sin ser el propietario del NFT. Este registro delega ese poder con su propio límite por delegado, de modo que el propietario puede autorizar a un escáner a quemar como máximo N usos.

## Diseño de bytes

UseAuthorityRecord se codifica con Borsh. Es una PDA sembrada con la mint del NFT y la autoridad delegada.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `key`          | `u8` enum | `8` = UseAuthorityRecord. |
| 1 | 8 | `allowed_uses` | `u64` LE  | Cuántos usos puede consumir este delegado. |
| 9 | 1 | `bump`         | `u8`      | Bump canónico de la PDA de este registro. |

Total: **10 bytes**.

## El campo Uses contra el que descuenta

Los propios [metadatos](/learn/metaplex/token-metadata) del NFT llevan una struct opcional `Uses { use_method, remaining, total }` — el contador global. Un Use Authority Record es una asignación *acotada al delegado* que descuenta de ese `remaining` global. Consumir un uso decrementa tanto el `allowed_uses` del delegado como el `remaining` del NFT.

## Dónde lo encuentras

Sistemas de NFT canjeables: venta de entradas a eventos, canjes de fidelidad, consumo de objetos de juego. El registro existe siempre que el propietario de un NFT ha delegado el consumo de usos a un servicio.

## Errores comunes

- **Dos contadores, ambos descuentan.** El `allowed_uses` del delegado y el `Uses.remaining` global del NFT son separados; un uso consume de ambos. Un delegado no puede exceder su `allowed_uses` aunque al NFT le queden usos.
- **El registro más pequeño de Metaplex con 10 bytes.** Sin campos `Option` — solo key, un u64 y un bump. Rápido de decodificar.
- **`use_method` importa para la semántica.** El `Uses.use_method` del NFT (Burn, Multiple, Single) determina qué pasa al llegar a cero restantes — Burn destruye el NFT. El registro en sí solo rastrea la asignación.
- **Revocable por el propietario.** Cerrar el registro revoca de inmediato la asignación restante del delegado.
