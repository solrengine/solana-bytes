---
name: Vote Account
summary: La identidad on-chain de un validador. Registra la autoridad de voto del nodo, la tasa de comisión y un historial rodante de votos y créditos por epoch.
---

## Qué es

Una cuenta Vote es la identidad on-chain de un validador. Registra la autoridad de voto del validador, su tasa de comisión y un historial rodante de 3,7 KB de votos recientes y créditos por epoch.

## Por qué existe

Cada validador de Solana tiene exactamente una cuenta Vote. Las [cuentas Stake](/learn/consensus/stake-account) apuntan a una cuenta Vote para delegar; el programa Vote registra los votos del validador (qué slots confirmó y cuándo), y la red usa ese registro para distribuir recompensas de staking proporcionales a la participación del validador.

## Diseño de bytes

Los primeros 109 bytes son decodificables a nivel de campo. Los ~3.653 bytes restantes son un búfer empaquetado de entradas `LandedVote` recientes.

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0   | 4    | `version`               | `u32` enum     | Versión del estado de voto (`0` v0, `1` v1_14_11, `2` actual). |
| 4   | 32   | `node_pubkey`           | `Pubkey`       | El par de claves de identidad del validador. |
| 36  | 32   | `authorized_withdrawer` | `Pubkey`       | Reclama recompensas. Normalmente en frío. |
| 68  | 1    | `commission`            | `u8`           | Porcentaje de comisión del validador (0–100). |
| 69  | 40   | `authorized_voters`     | mapa por epoch | Pubkey del votante autorizado activo por epoch. |
| 109 | 3653 | `vote_history`          | `LandedVote[]` | Búfer empaquetado; cada LandedVote ≈ 12 bytes (slot, recuento de confirmaciones, latencia). |

Total: **3.762 bytes**.

## Dónde lo encuentras

Flujos de staking (consultar la comisión de un validador antes de delegar), paneles de validadores, lógica del calendario de líderes. Llamadas RPC como `getVoteAccounts` devuelven una entrada por cuenta Vote.

## Errores comunes

- **El diseño on-chain es demasiado denso para anotarlo byte a byte en línea.** Para la struct `LandedVote` exacta, consulta la fuente de Agave enlazada arriba o recorre el búfer con `getProgramAccounts` sobre el programa Vote.
- **`authorized_voter` rota por epoch.** El diseño on-chain almacena un pequeño mapa de entradas `(epoch → pubkey)`, no una sola pubkey.
- **Los cambios de comisión no se aplican al instante.** Los programas Vote imponen límites de tiempo para evitar estafar a los delegadores a mitad de epoch.
