---
name: MintCloseAuthority (extensión)
summary: Extensión del lado Mint de Token-2022 que nombra una autoridad autorizada a cerrar la mint y recuperar su rent — pero solo cuando el suministro es cero. Las mints de SPL Token nunca pudieron cerrarse.
---

## Qué es

`MintCloseAuthority` nombra una dirección autorizada a cerrar la propia cuenta mint y recuperar los lamports exentos de rent bloqueados en ella — siempre que el suministro de la mint sea cero. Es una pequeña extensión que arregla una molestia de larga data de SPL Token: una mint creada y luego abandonada bloqueaba su rent para siempre.

## Por qué existe

En SPL Token, una cuenta [Mint](/learn/spl-token/mint) nunca puede cerrarse. Cada mint de prueba, cada despliegue erróneo, cada token retirado dejaba ~0,0015 SOL de rent varado permanentemente. Token-2022 permite a una autoridad designada cerrar una mint totalmente quemada y recuperar ese rent, lo que importa a escala para emisores que crean y retiran muchas mints.

## Diseño de bytes

Esta es la carga útil de una entrada TLV MintCloseAuthority (`extension_type = 3`, `length = 32`). La entrada on-chain completa añade los 4 bytes de cabecera TLV (consulta el [primer de diseño TLV](/learn/token-2022/tlv-layout-primer)).

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 32 | `close_authority` | `OptionalNonZeroPubkey` | Puede cerrar la mint para recuperar el rent. Todo a cero = None — la mint nunca puede cerrarse (comportamiento de SPL Token). |

Carga útil total: **32 bytes**.

## Dónde lo encuentras

Emisores que crean y retiran mints de forma programática (entornos de prueba, tokens de campaña efímeros, lanzadores de tokens estilo fábrica). La mayoría de los tokens de larga vida lo dejan en None.

## Errores comunes

- **El suministro debe ser cero para cerrar.** El programa rechaza `CloseAccount` sobre una mint con cualquier suministro pendiente. Cada token debe quemarse primero; de lo contrario el cierre falla y el rent permanece bloqueado.
- **Cerrar la mint es permanente y libera la dirección.** Tras el cierre, la cuenta desaparece y su dirección podría en principio ser reutilizada por una cuenta nueva. No caches los metadatos de una mint cerrada como si la dirección fuera estable.
- **Es una autoridad separada de la de mint/congelación.** La autoridad de cierre puede ser una clave distinta de la autoridad de emisión o de congelación. No asumas que una clave tiene las tres.
- **None al crear es para siempre.** Como otras extensiones de mint, si la mint se lanzó sin autoridad de cierre nunca puede ganar una — el rent queda bloqueado para siempre, exactamente como en SPL Token.
