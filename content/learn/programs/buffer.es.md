---
name: Cuenta Buffer
summary: Una cuenta de preparación temporal que contiene el ELF de un programa durante el despliegue o antes de una actualización. Una vez escrita y verificada, su contenido se copia en la cuenta ProgramData y el buffer se cierra.
---

## Qué es

Una cuenta Buffer es espacio de borrador para desplegar o actualizar un programa. Los bytes del ELF se escriben en un buffer a lo largo de muchas transacciones (un programa es mucho mayor de lo que una transacción puede llevar), y solo cuando el ELF completo está preparado y verificado una única instrucción Deploy o Upgrade lo copia en la cuenta [ProgramData](/learn/programs/program-data).

## Por qué existe

El ELF de un programa de Solana suele pesar cientos de kilobytes — no cabe en el límite de 1.232 bytes de una transacción. Los buffers te permiten subir el código en trozos (instrucciones `Write`) a una cuenta de preparación, y luego promoverlo de forma atómica. También habilita flujos de gobernanza: prepara una actualización en un buffer, luego haz que una multifirma o DAO autorice el cambio final.

## Diseño de bytes

La cuenta contiene la variante `Buffer` de `UpgradeableLoaderState` (bincode), luego el ELF parcial o completo:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 4  | `state_discriminator` | `u32` LE | `1` = Buffer. |
| 4  | 1  | etiqueta `authority` | `u8` (Option de Borsh) | `0` None, `1` Some. |
| 5  | 32 | `authority` | `Pubkey` | Presente cuando la etiqueta es `1`. Puede escribir en el buffer y desplegar desde él. |
| 37 | …  | `elf` | bytes | El [ELF](/learn/programs/elf-bytecode) (posiblemente parcial) en preparación. |

La cabecera son **37 bytes** (4 + 1 + 32) cuando hay una autoridad fijada; el ELF preparado sigue.

## Dónde lo encuentras

Durante `solana program deploy` y `solana program write-buffer`. Los buffers son transitorios — existen entre el primer `Write` y el `Deploy`/`Upgrade` final, luego se cierran para recuperar el rent. Ocasionalmente encontrarás buffers abandonados de despliegues fallidos que aún retienen rent.

## Errores comunes

- **El ELF empieza en el offset 37 aquí, en el 45 en ProgramData.** Las dos variantes de estado tienen tamaños de cabecera distintos (Buffer no tiene campo `slot`). No reutilices el offset de ProgramData para parsear un Buffer.
- **Los buffers abandonados varan rent.** Un despliegue que falla a mitad deja un buffer financiado. `solana program close --buffers` los recupera; comprueba si hay buffers huérfanos si desaparece SOL durante los despliegues.
- **La autoridad del buffer controla el despliegue.** Solo la `authority` del buffer puede finalizar un despliegue/actualización desde él — relevante para flujos de actualización controlados por multifirma donde el buffer lo prepara una parte y lo promueve otra.
- **Discriminador `1`, no `3`.** Buffer es la variante 1; ProgramData es la 3. La etiqueta de 4 bytes en el offset 0 te dice cuál estás mirando.
