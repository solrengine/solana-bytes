---
name: Instrucciones del Vote Program
summary: Diseños de datos de instrucción del Vote Program — InitializeAccount, Authorize, Vote, Withdraw, UpdateCommission. Un discriminador enum de 4 bytes seguido de campos bincode. Mayormente internas del validador.
---

## Qué es

El Vote Program gestiona la [cuenta Vote](/learn/consensus/vote-account) de un validador: crearla, rotar sus autoridades, registrar votos, actualizar la comisión y retirar las recompensas ganadas. La mayoría de estas se ejecutan automáticamente desde el cliente del validador; algunas (comisión, retiro, autorización) son acciones del operador.

## Por qué existe

Los validadores votan sobre qué bloques son válidos, y ese registro de votos impulsa la distribución de recompensas. El Vote Program es cómo esos votos quedan registrados on-chain y cómo los operadores gestionan la cuenta que representa a su validador.

## Diseño de bytes

Los datos de instrucción del Vote se codifican con **bincode**: un discriminador `u32` little-endian de 4 bytes, luego los campos. Variantes destacadas:

| Discriminador (u32 LE) | Variante | Carga útil | Notas |
|----:|----------|-----------|-------|
| `0` | `InitializeAccount` | `VoteInit{node_pubkey, authorized_voter, authorized_withdrawer, commission: u8}` | Crea la cuenta vote. |
| `1` | `Authorize`         | `pubkey: Pubkey`, `VoteAuthorize: u32` | Rota la autoridad de votante o de retiro. |
| `3` | `Withdraw`          | `lamports: u64` | Retira recompensas (solo el withdrawer). |
| `5` | `UpdateCommission`  | `commission: u8` | Cambia el porcentaje de comisión del validador. |

Las propias transacciones de voto (las de alta frecuencia que el validador envía en cada slot) llevan actualizaciones compactas del estado de voto; las de comisión y retiro son las orientadas al operador que decodificarás en los paneles.

## Dónde lo encuentras

Operaciones de validadores y paneles de staking. `UpdateCommission` y `Withdraw` son las instrucciones que importan a los delegadores — una subida de comisión afecta directamente a sus recompensas.

## Errores comunes

- **La mayor parte del tráfico de voto está automatizado.** El cliente del validador envía actualizaciones del estado de voto continuamente; rara vez las construyes a mano. Las instrucciones del operador (comisión, retiro, autorización) son las que aparecen en transacciones construidas por humanos.
- **Los cambios de comisión están restringidos en el tiempo.** El runtime limita cuándo puede cambiar la comisión dentro de un epoch para evitar que los validadores estafen a los delegadores justo antes de las recompensas. Un `UpdateCommission` puede rechazarse por temporización.
- **Withdraw requiere la autoridad withdrawer.** Las recompensas solo puede sacarlas el `authorized_withdrawer` — normalmente una clave en frío separada de la clave de voto.
- **Discriminador de 4 bytes (bincode), como System y Stake.**
