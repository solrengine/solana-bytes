---
name: Instrucciones del Stake Program
summary: Diseños de datos de instrucción del Stake Program — Initialize, DelegateStake, Deactivate, Split, Merge, Withdraw, Authorize. Un discriminador enum de 4 bytes seguido de campos bincode.
---

## Qué es

El Stake Program gestiona el ciclo de vida de una [cuenta Stake](/learn/consensus/stake-account): inicializarla, delegar a un validador, desactivar, dividir, fusionar y retirar. Estas instrucciones son cómo los titulares de SOL y los protocolos de liquid staking operan el stake.

## Por qué existe

El staking no es una sola acción — es una máquina de estados a lo largo de epochs. Inicializas una cuenta de stake, la delegas (la activación tarda un epoch), opcionalmente divides o fusionas, desactivas (el enfriamiento tarda un epoch), luego retiras. Cada transición es una instrucción del Stake.

## Diseño de bytes

Los datos de instrucción del Stake se codifican con **bincode**: un discriminador `u32` little-endian de 4 bytes, luego los campos de la variante. Variantes clave:

| Discriminador (u32 LE) | Variante | Carga útil | Notas |
|----:|----------|-----------|-------|
| `0` | `Initialize`     | `Authorized{staker, withdrawer}`, `Lockup{ts, epoch, custodian}` | Fija autoridades + lockup. |
| `1` | `Authorize`      | `new_authority: Pubkey`, `StakeAuthorize: u32` | Rota staker o withdrawer. |
| `2` | `DelegateStake`  | (ninguna) | Las cuentas llevan la cuenta vote a la que delegar. |
| `3` | `Split`          | `lamports: u64` | Mueve parte del stake a una cuenta nueva. |
| `4` | `Withdraw`       | `lamports: u64` | Retira fondos desbloqueados y desactivados. |
| `5` | `Deactivate`     | (ninguna) | Inicia el enfriamiento. |
| `7` | `Merge`          | (ninguna) | Fusiona dos cuentas de stake compatibles. |

`DelegateStake` y `Deactivate` no llevan datos — el validador objetivo y la cuenta de stake se pasan como *cuentas*, no como campos de la instrucción.

## Dónde lo encuentras

Flujos de delegación de validadores, protocolos de liquid staking (Marinade, Jito) gestionando pools de stake, y cualquier botón de «hacer staking de SOL» de una billetera.

## Errores comunes

- **La activación y la desactivación tardan un epoch completo cada una.** `DelegateStake` no gana recompensas hasta el siguiente límite de epoch; los fondos de `Deactivate` no son retirables hasta que se completa el enfriamiento. La instrucción aterriza al instante; el *efecto* está controlado por epoch.
- **Las autoridades se referencian de dos formas.** `Initialize` las fija como datos de instrucción; `Authorize` rota una de ellas. No confundas el staker (gestiona la delegación) con el withdrawer (mueve fondos).
- **Split crea una cuenta nueva.** `Split` necesita una cuenta de stake destino prefinanciada y exenta de rent — el campo lamports es lo que se mueve *dentro* de ella, separado del rent.
- **Discriminador de 4 bytes (bincode), como System y Vote** — no la convención de 1 byte de SPL.
