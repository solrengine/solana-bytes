---
name: Bubblegum — TreeConfig y Leaf Schema
summary: Cómo funcionan los NFT comprimidos — una pequeña cuenta TreeConfig gobierna un árbol de Merkle, y cada NFT es una hoja hasheada (LeafSchema) en lugar de su propia cuenta. Millones de NFT por el coste de unas pocas cuentas.
---

## Qué es

Los NFT comprimidos (cNFT) no tienen su propia cuenta. En su lugar, Metaplex Bubblegum almacena cada NFT como una **hoja hasheada** en un árbol de Merkle, y una única y pequeña cuenta **TreeConfig** gobierna todo el árbol. Un árbol que contiene un millón de NFT cuesta el equivalente al rent de unas pocas cuentas en lugar de un millón — el truco central tras el minteo barato y a gran escala de NFT.

## Por qué existe

Un NFT normal necesita una mint, una [token account](/learn/spl-token/token-account) y una cuenta de [metadatos](/learn/metaplex/token-metadata) — demasiado caro para airdrops de millones. La compresión de estado hashea los datos del NFT en un árbol de Merkle concurrente (almacenado fuera de la cadena, con solo la raíz de 32 bytes y un registro de cambios on-chain). La propiedad y los metadatos se prueban contra la raíz mediante pruebas de Merkle, así que el almacenamiento on-chain por NFT cae a casi cero.

## Diseño de bytes

**TreeConfig** — la cuenta de autoridad por árbol (una cuenta de Anchor, así que empieza con un [discriminador](/learn/anchor/account-discriminator) de 8 bytes):

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 8  | discriminador       | `[u8; 8]` | Discriminador de cuenta de Anchor. |
| 8  | 32 | `tree_creator`      | `Pubkey`  | Quién creó el árbol. |
| 40 | 32 | `tree_delegate`     | `Pubkey`  | Autorizado a mintear en el árbol. |
| 72 | 8  | `total_mint_capacity` | `u64` LE | Máximo de hojas (fijado por la profundidad del árbol). |
| 80 | 8  | `num_minted`        | `u64` LE  | Hojas minteadas hasta ahora. |
| 88 | 1  | `is_public`         | `bool`    | Si cualquiera puede mintear. |
| 89 | 1  | `is_decompressible` | `u8` enum | Si las hojas pueden descomprimirse a NFT reales. |
| 90 | 1  | `version`           | `u8` enum | Versión del esquema del árbol. |

**LeafSchema V1** — los datos por NFT que se hashean con keccak en un único nodo de árbol de 32 bytes (*no* se almacenan como cuenta):

| Campo | Tipo | Notas |
|-------|------|-------|
| `id`           | `Pubkey`   | El id del activo — una PDA del árbol + nonce. |
| `owner`        | `Pubkey`   | Propietario actual. |
| `delegate`     | `Pubkey`   | Delegado aprobado, si lo hay. |
| `nonce`        | `u64`      | Índice de hoja / nonce de unicidad. |
| `data_hash`    | `[u8; 32]` | Hash de los metadatos del NFT. |
| `creator_hash` | `[u8; 32]` | Hash del array de creadores. |

El programa calcula `keccak(id, owner, delegate, nonce, data_hash, creator_hash)` → el nodo de hoja de 32 bytes almacenado en el árbol.

## Dónde lo encuentras

Airdrops grandes, objetos de juegos y cualquier colección de NFT de alto volumen (Drip, Helium, etc.). No obtienes un cNFT por cuenta — consultas un indexador (la DAS API) que lo reconstruye desde el árbol y sirve una prueba de Merkle.

## Errores comunes

- **El NFT no tiene cuenta.** No puedes hacer `getAccountInfo` a un cNFT. La propiedad vive como un hash en el árbol; las transferencias actualizan la hoja y la raíz del árbol. Las herramientas que asumen una-cuenta-por-NFT no funcionan.
- **Necesitas una prueba de Merkle para actuar sobre uno.** Transferir o quemar un cNFT requiere enviar los datos de la hoja más una ruta de prueba contra la raíz actual — normalmente obtenida de un proveedor de DAS API, no derivada localmente.
- **La cuenta de árbol on-chain es separada de TreeConfig.** TreeConfig (esta cuenta) lleva autoridad/contadores; el árbol de Merkle concurrente real (raíz + registro de cambios) vive en una cuenta separada propiedad del programa SPL Account Compression.
- **`data_hash`/`creator_hash` son compromisos, no los datos.** Los metadatos reales viven fuera de la cadena; solo su hash está on-chain. Verificar los metadatos de un NFT significa rehashear los datos fuera de la cadena y comprobar que coinciden.
