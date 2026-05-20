---
name: TokenGroup (extensión)
summary: Extensión del lado Mint de Token-2022 que define un grupo (colección) — su autoridad de actualización, la mint del grupo y el recuento de miembros actual/máximo. El análogo de una colección de Metaplex en la Group Interface.
---

## Qué es

`TokenGroup` define una colección: un grupo con nombre al que otros tokens pueden pertenecer, con un recuento de miembros actual y un tope rígido. Implementa la SPL Token Group Interface y es el equivalente nativo de Token-2022 a un NFT de colección de Metaplex — el «padre» al que los miembros apuntan de vuelta.

## Por qué existe

Las colecciones necesitan una definición on-chain canónica: quién controla la colección, cuántos miembros existen y el máximo permitido. Sin un tope, una colección puede diluirse; sin un recuento, no puedes mostrar «#42 de 100». TokenGroup almacena exactamente eso, y la extensión [GroupPointer](/learn/token-2022/group-pointer) es cómo una mint anuncia que lleva (o referencia) uno.

## Diseño de bytes

Esta es la carga útil de una entrada TLV TokenGroup (`extension_type = 21`, `length = 80`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `update_authority` | `OptionalNonZeroPubkey` | Puede actualizar el grupo (p. ej. subir max_size). Todo a cero = None — congelado. |
| 32 | 32 | `mint`             | `Pubkey`                | La propia mint del grupo. Debería coincidir con la cuenta contenedora para un grupo en línea. |
| 64 | 8  | `size`             | `u64` LE                | Número actual de miembros. Mantenido por el programa al añadir miembros. |
| 72 | 8  | `max_size`         | `u64` LE                | Máximo de miembros permitidos. Añadir un miembro pasado este tope falla. |

Carga útil total: **80 bytes**.

## Cómo se unen los miembros

Un token miembro lleva una extensión `TokenGroupMember` que apunta a la mint de este grupo, y el `size` del grupo se incrementa cuando el miembro se inicializa. El `update_authority` del grupo controla si `max_size` puede cambiar. Juntos, GroupPointer + TokenGroup + TokenGroupMember reflejan la maquinaria de colección/creador-verificado de Metaplex en la Group Interface.

## Dónde lo encuentras

Colecciones de NFT nativas de Token-2022 y familias de tokens acotadas. La mayoría de las colecciones de NFT en producción aún usan Metaplex, pero la Group Interface es la vía estándar para la semántica de colección sin un programa aparte.

## Errores comunes

- **`size` lo mantiene el programa, no el usuario.** No lo escribas directamente — refleja cuántos miembros se han inicializado contra el grupo. Confía en él como contador, pero verifica los tokens miembro individualmente si importa la procedencia.
- **`max_size` puede subirlo la autoridad de actualización** (si existe). «Limitado a 100» es solo tan firme como que la autoridad sea None. Muestra el estado de la autoridad al exhibir la escasez.
- **El campo `mint` debería coincidir con la cuenta.** Como con TokenMetadata, un grupo podría afirmar una mint diferente. Verifícalo antes de confiar.
- **En línea frente a externo refleja a GroupPointer.** Cuando `group-pointer.group_address == mint`, busca esta extensión en la misma cuenta; si no, vive en la mint referenciada.
