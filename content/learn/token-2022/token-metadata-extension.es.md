---
name: TokenMetadata (extensión)
summary: Extensión del lado Mint de Token-2022 que almacena nombre, símbolo, URI y pares clave-valor arbitrarios en línea dentro de la cuenta mint — la alternativa autocontenida de Token-2022 a una cuenta de metadatos de Metaplex aparte.
---

## Qué es

`TokenMetadata` almacena el nombre, símbolo, URI fuera de la cadena y una lista arbitraria de pares clave-valor de un token **en línea, en la propia cuenta mint**. Implementa la SPL Token Metadata Interface, y es lo que hace que una mint de Token-2022 se describa a sí misma — sin cuenta separada, sin programa Metaplex, sin derivación de PDA.

## Por qué existe

La cuenta [Token Metadata](/learn/metaplex/token-metadata) de Metaplex es una segunda cuenta, propiedad de un segundo programa, que requiere un segundo pago de rent y una CPI para crearse. Para tokens que solo necesitan un nombre y un logo, son muchas piezas móviles. Token-2022 lo colapsa: los metadatos viven en la mint, controlados por el [MetadataPointer](/learn/token-2022/metadata-pointer) apuntando de vuelta a la mint.

## Diseño de bytes

Esta es una extensión de **longitud variable** (`extension_type = 19`); su campo `length` de TLV da el tamaño total de la carga útil. A diferencia de las cadenas con relleno fijo de Metaplex, cada cadena aquí es una verdadera cadena de Borsh con prefijo de longitud: un `u32` LE de 4 bytes seguido de exactamente esos bytes UTF-8, sin relleno.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `update_authority`     | `OptionalNonZeroPubkey` | Puede actualizar los campos. Todo a cero = None — metadatos congelados. |
| 32 | 32 | `mint`                 | `Pubkey`                | La mint que describen estos metadatos. Debería coincidir con la cuenta contenedora. |
| 64 | 4+N | `name`                | `String` de Borsh       | Longitud LE de 4 bytes + bytes UTF-8. Sin máximo fijo. |
| …  | 4+N | `symbol`              | `String` de Borsh       | Longitud LE de 4 bytes + bytes UTF-8. |
| …  | 4+N | `uri`                 | `String` de Borsh       | Longitud LE de 4 bytes + bytes UTF-8. Apunta al JSON fuera de la cadena. |
| …  | 4+… | `additional_metadata` | `Vec<(String, String)>` | Conteo LE de 4 bytes, luego esa cantidad de pares clave/valor, cada uno una `String` de Borsh. |

La longitud total es la que sumen las cadenas — no hay tamaño de cuenta fijo.

## Cómo se empareja con MetadataPointer

Una billetera que renderiza el token lee primero [MetadataPointer](/learn/token-2022/metadata-pointer). Cuando el `metadata_address` del puntero es igual a la propia dirección de la mint, el renderizador busca *esta* extensión en la lista TLV de la misma cuenta y decodifica los campos aquí. El puntero es el «dónde», TokenMetadata es el «qué».

## Dónde lo encuentras

Lanzamientos autocontenidos de Token-2022: PYUSD, stablecoins reguladas y la oleada de mints de 2025–2026 que se saltan Metaplex por completo. `additional_metadata` se usa cada vez más para cosas como `["description", …]`, `["category", …]`, o etiquetas de cumplimiento específicas del emisor.

## Errores comunes

- **Cadenas de longitud variable, no los campos con relleno de Metaplex.** Metaplex rellena el nombre hasta 32, el símbolo hasta 10, el uri hasta 200 bytes. TokenMetadata usa verdaderas cadenas de Borsh — prefijo de longitud de 4 bytes, recuento exacto de bytes, sin ceros finales. Un decodificador construido para una leerá mal la otra.
- **`additional_metadata` no tiene cota.** Es un `Vec` de pares de cadenas sin esquema. Trata las claves como entrada no fiable — sanea antes de renderizar (caracteres de control, anulaciones bidi, longitud).
- **El campo `mint` debería coincidir con la cuenta, pero verifícalo.** Una mint maliciosa podría incrustar metadatos que afirmen una pubkey de mint diferente. Comprueba que `metadata.mint == account_pubkey` antes de confiar en ello.
- **Esta extensión hace crecer la cuenta.** Como es de longitud variable y normalmente la última extensión, añadir entradas a `additional_metadata` reasigna la cuenta y requiere más rent. El programa Token-2022 gestiona la reasignación, pero el pagador de comisiones cubre el nuevo rent.
