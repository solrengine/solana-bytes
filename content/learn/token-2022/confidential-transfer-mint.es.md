---
name: ConfidentialTransferMint (extensión)
summary: Extensión del lado Mint de Token-2022 que habilita las transferencias confidenciales — los importes se cifran on-chain con ElGamal y se prueban correctos con pruebas de conocimiento cero. Esta extensión guarda la política; los saldos cifrados viven en el lado cuenta.
---

## Qué es

`ConfidentialTransferMint` activa las transferencias confidenciales de un token. Cuando se habilita, los importes de transferencia se **cifran on-chain con ElGamal** — el ledger registra que ocurrió una transferencia y prueba que fue válida (sin saldos negativos, sin inflación) usando pruebas de conocimiento cero, pero el importe en sí queda oculto a la vista pública. Esta extensión del lado Mint es la *política*; los saldos cifrados reales viven en la extensión `ConfidentialTransferAccount` por cuenta.

## Por qué existe

Los importes públicos son un problema real para nóminas, liquidación B2B y cualquier uso institucional donde los tamaños de transacción son sensibles. Las transferencias confidenciales dan privacidad de importe manteniendo la verificación sin confianza de Solana — la red nunca ve el texto plano pero aún puede probar que la aritmética es correcta. La clave del auditor proporciona una vía de escape para cumplimiento, de modo que una parte designada puede descifrar cuando se requiera.

## Diseño de bytes

Esta es la carga útil de una entrada TLV ConfidentialTransferMint (`extension_type = 4`, `length = 65`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 32 | `authority`                 | `OptionalNonZeroPubkey`            | Configura los ajustes de transferencia confidencial de esta mint. Todo a cero = None — configuración congelada. |
| 32 | 1  | `auto_approve_new_accounts` | `PodBool` (`u8`)                   | `1` = las cuentas nuevas pueden usar transferencias confidenciales de inmediato; `0` = cada cuenta debe ser aprobada antes por la autoridad. |
| 33 | 32 | `auditor_elgamal_pubkey`    | `OptionalNonZeroElGamalPubkey`     | Auditor opcional que puede descifrar cada importe de transferencia. Todo a cero = None (sin auditor). |

Carga útil total: **65 bytes**.

## Por qué el importe no está aquí

Esta extensión no lleva saldos — solo política. El saldo cifrado de cada titular, los contadores de saldo pendiente y la pubkey ElGamal por cuenta viven en la extensión del lado cuenta `ConfidentialTransferAccount`. Una instrucción de transferencia confidencial va acompañada de instrucciones de prueba ZK (pruebas de rango, pruebas de igualdad) verificadas por el programa ZK ElGamal Proof; el programa de tokens comprueba las pruebas y luego actualiza los textos cifrados sin ver nunca el texto plano.

## Dónde lo encuentras

Stablecoins institucionales y rieles de pago que necesitan privacidad de importe. La adopción aún es temprana porque la criptografía del lado cliente (generar pruebas, gestionar claves ElGamal) es más pesada que una transferencia normal, pero es la función estrella de privacidad de Token-2022.

## Errores comunes

- **Una pubkey ElGamal no es una pubkey Ed25519.** Ambas son de 32 bytes, pero `auditor_elgamal_pubkey` es un punto Ristretto comprimido usado para cifrado ElGamal — no la renderices ni la valides como una dirección Solana normal.
- **`auto_approve_new_accounts = false` es una lista de permitidos.** Cuando es false, la autoridad de la mint debe aprobar cada cuenta antes de que pueda operar de forma confidencial — una palanca de permisos para tokens regulados.
- **El auditor puede descifrar importes, no incautar fondos.** La clave del auditor concede acceso de lectura a los textos cifrados, no autoridad de transferencia. No la confundas con [PermanentDelegate](/learn/token-2022/permanent-delegate).
- **Política de mint ≠ estado de cuenta.** Esta extensión solo dice que las transferencias confidenciales son *posibles*. Una billetera también debe configurar la extensión del lado cuenta y depositar en el saldo confidencial antes de poder enviar de forma confidencial.
