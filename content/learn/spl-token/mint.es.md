---
name: Mint
summary: Describe un token — su autoridad, suministro total, decimales y autoridad de congelación opcional. USDC, USDT y wrapped SOL tienen todos cuentas Mint.
---

## Qué es

Una cuenta Mint de SPL define un token fungible en Solana — su autoridad, su suministro total, sus decimales y una autoridad de congelación opcional. USDC, USDT y wrapped SOL están todos definidos por cuentas Mint.

## Por qué existe

Solana no incluye una primitiva de token integrada. El programa SPL Token trata cada token fungible de la misma forma: cada token tiene exactamente una cuenta Mint que guarda los metadatos canónicos, y muchas Token Accounts que guardan los saldos individuales. Esta separación es lo que permite que el mismo token viva en millones de billeteras sin volver a almacenar los metadatos cada vez.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 36 | `mint_authority` | `COption<Pubkey>` | Etiqueta de 4 bytes (`0` = None, `1` = Some) + pubkey de 32 bytes. Si es None, la emisión queda bloqueada para siempre. |
| 36 | 8 | `supply` | `u64` LE | Total de unidades atómicas en circulación. Divide por `10^decimals` para el importe legible. |
| 44 | 1 | `decimals` | `u8` | Exponente — p. ej. el `6` de USDC significa que 1 USDC = 10⁶ unidades atómicas. |
| 45 | 1 | `is_initialized` | `bool` | `1` una vez inicializada; una Mint sin inicializar es inutilizable. |
| 46 | 36 | `freeze_authority` | `COption<Pubkey>` | Etiqueta de 4 bytes + pubkey de 32 bytes. Si es Some, puede congelar cualquier Token Account de esta mint. |

Total: **82 bytes**.

## Dónde lo encuentras

Te topas con una Mint cada vez que lees el campo `mint` de una Token Account, llamas a `getMint` por RPC, o consultas un activo en Jupiter, en la interfaz de una billetera o en un explorador.

## Errores comunes

- **La etiqueta COption ocupa 4 bytes, no 1.** SPL Token usa una etiqueta de 4 bytes delante de cada pubkey opcional para preservar la alineación de la estructura en `Pack` (`36 = 4 + 32`). Esto es distinto del `Option` de Borsh, que usa una etiqueta de 1 byte. Token-2022 sigue la misma convención de SPL.
- **`decimals` es un exponente, no un número de dígitos.** Un `decimals` de `9` significa que los importes se dividen por 10⁹, no que «se muestran 9 dígitos».
- **`mint_authority: None` es permanente.** Una vez que se elimina una autoridad (SetAuthority → None), nada puede volver a habilitar la emisión. Muchos tokens bloquean la emisión tras la distribución inicial para generar confianza.
