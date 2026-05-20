---
name: COption frente a Option frente a OptionalNonZeroPubkey
summary: Solana tiene tres formas distintas de codificar un valor opcional, y no son intercambiables. El COption de SPL son 4 bytes de etiqueta, el Option de Borsh es 1, y el OptionalNonZeroPubkey de Token-2022 es 0 — la fuente más común de errores de offset en decodificadores.
---

## Qué es

«Este campo es opcional» se codifica de tres formas distintas en Solana según qué serialización use el programa. Confundirlas es la razón más común de que un decodificador escrito a mano se desvíe unos bytes y lea basura.

## Por qué existe

Distintas capas adoptaron convenciones distintas: SPL Token usa su propio formato `Pack` con una etiqueta de ancho fijo para la alineación, Borsh (Anchor, la mayoría de las apps) usa una etiqueta compacta de 1 byte, y Token-2022 optimiza las opciones de pubkey a cero overhead. Todas coexisten, a veces en la misma cuenta.

## Diseño de bytes

| Codificación | Dónde | None | Some(valor) | Total para `Option<Pubkey>` |
|--------------|-------|------|-------------|----------------------------:|
| `COption<T>` (`Pack` de SPL) | diseño base de SPL Token | etiqueta de 4 bytes `00 00 00 00` + espacio de valor a cero | etiqueta de 4 bytes `01 00 00 00` + valor | **36 bytes** (4 + 32) |
| `Option<T>` (Borsh) | Anchor, Metaplex, apps | etiqueta de 1 byte `00` | etiqueta de 1 byte `01` + valor | **33 bytes** (1 + 32) |
| `OptionalNonZeroPubkey` | extensiones de Token-2022 | 32 bytes todo a cero | la pubkey de 32 bytes | **32 bytes** (sin etiqueta) |

Las diferencias clave:

- **COption reserva espacio para el valor incluso cuando es None.** El `freeze_authority` de una `Mint` de SPL Token siempre ocupa 36 bytes en disco esté fijado o no — el diseño es de tamaño fijo.
- **El Option de Borsh omite el valor cuando es None.** Un None es un único byte `00`; los bytes del valor no están presentes en absoluto. Esto hace que las structs de Borsh sean de longitud variable.
- **OptionalNonZeroPubkey no tiene etiqueta alguna.** Una pubkey toda a cero *es* el centinela de None. Cero overhead, pero no puedes representar «Some(pubkey toda a cero)» — está bien para pubkeys, que nunca son todo a cero en la práctica.

## Dónde lo encuentras

- COption: autoridades de [Mint](/learn/spl-token/mint) y [Token Account](/learn/spl-token/token-account).
- Option de Borsh: campos de [metadatos de Metaplex](/learn/metaplex/token-metadata), campos de cuentas de Anchor.
- OptionalNonZeroPubkey: casi cada autoridad de [extensión de Token-2022](/learn/token-2022/transfer-fee-config).

## Errores comunes

- **Una mint de Token-2022 puede contener las tres.** El diseño base usa COption (etiquetas de 4 bytes), un campo Borsh incrustado podría usar Option (1 byte), y las extensiones usan OptionalNonZeroPubkey (0 de etiqueta). Decodificar una sección con la convención equivocada desplaza todo lo que sigue.
- **COption es little-endian de 4 bytes, valor 0 o 1.** No lo leas como un solo byte — que los bytes 1–3 sean cero es lo que hace que una lectura ingenua de 1 byte funcione por accidente para None y luego se rompa para Some.
- **El None de Borsh cambia el tamaño de la struct.** No puedes calcular el tamaño en bytes de una struct de Borsh solo a partir de su tipo si tiene Options — el tamaño depende de los valores.
- **Pubkey toda a cero significa None para OptionalNonZeroPubkey.** Los 32 bytes a cero son el marcador de None, no una dirección real.
