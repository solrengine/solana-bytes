---
name: MetadataPointer (extensión)
summary: Extensión del lado Mint de Token-2022 que registra dónde viven los metadatos de un token. Puede apuntar a una cuenta externa o a la propia mint para metadatos en línea — la respuesta de Token-2022 a Metaplex.
---

## Qué es

`MetadataPointer` registra *dónde* viven los metadatos de un token. Es una capa de indirección: el puntero puede referenciar una cuenta de metadatos externa (p. ej. una cuenta [Token Metadata de Metaplex](/learn/metaplex/token-metadata)) o puede apuntar a la propia mint, lo que significa que los metadatos se almacenan en línea mediante la extensión emparejada `TokenMetadata`.

## Por qué existe

Metaplex almacena los metadatos de NFT/token en una cuenta separada derivada de la mint por PDA — una segunda cuenta, un segundo programa, un segundo pago de rent. Token-2022 permite que una mint contenga sus propios metadatos en línea, eliminando la dependencia de Metaplex por completo. Pero el ecosistema todavía tiene metadatos de Metaplex por todas partes, así que Token-2022 necesita una forma de decir «mis metadatos están allí» *o* «mis metadatos están aquí mismo». MetadataPointer es ese interruptor.

## Diseño de bytes

Esta es la carga útil de una entrada TLV MetadataPointer (`extension_type = 18`, `length = 64`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`        | `OptionalNonZeroPubkey` | Puede actualizar el puntero. Todo a cero = None — puntero congelado. |
| 32 | 32 | `metadata_address` | `OptionalNonZeroPubkey` | Dónde viven los metadatos. Todo a cero = None (sin metadatos). |

Carga útil total: **64 bytes**.

## Las dos configuraciones

- **En línea:** `metadata_address == mint_address`. La mint también lleva una extensión `TokenMetadata` (tipo 19) que contiene el nombre, símbolo, URI y pares clave-valor adicionales en la misma cuenta. Sin segunda cuenta, sin Metaplex.
- **Externa:** `metadata_address` apunta a otra cuenta — normalmente una PDA de Token Metadata de Metaplex. El puntero es solo una pista; los campos reales viven en la cuenta referenciada y siguen el diseño de ese programa.

Una billetera que renderiza un token de Token-2022 lee primero el puntero, luego obtiene `metadata_address` para conseguir los campos visualizables.

## Dónde lo encuentras

La mayoría de los tokens de Token-2022 que muestran un nombre y un logo (PYUSD, stablecoins reguladas, nuevas mints estilo NFT) llevan un MetadataPointer. Los metadatos en línea son cada vez más el valor por defecto en los lanzamientos nuevos porque son autocontenidos — una cuenta contiene el token *y* su identidad.

## Errores comunes

- **El puntero no son los metadatos.** MetadataPointer solo almacena una dirección. El nombre/símbolo/URI real vive en línea (extensión TokenMetadata, tipo 19) o en la cuenta externa referenciada. Dos cosas distintas que decodificar.
- **`metadata_address == mint` es la señal de en línea.** Cuando el puntero apunta de vuelta a su propia mint, busca una extensión TokenMetadata en la lista TLV de la misma cuenta — ahí están los campos.
- **Un puntero fiable necesita una autoridad fiable.** Cualquiera puede crear una mint de Token-2022 que apunte su MetadataPointer a la cuenta de metadatos de *otra persona* para suplantar un token. Las billeteras deberían verificar la autoridad de actualización de los metadatos apuntados, no confiar a ciegas en el puntero.
- **`OptionalNonZeroPubkey`, no `COption`.** Ambos campos son de 32 bytes con todo a cero significando None — sin byte de etiqueta. Misma familia de codificación que las demás extensiones de Token-2022, distinta del `COption` de 4 bytes del diseño base.
