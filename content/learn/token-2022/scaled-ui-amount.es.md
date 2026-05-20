---
name: ScaledUiAmount (extensión)
summary: Extensión del lado Mint de Token-2022 que multiplica los saldos mostrados por un factor configurable. El importe on-chain no cambia; el importe de UI es amount × multiplicador — usado para rebase y visualización estilo split de acciones.
---

## Qué es

ScaledUiAmount aplica un multiplicador al saldo *mostrado* de un token. Como [InterestBearing](/learn/token-2022/interest-bearing-mint), el `amount` en bruto on-chain no cambia nunca — `amount_to_ui_amount` lo multiplica por el multiplicador actual. A diferencia del interés (que se compone con el tiempo), este es un factor único configurable que fija la autoridad, ideal para rebases y ajustes estilo split de acciones.

## Por qué existe

Algunos activos necesitan reexpresar su valor unitario: un fondo tokenizado que hace un split 2:1, una stablecoin con rebase, un token de recompensa que escala periódicamente. En lugar de emitir/quemar contra cada titular (lo que rompe la componibilidad), la mint simplemente cambia un multiplicador y el saldo mostrado de cada billetera escala de forma uniforme.

## Diseño de bytes

Esta es la carga útil de una entrada TLV ScaledUiAmount (`extension_type = 25`, `length = 56`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                          | `OptionalNonZeroPubkey` | Puede actualizar el multiplicador. Todo a cero = None (congelado). |
| 32 | 8  | `multiplier`                         | `f64` (IEEE-754 LE)     | Multiplicador de visualización actual. |
| 40 | 8  | `new_multiplier_effective_timestamp` | `i64` LE (segundos unix) | Cuándo toma el relevo `new_multiplier`. |
| 48 | 8  | `new_multiplier`                     | `f64` (IEEE-754 LE)     | Próximo multiplicador programado. |

Carga útil total: **56 bytes**.

## Por qué dos multiplicadores + un timestamp

Como el patrón older/newer de la configuración de comisiones, un cambio de multiplicador puede programarse: fija `new_multiplier` con un `new_multiplier_effective_timestamp` futuro, y los decodificadores aplican `multiplier` hasta ese momento, luego `new_multiplier`. Una UI correcta elige el multiplicador activo según el reloj del clúster.

## Dónde lo encuentras

Fondos tokenizados, tokens con rebase y cualquier activo que reexprese periódicamente su valor unitario. Más nuevo que la mayoría de las extensiones (tipo 25), así que la adopción es temprana pero creciente para productos RWA.

## Errores comunes

- **Punto flotante on-chain — raro y notable.** El multiplicador es un `f64` IEEE-754 real (8 bytes, little-endian). La mayoría de los campos de Solana son enteros; este es uno de los pocos f64. Decodifica los 8 bytes como un double, no como un u64.
- **El `amount` en bruto nunca se escala.** Como con los tokens con interés, leer el `amount` de una [token account](/learn/spl-token/token-account) directamente sub/sobreestima el valor. Pásalo por `amountToUiAmount`.
- **El multiplicador programado necesita el reloj.** No muestres `new_multiplier` como actual hasta que haya pasado `new_multiplier_effective_timestamp`.
- **Distinto del interés.** El interés se compone de forma continua a partir de una tasa; ScaledUiAmount es un factor discreto que fija la autoridad. Un token usa uno u otro, no ambos, para el mismo propósito.
