---
name: Collection Authority Record
summary: Un pequeño registro de delegado que permite a una dirección distinta de la autoridad de actualización de la colección verificar NFT en una colección de Metaplex. El permiso on-chain para la gestión delegada de colecciones.
---

## Qué es

Un Collection Authority Record delega el poder de verificar (y desverificar) NFT en una colección de Metaplex a una dirección que no es la autoridad de actualización de la colección. Es un pequeño permiso: «esta clave puede marcar NFT como pertenecientes a mi colección».

## Por qué existe

Verificar un NFT en una colección normalmente requiere que la autoridad de actualización de la colección firme. Pero las plataformas de minteo y las candy machines necesitan verificar elementos en nombre del emisor sin poseer la clave maestra de autoridad de actualización. El registro delega exactamente esa única capacidad, acotada a una colección.

## Diseño de bytes

CollectionAuthorityRecord se codifica con Borsh. Es una PDA sembrada con la mint de la colección y la autoridad delegada.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1   | `key`              | `u8` enum       | `9` = CollectionAuthorityRecord. |
| 1 | 1   | `bump`             | `u8`            | Bump canónico de la PDA de este registro. |
| 2 | 1+32 | `update_authority` | `Option<Pubkey>` | Option de Borsh: etiqueta de 1 byte + pubkey de 32 bytes. La autoridad que creó (y puede revocar) esta delegación. |

Total: **35 bytes** (1 + 1 + 1 + 32).

## Dónde lo encuentras

Candy Machine y otra infraestructura de minteo que verifica elementos en una colección en el momento del mint. La existencia de este registro es lo que permite a un firmante delegado llamar a `VerifyCollection` sin ser la autoridad de actualización de la colección.

## Errores comunes

- **Concede derechos de verificación, no propiedad.** El delegado puede verificar/desverificar la pertenencia a la colección; no puede cambiar los metadatos de la colección ni transferir el NFT de la colección.
- **Revocable.** La `update_authority` que creó el registro puede revocarlo (cerrando la cuenta), eliminando al instante el poder del delegado.
- **Almacena su propio bump.** El campo `bump` cachea el [bump canónico](/learn/addressing/canonical-bumps) para que el programa no lo rederive en cada llamada — un patrón común en los pequeños registros de Metaplex.
- **Superado por MetadataDelegate en los flujos más nuevos.** Las versiones recientes de Metaplex prefieren el registro generalizado `MetadataDelegate` (key 12); CollectionAuthorityRecord (key 9) sigue siendo común en colecciones existentes.
