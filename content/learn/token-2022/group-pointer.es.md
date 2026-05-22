---
name: GroupPointer (extensión)
summary: Extensión del lado Mint de Token-2022 que registra dónde vive la configuración de grupo (colección) de un token. El análogo de agrupación de MetadataPointer — puede apuntar a una cuenta TokenGroup o a la propia mint.
---

## Qué es

`GroupPointer` registra *dónde* vive la configuración de grupo (colección) de un token. Es la contraparte de agrupación de [MetadataPointer](/learn/token-2022/metadata-pointer): una capa de indirección que apunta a una cuenta [TokenGroup](/learn/token-2022/token-group) — externa o la propia mint para un grupo en línea.

## Por qué existe

Las colecciones de NFT, las familias de tokens y cualquier relación de «estos tokens van juntos» necesitan un ancla on-chain. Metaplex modela esto con un NFT de colección; Token-2022 lo modela con la SPL Token Group Interface. GroupPointer es el interruptor que dice «la configuración de grupo de este token está aquí», reflejando cómo funciona MetadataPointer para los metadatos, de modo que ambos sistemas componen de forma predecible.

## Diseño de bytes

Esta es la carga útil de una entrada TLV GroupPointer (`extension_type = 20`, `length = 64`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`     | `OptionalNonZeroPubkey` | Puede actualizar el puntero. Todo a cero = None — congelado. |
| 32 | 32 | `group_address` | `OptionalNonZeroPubkey` | Dónde vive la configuración de grupo. Todo a cero = None (no es parte de un grupo). |

Carga útil total: **64 bytes**.

## Las dos configuraciones

- **En línea:** `group_address == mint_address`. La mint también lleva una extensión `TokenGroup` con la configuración de tamaño/tamaño-máximo. Esta es la mint de «definición de grupo» — la colección en sí.
- **Externa:** `group_address` apunta a otra mint que contiene el TokenGroup. Este token es un candidato a *miembro* que apunta a su colección (los miembros se rastrean formalmente con la extensión separada TokenGroupMember).

## Dónde lo encuentras

Colecciones de NFT nativas de Token-2022 y familias de tokens. La adopción va por detrás de las colecciones de Metaplex, pero la Group Interface es la vía estándar para expresar pertenencia a una colección sin el programa Metaplex.

## Errores comunes

- **El puntero no es el grupo.** GroupPointer solo almacena una dirección. El recuento de miembros, el tamaño máximo y la autoridad de actualización viven en la extensión [TokenGroup](/learn/token-2022/token-group) en la cuenta apuntada.
- **Verifica la autoridad del grupo apuntado.** Como con MetadataPointer, cualquiera puede apuntar a la cuenta de grupo de otra persona para fingir pertenencia. Confía en el `update_authority` del grupo, no en el puntero en bruto.
- **`OptionalNonZeroPubkey`, no `COption`.** Campos de 32 bytes, todo a cero = None, sin byte de etiqueta — misma familia de codificación que las demás extensiones de Token-2022.
