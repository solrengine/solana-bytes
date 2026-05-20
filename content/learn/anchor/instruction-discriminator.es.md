---
name: Discriminador de Instrucción de Anchor
summary: El prefijo de 8 bytes en los datos de cada instrucción de Anchor, derivado del nombre de la instrucción. Es cómo un programa de Anchor enruta las instrucciones entrantes al manejador correcto.
---

## Qué es

Cada instrucción enviada a un programa de Anchor empieza sus datos con un **discriminador** de 8 bytes derivado del nombre de la instrucción. El programa lee estos 8 bytes para decidir a qué manejador despachar, luego decodifica con Borsh los bytes restantes como argumentos de ese manejador.

## Por qué existe

Un programa expone muchas instrucciones (`initialize`, `deposit`, `withdraw`, …). Los programas nativos usan una etiqueta entera pequeña; Anchor usa un hash de 8 bytes derivado del nombre para que el despacho sea resistente a colisiones y nunca tengas que asignar números de instrucción a mano. El framework genera tanto el match on-chain como el codificador del lado cliente desde la misma fuente.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 8 | `discriminator` | `[u8; 8]` | Primeros 8 bytes de `sha256("global:<nombre_de_instrucción>")`. |
| 8 | … | argumentos | Borsh | Los argumentos de la instrucción serializados con Borsh siguen. |

El discriminador es:

```text
discriminator = sha256("global:" + nombre_de_instruccion_snake_case)[0..8]
```

Así que una instrucción `fn deposit(...)` tiene datos que empiezan con los primeros 8 bytes de `sha256("global:deposit")`. El espacio de nombres es `global:` — distinto del `account:` usado para los [discriminadores de cuenta](/learn/anchor/account-discriminator).

## Dónde lo encuentras

Los primeros 8 bytes del campo `data` en cualquier instrucción dirigida a un programa de Anchor. Cuando decodificas una [transacción](/learn/transactions/legacy-transaction) y los datos de una instrucción empiezan con 8 bytes opacos antes de argumentos reconocibles, esa es la etiqueta de despacho.

## Errores comunes

- **El nombre, en snake_case, es la entrada.** `fn initializeVault` se convierte en `global:initialize_vault`. Renombrar una instrucción cambia su discriminador y rompe cada cliente que codificó los bytes antiguos a mano.
- **8 bytes, luego argumentos Borsh.** Tras el discriminador, los argumentos son Borsh puro — un `u64` son 8 bytes little-endian, un `Option<T>` es una etiqueta de 1 byte, etc. (ver [Borsh frente a bincode](/learn/encoding/borsh-vs-bincode)).
- **Los eventos y el estado usan espacios de nombres distintos.** Los eventos de Anchor usan `event:`; el antiguo `#[state]` usaba otro. El caso común de instrucción es `global:`.
- **No es lo mismo que las etiquetas nativas de 1/4 bytes.** Las instrucciones de un programa de Anchor llevan etiqueta de 8 bytes; una instrucción de System o SPL Token en la misma transacción usa su propio esquema (de 4 o 1 byte). La codificación de despacho es por programa.
