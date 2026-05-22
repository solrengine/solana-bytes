---
name: Token Metadata
summary: Cuenta MetadataV1 — vincula una mint con su nombre, símbolo, URI, regalías, creadores y colección opcional. La base de cada NFT de Solana.
---

## Qué es

Una cuenta Token Metadata de Metaplex añade un nombre, símbolo, URI de imagen y regalías de creador a una [Mint](/learn/spl-token/mint) de SPL — la base de cada NFT de Solana y de la mayoría de los tokens «fungibles-con-metadatos».

## Por qué existe

Las cuentas Mint de SPL son solo números: suministro, decimales, autoridades. Para los NFT necesitas un nombre, una imagen, creadores a quienes pagar regalías y una forma de apuntar a un JSON fuera de la cadena. El programa Token Metadata de Metaplex almacena eso on-chain como una cuenta separada derivada de la mint mediante una PDA fija: `["metadata", program_id, mint_pubkey]`.

## Diseño de bytes

El diseño MetadataV1 de 607 bytes está dominado por tres cadenas de longitud variable con relleno y varios campos Option. El relleno se rellena con bytes a cero hasta los máximos fijos.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0    | 1   | `key`                       | `u8` enum            | `4` = MetadataV1. |
| 1    | 32  | `update_authority`          | `Pubkey`             | Puede actualizar campos mientras `is_mutable`. |
| 33   | 32  | `mint`                      | `Pubkey`             | La Mint de SPL que describen estos metadatos. |
| 65   | 36  | `name`                      | cadena con relleno   | Longitud de 4 bytes + hasta 32 bytes UTF-8. |
| 101  | 14  | `symbol`                    | cadena con relleno   | Longitud de 4 bytes + hasta 10 bytes UTF-8. |
| 115  | 204 | `uri`                       | cadena con relleno   | Longitud de 4 bytes + hasta 200 bytes UTF-8. Apunta al JSON fuera de la cadena. |
| 319  | 2   | `seller_fee_basis_points`   | `u16` LE             | Regalía en puntos básicos (500 = 5%). |
| 321  | var | `creators`                  | `Option<Vec<Creator>>` | Etiqueta Option de 1 byte + longitud de 4 bytes + entradas Creator de 34 bytes. |
| …    | 1   | `primary_sale_happened`     | `bool`               | |
| …    | 1   | `is_mutable`                | `bool`               | Si es false, los campos quedan congelados para siempre. |
| …    | 2   | `edition_nonce`             | `Option<u8>`         | Etiqueta Option de 1 byte + nonce de 1 byte. |
| …    | 2   | `token_standard`            | `Option<u8>` enum    | NonFungible, Fungible, ProgrammableNonFungible, etc. |
| …    | var | `collection`                | `Option<Collection>` | Mint de colección vinculada. |
| …    | var | `uses`                      | `Option<Uses>`       | Seguimiento de usos burn/multi/single. |

Total: **607 bytes** (con relleno a tamaño fijo; los campos variables se rellenan hasta el máximo).

## Dónde lo encuentras

Las billeteras y marketplaces resuelven cualquier mint de NFT a su cuenta Token Metadata para renderizar el nombre y la imagen. La mayoría de los tokens fungibles también usan Metaplex (el logo y el nombre de USDC vienen de una cuenta Metadata). Token-2022 introdujo una extensión de metadatos en línea alternativa que evita la cuenta separada, pero Metaplex sigue dominando para NFT.

## Errores comunes

- **Cadenas con relleno, no estilo Borsh.** `name`/`symbol`/`uri` tienen prefijo de longitud pero siempre se rellenan al tamaño máximo on-chain. Los bytes a cero finales son parte del diseño.
- **`is_mutable: false` es permanente.** Una vez fijado, ningún campo puede cambiarse. Muchas colecciones se vuelven inmutables tras agotar el mint para probar la procedencia.
- **Metaplex usa `Option` de Borsh (etiqueta de 1 byte), no el `COption` de SPL (etiqueta de 4 bytes).** Las dos codificaciones conviven en Solana — fuente fácil de errores de tres bytes.
- **Las regalías son orientativas.** El `seller_fee_basis_points` on-chain no obliga a los marketplaces a pagar — los pNFT (NFT Programables) añadieron aplicación mediante un ruleset separado.
