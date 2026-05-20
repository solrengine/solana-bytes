---
name: Token-2022 Mint/Account + Extensiones
summary: Las Mints y Token Accounts de Token-2022 comparten los diseños base de SPL Token y añaden funciones como bloques de extensión TLV posteriores a la base — un discriminador de 1 byte en el offset 165 distingue Mint de TokenAccount.
---

## Qué es

Token-2022 es un programa de tokens paralelo que mantiene los diseños base de [Mint](/learn/spl-token/mint) y [TokenAccount](/learn/spl-token/token-account) idénticos byte a byte a SPL Token y añade funciones mediante extensiones. Una Mint de Token-2022 es propiedad de `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` en lugar de `TokenkegQ…`; todo lo demás sobre los primeros 82 bytes (Mint) o 165 bytes (TokenAccount) sigue el mismo camino de código.

## Por qué existe

SPL Token se lanzó en 2020 con diseños de cuenta fijos. Añadir campos habría invalidado cada token existente en Solana, así que las nuevas funciones —comisiones de transferencia, acumulación de intereses, transferencias confidenciales, metadatos, transfer hooks, importes de UI escalados— llegaron en Token-2022 como **extensiones TLV posteriores a la base**. El compromiso es intencionado: los tokens de SPL Token permanecen estables para siempre, y las funciones nuevas viven en un programa nuevo al que exploradores y billeteras se adhieren.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 82 o 165 | base | base SPL Token | Idéntico byte a byte a [Mint](/learn/spl-token/mint) (82) o [TokenAccount](/learn/spl-token/token-account) (165). |
| 82 | 83 | relleno (solo Mints) | bytes a cero | Las Mints se rellenan con ceros hasta 165 para que el discriminador quede en un offset fijo sin importar el tipo base. |
| 165 | 1 | `account_type` | `u8` enum | `1` = Mint, `2` = TokenAccount. Única forma fiable on-chain de distinguirlos, ya que ambos ocupan 165 bytes antes de que empiecen las extensiones. |
| 166 | variable | extensiones | TLV[] | Una entrada por extensión activa. Consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer) para el formato de la cabecera de 4 bytes y el algoritmo de recorrido. |

Una Mint de Token-2022 sin extensiones ocupa exactamente 166 bytes (82 base + 83 relleno + 1 discriminador). Cualquier tamaño mayor lleva extensiones adjuntas.

## Dónde lo encuentras

Token-2022 es la capa detrás de una porción creciente de tokens regulados y con funciones avanzadas: PYUSD (la stablecoin de PayPal), el token BUIDL de BlackRock, tokens de activos del mundo real (RWA) con rendimiento, y la mayoría de los lanzamientos nuevos orientados a pagos. SPL Token sigue anclando la larga cola de memecoins y emisiones anteriores a 2024, así que billeteras e indexadores deben manejar ambos programas.

## Errores comunes

- **El propietario del programa es la única señal de tipo fiable.** Una cuenta de 200 bytes podría ser una Mint de Token-2022 con extensiones, una cuenta personalizada de un programa ajeno, o cualquier otra cosa. Lee primero `accountInfo.owner` — si es `Tokenz…`, los bytes siguen este diseño. El tamaño por sí solo no te dice nada.
- **Una Mint y una TokenAccount de Token-2022 pueden tener el mismo tamaño.** Ambas comparten los offsets 0–164 tras el relleno de la Mint; el byte `account_type` en el offset 165 es el discriminador. Los decodificadores que infieren el tipo a partir del tamaño se equivocan con cualquier Mint que tenga aunque sea una pequeña extensión.
- **El diseño base usa el `COption` de SPL (etiqueta de 4 bytes).** Las extensiones no — la mayoría usa `OptionalNonZeroPubkey` (32 bytes, todo a cero = None) o `Option<T>` de Borsh (etiqueta de 1 byte). Tres codificaciones opcionales coexisten en una sola cuenta de Token-2022; elige la equivocada y tu decodificador se desliza tres o cuatro bytes.
- **Las extensiones se añaden de forma incremental a nivel de programa, pero aparecen en un orden fijo on-chain.** El programa Token-2022 las serializa en un orden estable determinado por el número de tipo de extensión, no por el orden de inicialización. Si escribes un decodificador que depende del orden de las extensiones, seguirá funcionando — pero no asumas que el orden por cuenta refleja la cronología del usuario.
