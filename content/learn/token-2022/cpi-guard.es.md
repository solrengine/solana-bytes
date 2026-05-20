---
name: CpiGuard (extensión)
summary: Extensión del lado cuenta de Token-2022 que, cuando se habilita, bloquea ciertas acciones de token dentro de una CPI — protegiendo a los usuarios de programas maliciosos que intentan redirigir aprobaciones o cerrar cuentas a mitad de la llamada.
---

## Qué es

CpiGuard es una opción del lado cuenta que, cuando se habilita, impide que ciertas operaciones de token se realicen mediante invocación entre programas (CPI). Con el guard activado, un programa con el que el usuario interactúa no puede aprobar silenciosamente un delegado, cambiar el propietario/autoridad de cierre de la cuenta, ni cerrar la cuenta hacia un destino elegido por el atacante — esas acciones deben venir directamente del usuario, no desde dentro de la llamada de otro programa.

## Por qué existe

Un usuario que firma una transacción para «usar» alguna dapp autoriza implícitamente cualquier CPI que esa dapp haga. Un programa malicioso o comprometido podría abusar de eso para, por ejemplo, ponerse como delegado y vaciar la cuenta más tarde. CpiGuard permite a los usuarios cautelosos (o a las billeteras) bloquear las operaciones peligrosas a llamadas directas, no por CPI.

## Diseño de bytes

Esta es la carga útil de una entrada TLV CpiGuard (`extension_type = 11`, `length = 1`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `lock_cpi` | `bool` (`u8`) | `1` = guard de CPI activo para esta cuenta; `0` = inactivo. |

Carga útil total: **1 byte**.

## Qué bloquea cuando está activo

Con `lock_cpi = 1`, lo siguiente se rechaza si se intenta dentro de una CPI: `Approve` (fijar un delegado), `SetAuthority` para las autoridades de cierre/propietario, `CloseAccount` hacia un destino arbitrario, y usar un delegado fijado vía CPI. El usuario debe realizar estas acciones directamente.

## Dónde lo encuentras

Cuentas gestionadas por billeteras que optan por seguridad extra, y usuarios avanzados cautelosos. Es a nivel de cuenta (lo fija el propietario), no a nivel de mint — el emisor del token no lo impone.

## Errores comunes

- **Es del lado cuenta, no del lado mint.** El propietario de la cuenta lo habilita en su propia [token account](/learn/spl-token/token-account); no tiene nada que ver con la política de la mint. Contrasta con extensiones de mint como [PermanentDelegate](/learn/token-2022/permanent-delegate).
- **Un solo byte, pero cambia la semántica de las llamadas.** Un programa que integra Token-2022 debe manejar el caso en que una cuenta protegida rechaza una aprobación/cierre dentro de una CPI — muestra un error claro en lugar de un fallo genérico.
- **No bloquea las acciones directas.** El usuario aún puede aprobar delegados y cerrar la cuenta él mismo; solo se controla la vía de CPI.
