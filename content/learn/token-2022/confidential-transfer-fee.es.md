---
name: ConfidentialTransferFee (extensión)
summary: El par de extensiones que hacen funcionar las comisiones de transferencia sobre transferencias confidenciales — una configuración del lado mint con una clave ElGamal para comisiones retenidas cifradas, y un importe retenido cifrado del lado cuenta.
---

## Qué es

Cuando un token tiene a la vez [comisiones de transferencia](/learn/token-2022/transfer-fee-config) y [transferencias confidenciales](/learn/token-2022/confidential-transfer-mint), las propias comisiones retenidas deben permanecer cifradas — de lo contrario la comisión filtraría el importe de la transferencia. Este par de extensiones se encarga de eso: un `ConfidentialTransferFeeConfig` del lado mint y un `ConfidentialTransferFeeAmount` del lado cuenta, ambos manteniendo las comisiones retenidas como textos cifrados ElGamal.

## Por qué existe

Una comisión retenida en texto plano sobre un token con comisión porcentual revela el importe de la transferencia (importe = comisión / tasa). Para preservar la confidencialidad, la comisión retenida se cifra bajo una clave ElGamal dedicada en poder de la autoridad de retiro, que puede descifrar y cobrar sin que el público vea importes individuales.

## Diseño de bytes

**ConfidentialTransferFeeConfig** — del lado mint (`extension_type = 16`):

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                                  | `OptionalNonZeroPubkey` | Configura la comisión confidencial. Todo a cero = None. |
| 32 | 32 | `withdraw_withheld_authority_elgamal_pubkey` | `ElGamalPubkey`         | Clave ElGamal bajo la que se cifran las comisiones retenidas. |
| 64 | 1  | `harvest_to_mint_enabled`                    | `bool`                  | Si las cuentas pueden cosechar las comisiones retenidas hacia la mint. |
| 65 | 64 | `withheld_amount`                            | `EncryptedWithheldAmount` | Texto cifrado ElGamal de las comisiones retenidas en la mint. |

Total: **129 bytes**.

**ConfidentialTransferFeeAmount** — del lado cuenta (`extension_type = 17`):

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 64 | `withheld_amount` | `EncryptedWithheldAmount` | Texto cifrado ElGamal de las comisiones retenidas en esta cuenta. |

Total: **64 bytes**.

## Cómo se relaciona con la comisión en texto plano

Un token puede tener un [TransferFeeConfig](/learn/token-2022/transfer-fee-config) (la política de tasa/tope) *y* este par confidencial (la retención cifrada) a la vez. Las transferencias no confidenciales retienen texto plano en `TransferFeeAmount`; las transferencias confidenciales retienen texto cifrado en `ConfidentialTransferFeeAmount`. La autoridad de retiro recoge ambos.

## Dónde lo encuentras

Tokens que combinan comisiones porcentuales con privacidad de importe — tempranos y raros, pero la vía estándar para activos «privados pero con comisión».

## Errores comunes

- **La comisión retenida se cifra bajo una clave ElGamal separada**, distinta de la clave de cuenta de cualquier titular — la de `withdraw_withheld_authority_elgamal_pubkey`. Solo esa autoridad puede descifrar los totales retenidos.
- **Dos extensiones, dos lados.** Config (16) es del lado mint; Amount (17) es del lado cuenta. No esperes que el blob de 64 bytes del lado cuenta lleve los campos de política.
- **Requiere tener habilitadas tanto las transferencias confidenciales como las comisiones de transferencia.** Este par solo aparece en mints que tienen ambas funciones — es el puente entre ellas.
- **`withheld_amount` es un texto cifrado, no un número.** 64 bytes de ElGamal, no un u64. Decodifícalo solo con la clave de la autoridad de retiro.
