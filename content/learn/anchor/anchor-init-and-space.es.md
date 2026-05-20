---
name: init y Espacio de Cuenta en Anchor
summary: Cómo el #[account(init)] de Anchor dimensiona una cuenta nueva — 8 bytes de discriminador más el tamaño serializado de los campos — y por qué acertar con el recuento de bytes es lo que hace que la cuenta sea exenta de rent.
---

## Qué es

Cuando una cuenta de Anchor se crea con `#[account(init, payer = …, space = N)]`, `N` es el tamaño exacto en bytes a asignar. Ese tamaño debe ser igual a 8 (el [discriminador](/learn/anchor/account-discriminator)) más el tamaño serializado con Borsh de cada campo. Acierta y la cuenta es exenta de rent y está bien dimensionada; falla y o desperdicias rent o no caben los datos.

## Por qué existe

Las cuentas de Solana tienen un tamaño fijo establecido al crearse, y prepagas el rent para que ese tamaño sea exento de rent. Anchor no conoce automáticamente el tamaño serializado de tu struct en versiones antiguas, así que lo declaras. La aritmética de bytes es el puente entre tus tipos de Rust y la asignación on-chain.

## Diseño de bytes

El presupuesto de espacio es una suma de tamaños en bytes:

| Componente | Bytes | Notas |
|------------|------:|-------|
| discriminador | 8 | Siempre — cada cuenta de Anchor empieza con él. |
| `bool` | 1 | |
| `u8` / `i8` | 1 | |
| `u16` / `i16` | 2 | |
| `u32` / `i32` | 4 | |
| `u64` / `i64` | 8 | |
| `Pubkey` | 32 | |
| `Option<T>` | 1 + sizeof(T) | Etiqueta Borsh de 1 byte + el valor interno cuando está presente. |
| `Vec<T>` | 4 + len × sizeof(T) | Prefijo de longitud de 4 bytes; debes presupuestar la longitud máxima. |
| `String` | 4 + max_byte_len | Prefijo de longitud de 4 bytes + bytes UTF-8; presupuesta el máximo. |

Así que una struct `{ owner: Pubkey, amount: u64, label: String(≤16) }` necesita `8 + 32 + 8 + (4 + 16) = 68` bytes.

## Dónde lo encuentras

Cada restricción `init` en un programa de Anchor, y el cálculo de rent tras cada transacción de creación de cuenta. El tamaño asignado aparece como el `space`/longitud de datos de la cuenta on-chain.

## Errores comunes

- **Suma siempre 8.** El discriminador es parte de la cuenta; olvidarlo infraasigna exactamente 8 bytes y tu último campo se trunca. El error de espacio de Anchor más común.
- **`Vec` y `String` necesitan un presupuesto máximo.** Son de longitud variable pero la cuenta es de tamaño fijo — debes reservar espacio para el valor más grande que vayas a almacenar, más el prefijo de longitud de 4 bytes.
- **`Option<T>` es 1 + T, no T.** El byte de etiqueta de Borsh siempre está presente, incluso cuando el valor es None. No lo dimensiones como solo `sizeof(T)`.
- **Sobreasignar desperdicia rent; infraasignar inutiliza las escrituras.** El tamaño se fija al crear (salvo realloc). Calcúlalo con exactitud. Anchor reciente ofrece el derive `InitSpace` para calcularlo por ti — prefiérelo a contar a mano.
