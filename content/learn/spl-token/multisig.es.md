---
name: Multisig
summary: Una cuenta multifirma m-de-n que puede actuar como cualquier autoridad sobre una Mint o Token Account. Hasta 11 firmantes; se requieren m firmas para autorizar una acción.
---

## Qué es

Una Multisig de SPL Token es una cuenta de 355 bytes que puede sustituir a cualquier autoridad sobre una [Mint](/learn/spl-token/mint) o una [Token Account](/learn/spl-token/token-account) — autoridad de emisión, autoridad de congelación, propietario de la cuenta o delegado. Codifica una política m-de-n: de hasta 11 firmantes listados, cualquier `m` de ellos debe firmar para autorizar una acción.

## Por qué existe

Una sola clave controlando una mint o una tesorería es un único punto de fallo. SPL Token incorpora una multifirma nativa para que los emisores puedan exigir, por ejemplo, 3-de-5 aprobaciones para emitir nuevo suministro —sin desplegar un programa de multifirma aparte. La cuenta multisig simplemente ocupa el lugar de la pubkey de la autoridad.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 1 | `m` | `u8` | Número de firmantes requeridos (el umbral). |
| 1 | 1 | `n` | `u8` | Número total de firmantes válidos configurados. |
| 2 | 1 | `is_initialized` | `bool` | `1` una vez inicializada. |
| 3 | 352 | `signers` | `[Pubkey; 11]` | 11 espacios fijos de firmante de 32 bytes. Los espacios sin usar van a cero; solo los primeros `n` son válidos. |

Total: **355 bytes** (1 + 1 + 1 + 11 × 32).

## Dónde lo encuentras

Mints de tesorería (un emisor de stablecoin que exige varias aprobaciones para emitir), Token Accounts controladas por una DAO, y cualquier configuración en la que la autoridad deba compartirse. Cuando la `mint_authority` de una Mint apunta a una cuenta de 355 bytes propiedad del programa Token, esa autoridad es una multisig.

## Errores comunes

- **Siempre hay 11 espacios de firmante, sin importar `n`.** El diseño reserva espacio para 11 pubkeys incluso en una 2-de-3. Los espacios más allá de `n` van a cero — no trates un espacio a cero como un firmante real.
- **La multisig sustituye a la autoridad, no a la cuenta.** Una mint controlada por multisig sigue teniendo un campo `mint_authority` normal — solo que contiene la dirección de la cuenta multisig. La lógica «m-de-n» vive en la cuenta multisig, comprobada en el momento de la instrucción.
- **Los firmantes se aportan en el momento de la transacción.** Para actuar, `m` de las claves de firmante listadas deben firmar la transacción; el programa Token las verifica contra los espacios. La cuenta guarda *quién puede firmar*, no las firmas.
- **Es distinta de la multifirma basada en programa (Squads).** Esta es la primitiva integrada del programa Token, limitada a autoridades de token y 11 firmantes. Squads y similares ofrecen multifirma a nivel de programa más rica para instrucciones arbitrarias.
