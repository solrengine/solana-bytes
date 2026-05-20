---
name: Token Account
summary: Guarda el saldo de un token concreto para un propietario concreto. Las Associated Token Accounts (ATAs) son la derivación estándar.
---

## Qué es

Una Token Account guarda el saldo de un único token para una única billetera. Cada saldo de un token SPL vive en su propia cuenta de 165 bytes.

## Por qué existe

SPL Token separa deliberadamente los metadatos de la mint (la cuenta [Mint](/learn/spl-token/mint)) de los saldos individuales (las Token Accounts). El mismo token —por ejemplo USDC— existe como exactamente una Mint y millones de Token Accounts, una por titular. La mayoría de las billeteras usan Associated Token Accounts (ATAs): dada una pubkey de billetera y una mint, la dirección de la ATA es la PDA determinista derivada del par, así que cualquier herramienta puede calcularla sin consultar la cadena.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0   | 32 | `mint`             | `Pubkey`            | Qué token guarda esta cuenta. |
| 32  | 32 | `owner`            | `Pubkey`            | Billetera que controla esta cuenta (firma las transferencias). |
| 64  | 8  | `amount`           | `u64` LE            | Saldo en unidades atómicas. |
| 72  | 36 | `delegate`         | `COption<Pubkey>`   | Etiqueta de 4 bytes + pubkey. El gastador aprobado, si lo hay. |
| 108 | 1  | `state`            | `u8` enum           | `0` Uninitialized, `1` Initialized, `2` Frozen. |
| 109 | 12 | `is_native`        | `COption<u64>`      | Etiqueta de 4 bytes + u64. Se activa en cuentas de wrapped SOL; el u64 es la reserva exenta de rent. |
| 121 | 8  | `delegated_amount` | `u64` LE            | Unidades atómicas que el delegado puede gastar. |
| 129 | 36 | `close_authority`  | `COption<Pubkey>`   | Etiqueta de 4 bytes + pubkey. Puede cerrar la cuenta y recuperar el rent. |

Total: **165 bytes**.

## Dónde lo encuentras

Te topas con Token Accounts cada vez que una billetera tiene un token SPL — en interfaces de billeteras, instrucciones de transferencia, rutas de swap de DEX y consultas de saldo. Un error «account not found» en una transferencia normalmente significa que la ATA del destinatario aún no se ha creado.

## Errores comunes

- **Las cuentas congeladas todavía pueden recibir tokens.** El estado `2` (Frozen) bloquea las transferencias salientes pero no las entrantes. Lo usan emisores como Circle por cumplimiento normativo.
- **`is_native` no es un booleano.** Es `COption<u64>` — cuando es Some, la cuenta es wrapped SOL y el u64 interno es la reserva de rent a preservar al cerrar.
- **Las ATAs son PDAs del programa SPL Associated Token Account**, no del programa Token. Las semillas de derivación son `[billetera, TOKEN_PROGRAM_ID, mint]`.
- **El `owner` de una Token Account es la *billetera*, no el programa Token.** El campo `owner` de la cabecera de la cuenta on-chain (no estos 165 bytes) es el programa Token; el campo `owner` de los datos es la billetera del usuario que autoriza los gastos.
