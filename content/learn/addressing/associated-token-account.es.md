---
name: Derivación de Associated Token Account (ATA)
summary: La PDA determinista que guarda el saldo de un token dado para una billetera dada. Derivada de [billetera, token_program, mint] bajo el programa ATA, así que cualquier herramienta puede calcularla sin consulta on-chain.
---

## Qué es

Una Associated Token Account (ATA) es la [Token Account](/learn/spl-token/token-account) canónica para un par (billetera, mint) dado. Su dirección es una [PDA](/learn/addressing/pda-derivation) derivada de forma determinista, así que cualquiera puede calcular «¿dónde guarda la billetera X el token Y?» sin consultar la cadena.

## Por qué existe

Una billetera podría guardar un token en cualquier número de token accounts en direcciones arbitrarias — una pesadilla de descubrimiento. El estándar ATA dice: para cada (billetera, mint), hay *una* dirección bien conocida. Los emisores pueden calcular la ATA del destinatario, crearla si falta y depositar — sin coordinación necesaria.

## Diseño de bytes

La ATA es `find_program_address` de estas semillas bajo el programa ATA (`ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`):

| Orden | Semilla | Bytes | Notas |
|------:|---------|------:|-------|
| 1 | `wallet` | 32 | La pubkey de billetera del propietario. |
| 2 | `token_program_id` | 32 | `TokenkegQ…` para SPL Token, o el id del programa Token-2022. |
| 3 | `mint` | 32 | La mint del token. |

```text
ata = find_program_address(
  [wallet, token_program_id, mint],
  ATA_PROGRAM_ID
)
```

La dirección derivada es una Token Account normal de 165 bytes; solo su *dirección* es especial (determinista), no su diseño.

## Dónde lo encuentras

Cada saldo de billetera, cada flujo de «enviar token», cada ruta de DEX. Cuando una transferencia falla con «account does not exist», normalmente significa que la ATA del destinatario no se ha creado — el emisor debe incluir antes una instrucción de crear-ATA.

## Errores comunes

- **El id del programa de token es una semilla.** Una ATA de SPL Token y una ATA de Token-2022 para la misma billetera+mint derivan a direcciones *distintas*, porque el id del programa de token es parte de las semillas. Usa el id de programa correcto para la mint.
- **Es una PDA, así que no tiene clave privada.** La billetera *posee* la ATA (vía el campo `owner` de la Token Account), pero la dirección en sí es derivada del programa — autorizas las transferencias firmando como la billetera, no como la ATA.
- **Crear-si-falta es idempotente con la instrucción correcta.** `createAssociatedTokenAccountIdempotent` no falla si la ATA ya existe — prefiérela para evitar carreras donde dos emisores intentan crearla a la vez.
- **Las semillas usan la billetera, no las otras ATA de la billetera.** La derivación siempre parte de la pubkey de la *billetera*, nunca encadenada desde otra token account.
