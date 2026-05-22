---
name: Derivación de PDA
summary: Cómo se calcula una Program Derived Address — SHA-256 sobre las semillas, un byte de bump, el id del programa y una cadena marcador, con el resultado forzado fuera de la curva ed25519 para que no pueda existir clave privada alguna para él.
---

## Qué es

Una Program Derived Address (PDA) es una dirección de cuenta que un programa controla sin poseer una clave privada. Se deriva de forma determinista de un conjunto de **semillas** más el id del programa, y se elige deliberadamente para caer *fuera* de la curva ed25519 — de modo que ningún par de claves podría firmar por ella. En su lugar, el programa propietario firma en su nombre vía `invoke_signed`.

## Por qué existe

Los programas necesitan cuentas que controlen por completo: una bóveda por usuario, un singleton de configuración, el estado de un mercado. Si esas usaran pares de claves normales, alguien tendría que poseer la clave privada. Las PDA permiten a un programa poseer y firmar por cuentas usando solo lógica on-chain — la base del modelo de cuentas de casi todos los programas de Solana.

## Diseño de bytes

`create_program_address` hashea una preimagen y comprueba que el resultado está fuera de la curva:

| Orden | Componente | Bytes | Notas |
|------:|------------|-------|-------|
| 1 | `seeds` | variable | Cada semilla concatenada, en orden (p. ej. `b"vault"`, una `Pubkey`, un `u64`). |
| 2 | `bump` | 1 | Un único byte añadido como última semilla (lo añade `find_program_address`). |
| 3 | `program_id` | 32 | La dirección del programa propietario. |
| 4 | `"ProgramDerivedAddress"` | 21 | Un marcador ASCII fijo que separa el dominio de las PDA de las claves reales. |

```text
hash = sha256(seed_0 || seed_1 || … || [bump] || program_id || "ProgramDerivedAddress")
si hash es un punto ed25519 válido: rechazar (probar un bump menor)
si no: hash es la PDA
```

Alrededor de la mitad de los hashes candidatos caen sobre la curva y se rechazan; `find_program_address` decrementa el bump hasta encontrar un resultado fuera de la curva (ver [bumps canónicos](/learn/addressing/canonical-bumps)).

## Dónde lo encuentras

Cada cuenta propiedad de un programa: bóvedas, escrows, singletons de configuración, libros de órdenes y las [Associated Token Accounts](/learn/addressing/associated-token-account). Siempre que veas una dirección derivada de `findProgramAddressSync(seeds, programId)`, es una PDA.

## Errores comunes

- **Cada semilla está limitada a 32 bytes, máximo 16 semillas.** Las semillas largas (como una cadena completa) deben hashearse o dividirse. El runtime impone estos límites.
- **El orden de las semillas es parte de la identidad.** `[user, mint]` y `[mint, user]` derivan PDA distintas. Documenta y fija tu orden de semillas.
- **Las PDA no tienen clave privada por construcción.** No puedes «firmar» con una PDA externamente — solo el programa propietario puede autorizar acciones vía `invoke_signed`, pasando las semillas + el bump.
- **El bump es parte de lo que se hashea.** Dos bumps distintos dan dos direcciones distintas a partir de las mismas semillas. Por eso importa la disciplina de bump canónico para la seguridad.
