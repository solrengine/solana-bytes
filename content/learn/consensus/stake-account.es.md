---
name: Stake Account
summary: Delega SOL a la cuenta Vote de un validador. Registra las autoridades de staker/withdrawer, el lockup, el importe delegado y los epochs de activación.
---

## Qué es

Una cuenta Stake delega SOL a la cuenta Vote de un validador para ganar recompensas de staking. El diseño de 200 bytes registra quién puede gestionar el stake, cuánto se delega y cuándo aterriza la activación o la desactivación.

## Por qué existe

El consenso proof-of-stake de Solana funciona sobre estas delegaciones. Los titulares de SOL crean cuentas Stake que apuntan a la [cuenta Vote](/learn/consensus/vote-account) de un validador; el programa Stake gestiona la activación basada en epochs, calcula las recompensas por epoch y registra los créditos que ha ganado el validador. Los protocolos de liquid staking como Marinade y Jito mantienen grandes pools de cuentas Stake en nombre de sus depositantes.

## Diseño de bytes

El diseño es un enum de estado de 4 bytes seguido de una struct `Meta` y (cuando el estado es `Stake`) una struct `Delegation`.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0   | 4  | `state`                 | `u32` enum    | `0` Uninitialized, `1` Initialized, `2` Stake, `3` RewardsPool. |
| 4   | 8  | `rent_exempt_reserve`   | `u64` LE      | SOL reservado para la exención de rent. |
| 12  | 32 | `authorized_staker`     | `Pubkey`      | Puede delegar, desactivar, dividir, fusionar. |
| 44  | 32 | `authorized_withdrawer` | `Pubkey`      | Puede retirar fondos. Normalmente en almacenamiento en frío. |
| 76  | 8  | `lockup.unix_timestamp` | `i64` LE      | El lockup expira en este tiempo UNIX. |
| 84  | 8  | `lockup.epoch`          | `u64` LE      | El lockup expira en este epoch. |
| 92  | 32 | `lockup.custodian`      | `Pubkey`      | Puede saltarse el lockup. |
| 124 | 32 | `voter_pubkey`          | `Pubkey`      | Cuenta Vote a la que delega este stake. |
| 156 | 8  | `stake_amount`          | `u64` LE      | SOL delegado en lamports. |
| 164 | 8  | `activation_epoch`      | `u64` LE      | Epoch en que se activa la delegación. |
| 172 | 8  | `deactivation_epoch`    | `u64` LE      | `u64::MAX` si sigue activa. |
| 180 | 8  | `credits_observed`      | `u64` LE      | Créditos del validador en el último cálculo de recompensas. |

Total: **200 bytes** (los offsets 188-199 son relleno de calentamiento/enfriamiento en diseños antiguos, a cero en el actual).

## Dónde lo encuentras

Paneles de validadores, flujos de liquid staking y cualquier llamada RPC que recorra delegaciones (`getStakeActivation`, `getProgramAccounts` sobre el programa Stake).

## Errores comunes

- **Autoridades en dos pasos.** `authorized_staker` y `authorized_withdrawer` pueden ser claves distintas — el almacenamiento en frío guarda el withdrawer mientras una clave caliente gestiona las delegaciones.
- **`deactivation_epoch = u64::MAX` significa «sigue activa».** Un valor finito significa que se ha solicitado la desactivación; el stake se enfría durante un epoch antes de que los fondos sean retirables.
- **El stake no gana recompensas de inmediato.** La activación tarda un epoch completo. Las recompensas aterrizan al inicio de cada epoch posterior.
