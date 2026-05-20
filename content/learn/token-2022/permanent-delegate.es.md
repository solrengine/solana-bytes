---
name: PermanentDelegate (extensión)
summary: Extensión del lado Mint de Token-2022 que otorga a una dirección autoridad ilimitada para transferir o quemar tokens de cualquier cuenta de la mint, para siempre. La primitiva de clawback — poderosa y peligrosa.
---

## Qué es

`PermanentDelegate` nombra una única dirección que puede transferir o quemar tokens de **cualquier** cuenta que tenga esta mint, en **cualquier** cantidad, **sin la aprobación del propietario de la cuenta** — de forma permanente. Es la primitiva de clawback: el emisor conserva la capacidad de mover o destruir tokens sin importar quién los tenga.

## Por qué existe

Algunos activos requieren legalmente poderes de recuperación: stablecoins reguladas que deben congelar e incautar fondos vinculados a direcciones sancionadas, estudios de juegos que necesitan revocar objetos, tokens empresariales con obligaciones de cumplimiento. SPL Token no tiene tal mecanismo — una vez que un token sale de tu cuenta, solo el titular puede moverlo. Token-2022 añade el delegado permanente para que los emisores que necesitan clawback puedan tenerlo (y los titulares puedan ver que existe antes de tenerlo).

## Diseño de bytes

Esta es la carga útil de una entrada TLV PermanentDelegate (`extension_type = 12`, `length = 32`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 32 | `delegate` | `OptionalNonZeroPubkey` | El delegado permanente. Todo a cero = None — sin delegado permanente (no puede añadirse después si la mint se lanzó sin él). |

Carga útil total: **32 bytes**.

## Dónde lo encuentras

Stablecoins de grado de cumplimiento, activos del mundo real tokenizados con requisitos legales de recuperación, y economías de juegos. Cualquier token donde el emisor deba conservar el control tras la distribución.

## Errores comunes

- **Anula al propietario por completo.** El delegado permanente no necesita la firma del titular ni una aprobación de delegado por cuenta. Puede actuar sobre cada cuenta de la mint a voluntad. Trata cualquier token con esta extensión como custodial en espíritu.
- **Muéstralo de forma destacada en las billeteras.** Los usuarios deberían saber, antes de adquirir un token, que un tercero puede moverlo o quemarlo. Una billetera de grado de referencia marca PermanentDelegate como marca una autoridad de congelación — posiblemente con más fuerza.
- **No puede añadirse después.** Como la mayoría de las extensiones de mint, debe estar presente cuando se crea la mint. Una mint que se lanzó sin él nunca puede ganar un delegado permanente — lo cual es en sí una señal de confianza útil.
- **Distinto de la clave del auditor.** El auditor de [ConfidentialTransferMint](/learn/token-2022/confidential-transfer-mint) solo puede *leer* importes; el delegado permanente puede *mover y destruir* tokens. No confundas los dos poderes.
