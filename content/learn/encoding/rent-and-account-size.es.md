---
name: Rent y Tamaño de Cuenta
summary: Por qué cada cuenta de Solana tiene un tamaño fijo en bytes establecido al crearse y un saldo mínimo de SOL para seguir viva. La exención de rent es un depósito proporcional al tamaño — reembolsable cuando la cuenta se cierra.
---

## Qué es

Cada cuenta de Solana reserva un número fijo de bytes (`data_length`) elegido al crearse, y debe mantener un saldo mínimo de SOL proporcional a ese tamaño para ser **exenta de rent**. Por debajo del umbral, una cuenta estaría sujeta al cobro de rent y acabaría purgada; en o por encima de él, la cuenta vive indefinidamente.

## Por qué existe

Los datos de las cuentas viven en la memoria de los validadores y hay que pagarlos. La exención de rent adelanta ese coste: depositas ~2 años de rent y la cuenta nunca se cobra. El depósito es reembolsable — cierra la cuenta y los lamports vuelven a quien designes.

## Diseño de bytes

El rent no es un campo dentro de la cuenta; es una relación entre dos valores de cabecera:

| Valor de cabecera | Tipo | Notas |
|-------------------|------|-------|
| `data_length` (alias `space`) | `u64` | Tamaño fijo en bytes de los datos de la cuenta, fijado al crearse. |
| `lamports` | `u64` | Saldo actual. Debe ser ≥ el mínimo exento de rent para este `data_length`. |

El mínimo exento de rent es aproximadamente:

```text
lamports_exentos_de_rent ≈ (128 + data_length) bytes
                            × lamports_por_byte_año
                            × 2 años
```

Los `128` son la sobrecarga fija de metadatos por cuenta. Como regla práctica sale a unos **0,00089 SOL para una cuenta de 0 bytes** más aproximadamente **0,00000696 SOL por byte adicional**, así que una [Mint](/learn/spl-token/mint) de 82 bytes necesita ~0,0014 SOL y una [Token Account](/learn/spl-token/token-account) de 165 bytes ~0,002 SOL.

## Dónde lo encuentras

Cada transacción de creación de cuenta financia la nueva cuenta hasta su mínimo exento de rent. `getMinimumBalanceForRentExemption(size)` devuelve la cifra exacta para una longitud de bytes dada.

## Errores comunes

- **El tamaño se fija al crearse.** No puedes hacer crecer una cuenta después sin `realloc` (que a su vez tiene tope por transacción y necesita más rent). Planifica el [espacio de cuenta](/learn/anchor/anchor-init-and-space) de antemano.
- **El rent es un depósito, no una comisión.** No se consume — se bloquea. Cerrar la cuenta reembolsa el saldo completo de lamports al destinatario que especifiques.
- **Infrafinanciar deja la cuenta cobrable.** Una cuenta por debajo del mínimo exento de rent puede ser recolectada por el garbage collector. Prácticamente toda cuenta se crea exenta de rent por esta razón.
- **La sobrecarga de 128 bytes es real.** Una cuenta de «0 bytes» igual cuesta rent por 128 bytes de metadatos. Las cuentas diminutas no son gratis.
- **Las mints de SPL Token no podían recuperar rent hasta Token-2022.** Una Mint de SPL cerrada varaba su rent para siempre; [MintCloseAuthority](/learn/token-2022/mint-close-authority) lo arregló para Token-2022.
