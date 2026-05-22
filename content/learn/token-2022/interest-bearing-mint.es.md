---
name: InterestBearingConfig (extensión)
summary: Extensión del lado Mint de Token-2022 que hace que un token acumule intereses de forma continua. El saldo almacenado no cambia nunca — el importe de UI se calcula a partir de una tasa y el tiempo transcurrido.
---

## Qué es

`InterestBearingConfig` es una extensión de Mint de Token-2022 que hace que un token *parezca* acumular intereses compuestos de forma continua. El detalle clave: nunca se escribe interés alguno en ninguna cuenta. El `amount` en bruto de cada Token Account permanece exactamente como se emitió o transfirió — el interés es una **transformación de visualización** aplicada por `amount_to_ui_amount`, calculada a partir de la tasa y el tiempo transcurrido.

## Por qué existe

Los tokens con rebase (donde los saldos crecen on-chain) rompen la componibilidad — cada transferencia tendría que tocar un índice global, y los integradores ven los saldos cambiar bajo sus pies. El enfoque de Token-2022 mantiene el saldo on-chain inmutable y empuja el cálculo del interés a una función determinista de `(principal, tasa, tiempo_transcurrido)`. Las billeteras y exploradores llaman a `amountToUiAmount` para mostrar el valor crecido; el ledger permanece limpio.

## Diseño de bytes

Esta es la carga útil de una entrada TLV InterestBearingConfig (`extension_type = 10`, `length = 52`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `rate_authority`            | `OptionalNonZeroPubkey` | Puede cambiar la tasa. Todo a cero = None — tasa congelada para siempre. |
| 32 | 8  | `initialization_timestamp`  | `i64` LE (segundos unix) | Cuándo se inicializó la extensión. |
| 40 | 2  | `pre_update_average_rate`   | `i16` LE puntos básicos | Tasa media ponderada por tiempo que aplicaba *antes* de la última actualización. |
| 42 | 8  | `last_update_timestamp`     | `i64` LE (segundos unix) | Cuándo entró en vigor `current_rate`. |
| 50 | 2  | `current_rate`              | `i16` LE puntos básicos | Tasa vigente desde `last_update_timestamp`. Con signo — puede ser negativa. |

Carga útil total: **52 bytes**.

## Por qué dos tasas

El interés debe ser continuo a través de los cambios de tasa. El importe acumulado *antes* de la última actualización se calcula con `pre_update_average_rate` sobre `(initialization_timestamp → last_update_timestamp)`; el importe acumulado *desde entonces* usa `current_rate` sobre `(last_update_timestamp → ahora)`. El campo «average» comprime todo el historial previo a la actualización en una sola tasa combinada para que el cálculo siga siendo O(1) por muchas veces que haya cambiado la tasa.

## Dónde lo encuentras

Las stablecoins con rendimiento y los productos de tesorería tokenizados usan esto para que el saldo mostrado de un titular crezca sin ninguna transacción on-chain. Es más común en tokens RWA (activos del mundo real) donde el emisor publica un APY como tasa en puntos básicos.

## Errores comunes

- **El `amount` on-chain nunca refleja el interés.** Si lees el `amount` en bruto de una Token Account y lo muestras directamente, subestimarás el valor del titular. Pásalo siempre por `amountToUiAmount` para mints con interés.
- **La tasa tiene signo (`i16`).** Las tasas negativas son legales — un token con demurrage que encoge con el tiempo. No la parsees como sin signo.
- **Puntos básicos, compuestos de forma continua.** `current_rate = 500` es un 5% TAE compuesto continuamente, no un 5% simple. El programa usa `e^(tasa × t)`, así que el importe mostrado diverge del cálculo de interés simple ingenuo en horizontes largos.
- **`rate_authority = None` congela la tasa, no el interés.** El interés sigue acumulándose a la última tasa fijada para siempre; None solo significa que nadie puede cambiarla.
