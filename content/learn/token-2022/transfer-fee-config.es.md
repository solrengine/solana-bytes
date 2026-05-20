---
name: TransferFeeConfig (extensión)
summary: Extensión del lado Mint de Token-2022 que cobra una comisión porcentual en cada transferencia. Las comisiones se acumulan como saldos retenidos en las Token Accounts destinatarias y las reclama más tarde la autoridad de retiro.
---

## Qué es

`TransferFeeConfig` es una extensión de Mint de Token-2022 que impone una comisión porcentual en cada transferencia del token. Las comisiones no van a una tesorería en el momento de la transferencia — se acumulan como saldos **retenidos** dentro de la Token Account del destinatario (mediante la extensión emparejada `TransferFeeAmount`), y la `withdraw_withheld_authority` las reclama más tarde.

## Por qué existe

SPL Token no tiene comisiones nativas. Los protocolos (DEX, apps de pago, aplicadores de regalías de NFT) cobran comisiones enrutando a través de una billetera extra a nivel de aplicación — con pérdidas, difícil de auditar, fácil de eludir. Token-2022 permite que la *propia Mint* aplique una política de comisiones, de modo que cada transferencia del token paga la comisión, ya pase por un DEX, un envío de billetera o una CPI desde otro protocolo.

## Diseño de bytes

Esta es la **carga útil** de una entrada TLV TransferFeeConfig (`extension_type = 1`, `length = 108`). La entrada on-chain completa son 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)) más esta carga útil de 108 bytes.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `transfer_fee_config_authority` | `OptionalNonZeroPubkey` | Actualiza la configuración de comisiones. Pubkey a cero = None (deshabilitada — comisiones congeladas para siempre). Sin byte de etiqueta. |
| 32 | 32 | `withdraw_withheld_authority`   | `OptionalNonZeroPubkey` | Reclama las comisiones retenidas de las Token Accounts. Todo a cero = None (comisiones no cobrables). |
| 64 | 8  | `withheld_amount`               | `u64` LE                | Total de comisiones retenidas a nivel de Mint (separado de los montos retenidos por cuenta). |
| 72 | 18 | `older_transfer_fee`            | struct `TransferFee`    | Configuración previa a la actualización — activa hasta que llega `newer.epoch`. |
| 90 | 18 | `newer_transfer_fee`            | struct `TransferFee`    | Configuración activa a partir de `newer.epoch`. |

El struct anidado `TransferFee` ocupa **18 bytes**:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 8 | `epoch`                     | `u64` LE | Epoch en que esta configuración entró (o entrará) en vigor. |
| 8  | 8 | `maximum_fee`               | `u64` LE | Tope absoluto en unidades atómicas (por transferencia). |
| 16 | 2 | `transfer_fee_basis_points` | `u16` LE | Tasa de comisión en puntos básicos (100 = 1%). |

Carga útil total: **108 bytes**.

## Por qué dos configuraciones de comisión

Los cambios de comisión no surten efecto de inmediato. Cuando la autoridad fija una nueva comisión vía `SetTransferFee`, el valor va a `newer_transfer_fee` con `epoch` fijado dos epochs por delante; hasta entonces, la red sigue cobrando `older_transfer_fee`. El modelo de dos configuraciones + epoch da a los titulares una ventana para reaccionar antes de que entre la nueva tasa.

Un decodificador que muestre la comisión *actual* debe leer el epoch actual del clúster y elegir `newer` si `epoch_actual >= newer.epoch`, en caso contrario `older`. Mostrar solo `newer.transfer_fee_basis_points` es el error canónico aquí.

## Dónde lo encuentras

PYUSD (la stablecoin de PayPal) lleva esta extensión con una configuración de 0 puntos básicos — presente para la auditabilidad de cumplimiento sin cobrar realmente. Los despliegues con comisión real son más raros pero crecientes: tokens comunitarios de reparto de ingresos, tokens RWA con regalías de transferencia, y algunos memecoins experimentales que enrutan comisiones a una billetera del creador.

## Errores comunes

- **Las extensiones de Token-2022 usan una tercera codificación opcional: `OptionalNonZeroPubkey`.** Mismo tamaño de 32 bytes que una `Pubkey` normal sin byte de etiqueta — todos los bytes a cero significan None. Distinta tanto del `COption<Pubkey>` de SPL (etiqueta de 4 bytes + 32 = 36 bytes) como del `Option<Pubkey>` de Borsh (etiqueta de 1 byte + 32 = 33 bytes). Tres codificaciones opcionales coexisten en una sola cuenta de Token-2022.
- **Las comisiones se retienen, no se queman.** La comisión se resta del saldo del emisor y aterriza en la extensión `TransferFeeAmount.withheld_amount` por cuenta del destinatario. La `withdraw_withheld_authority` luego las recoge vía `WithdrawWithheldTokensFromAccounts` y `WithdrawWithheldTokensFromMint`.
- **`maximum_fee` es por transferencia, no por periodo.** Una comisión del 1% sobre una transferencia de 1.000.000 USDC con `maximum_fee = 1000` se topa en $0,001 (unidades atómicas = 1000), no en los $10.000 que implicarían los puntos básicos sobre una comisión sin tope.
- **Retraso de actualización de dos epochs.** Fijar una nueva comisión no surte efecto hasta el epoch *siguiente al siguiente* — aproximadamente cuatro o cinco días en producción. Planifica los textos de la interfaz y las notificaciones en torno a ese retraso.
- **Leer la comisión activa requiere el epoch actual del clúster.** No muestres los parámetros de `newer_transfer_fee` como «la comisión» a menos que el epoch haya cambiado; de lo contrario, los usuarios ven una tasa que aún no están pagando.
