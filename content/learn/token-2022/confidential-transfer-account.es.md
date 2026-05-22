---
name: ConfidentialTransferAccount (extensión)
summary: Extensión del lado cuenta de Token-2022 que contiene los saldos cifrados con ElGamal de un titular. La contraparte de 295 bytes de ConfidentialTransferMint — donde viven los importes ocultos reales y la maquinaria de saldo pendiente.
---

## Qué es

Esta es la mitad del lado cuenta de las transferencias confidenciales. Mientras que [ConfidentialTransferMint](/learn/token-2022/confidential-transfer-mint) guarda la política de la mint, esta extensión de 295 bytes en cada [token account](/learn/spl-token/token-account) contiene los **saldos cifrados con ElGamal** del titular más la contabilidad de saldo pendiente que hace seguros los depósitos confidenciales frente a la repetición y el front-running.

## Por qué existe

Para operar de forma confidencial, cada cuenta necesita su propia clave de cifrado y textos cifrados de saldo que solo el propietario (y cualquier auditor) puede descifrar. La separación entre saldo «pendiente» y «disponible» existe para que las transferencias confidenciales entrantes no puedan usarse para fastidiar al destinatario — los depósitos aterrizan en pendiente y el propietario los aplica a disponible según su propio calendario.

## Diseño de bytes

Carga útil de una entrada TLV ConfidentialTransferAccount (`extension_type = 5`, `length = 295`). Añade los 4 bytes de cabecera TLV para la entrada completa.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0   | 1  | `approved`                                 | `bool` | Si la autoridad de la mint aprobó esta cuenta para uso confidencial. |
| 1   | 32 | `elgamal_pubkey`                           | `ElGamalPubkey` | La clave pública ElGamal de la cuenta (un punto Ristretto — no una clave Ed25519). |
| 33  | 64 | `pending_balance_lo`                        | `EncryptedBalance` | Texto cifrado twisted-ElGamal de los 16 bits bajos del saldo pendiente. |
| 97  | 64 | `pending_balance_hi`                        | `EncryptedBalance` | Texto cifrado de los 48 bits altos del saldo pendiente. |
| 161 | 64 | `available_balance`                         | `EncryptedBalance` | Texto cifrado del saldo gastable. |
| 225 | 36 | `decryptable_available_balance`             | `DecryptableBalance` | Saldo disponible cifrado con AES que el propietario puede descifrar de forma barata. |
| 261 | 1  | `allow_confidential_credits`                | `bool` | El propietario acepta transferencias confidenciales entrantes. |
| 262 | 1  | `allow_non_confidential_credits`            | `bool` | El propietario acepta transferencias no confidenciales entrantes. |
| 263 | 8  | `pending_balance_credit_counter`            | `u64` LE | Recuento de créditos pendientes recibidos. |
| 271 | 8  | `maximum_pending_balance_credit_counter`    | `u64` LE | Tope antes de que el propietario deba aplicar pendiente → disponible. |
| 279 | 8  | `expected_pending_balance_credit_counter`   | `u64` LE | Contador que el propietario esperaba en el último descifrado. |
| 287 | 8  | `actual_pending_balance_credit_counter`     | `u64` LE | Contador real en la última aplicación. |

Carga útil total: **295 bytes**.

## Por qué el saldo se divide en lo/hi y pendiente/disponible

Descifrar un texto cifrado ElGamal a un u64 completo es computacionalmente difícil (logaritmo discreto), así que el saldo se divide en un texto cifrado bajo de 16 bits y otro alto de 48 bits para mantener tratable el descifrado. La división pendiente/disponible más los contadores de crédito permiten al propietario detectar si llegaron nuevos depósitos desde su último descifrado, evitando una carrera en la que firme una transferencia contra un saldo obsoleto.

## Dónde lo encuentras

Token accounts de mints con transferencias confidenciales habilitadas, después de que el propietario configure la cuenta y deposite en el saldo confidencial. Los bytes son textos cifrados — opacos sin la clave ElGamal del propietario (o del auditor).

## Errores comunes

- **Ninguno de estos son claves Ed25519 ni importes en texto plano.** `elgamal_pubkey` es un punto Ristretto; los saldos son textos cifrados. No los renderices como direcciones ni números.
- **Dos dominios de saldo.** Los campos `*_balance` son textos cifrados twisted-ElGamal (64 bytes); `decryptable_available_balance` es un blob AES de 36 bytes que el propietario usa para lecturas baratas. Representan el mismo valor con esquemas distintos.
- **El pendiente debe aplicarse a disponible antes de gastar.** Los créditos confidenciales entrantes se acumulan en pendiente; `ApplyPendingBalance` los mueve a disponible. Una integración ingenua que ignore esto ve los depósitos «faltar» en el saldo gastable.
- **La extensión estándar más grande de Token-2022 con 295 bytes.** Una mint/cuenta que la lleve es sustancialmente más grande que una mínima.
