---
name: DefaultAccountState (extensión)
summary: Extensión del lado Mint de Token-2022 que fija el estado en que arrancan las Token Accounts nuevas. Ponerlo en Frozen convierte el token en una lista de permitidos — las cuentas deben descongelarse antes de poder operar.
---

## Qué es

`DefaultAccountState` controla en qué estado arranca una Token Account recién creada. Normalmente las cuentas se abren `Initialized` y pueden operar de inmediato. Pon esta extensión en `Frozen` y cada cuenta nueva se abre congelada — no puede enviar ni recibir hasta que la autoridad de congelación de la mint la descongele explícitamente. Eso convierte el token en una lista de permitidos.

## Por qué existe

Los tokens con permisos (stablecoins con KYC, valores regulados, comunidades cerradas) necesitan verificar a los titulares antes de dejarlos operar. Sin esta extensión tendrías que ganarle la carrera con una instrucción de congelación a la primera transferencia del usuario. DefaultAccountState convierte el «denegar por defecto» en la verdad de base: nadie puede mover el token hasta que el emisor apruebe su cuenta.

## Diseño de bytes

Esta es la carga útil de una entrada TLV DefaultAccountState (`extension_type = 6`, `length = 1`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `state` | `u8` enum | El `AccountState` que heredan las cuentas nuevas: `0` Uninitialized, `1` Initialized, `2` Frozen. En la práctica es `1` (normal) o `2` (lista de permitidos). |

Carga útil total: **1 byte**.

## Dónde lo encuentras

Stablecoins con KYC/AML, valores tokenizados y pools DeFi con permisos. Cualquier token cuyo emisor deba aprobar a un titular antes de que pueda usarlo. El mismo valor del enum `AccountState` aparece también en el campo `state` de la [TokenAccount](/learn/spl-token/token-account) base — esta extensión solo fija el valor por defecto que copian las cuentas nuevas.

## Errores comunes

- **Cambiar el valor por defecto no vuelve a congelar las cuentas existentes.** Actualizar `DefaultAccountState` solo afecta a las cuentas creadas *después* del cambio. Las cuentas ya descongeladas siguen descongeladas; el emisor debe congelarlas individualmente si hace falta.
- **Requiere una autoridad de congelación en la mint.** «Congelado por defecto» es inútil si no hay autoridad de congelación que descongele cuentas. Las dos van juntas — una mint con estado congelado por defecto y sin autoridad de congelación inutiliza cada cuenta nueva de forma permanente.
- **Es un byte, pero controla toda la UX del token.** Una billetera que no comprueba esta extensión dejará al usuario abrir una cuenta, intentar una transferencia y toparse con un opaco fallo de «account frozen». Las herramientas de grado de referencia muestran «este token requiere aprobación» de antemano.
