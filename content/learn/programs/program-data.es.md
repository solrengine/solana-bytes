---
name: Cuenta ProgramData
summary: La cuenta que realmente contiene el bytecode ELF de un programa actualizable, más el slot en que se desplegó por última vez y la autoridad de actualización. Referenciada por la pequeña cuenta Program en la dirección pública del programa.
---

## Qué es

La cuenta ProgramData es donde vive el código real de un programa actualizable. La cuenta [Program](/learn/programs/bpf-upgradeable-program) en la dirección pública es un puntero de 36 bytes; apunta aquí, a una cuenta mucho mayor que contiene una cabecera de estado de ~45 bytes seguida del bytecode [ELF](/learn/programs/elf-bytecode) del programa.

## Por qué existe

Separar «la dirección que invocas» (cuenta Program) de «el código y quién puede cambiarlo» (ProgramData) es lo que permite las actualizaciones sin cambiar la dirección pública del programa. ProgramData lleva la autoridad de actualización y el slot de despliegue, y se reescribe en cada actualización.

## Diseño de bytes

La cuenta contiene la variante `ProgramData` de `UpgradeableLoaderState` (bincode), luego el ELF en bruto:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 4  | `state_discriminator` | `u32` LE | `3` = ProgramData. |
| 4  | 8  | `slot` | `u64` LE | El slot en que el programa se desplegó o actualizó por última vez. |
| 12 | 1  | etiqueta `upgrade_authority` | `u8` (Option de Borsh) | `0` None (inmutable — congelado para siempre), `1` Some. |
| 13 | 32 | `upgrade_authority` | `Pubkey` | Presente cuando la etiqueta es `1`. Puede autorizar actualizaciones. |
| 45 | …  | `elf` | bytes | El objeto compartido [ELF](/learn/programs/elf-bytecode). El magic `7F 45 4C 46` empieza aquí. |

La cabecera son **45 bytes** (4 + 8 + 1 + 32) cuando hay una autoridad de actualización fijada; el ELF sigue inmediatamente.

## Dónde lo encuentras

Detrás de cada programa actualizable. Toma la dirección de un programa, lee el `programdata_address` de su cuenta [Program](/learn/programs/bpf-upgradeable-program), obtén esa cuenta — esto es lo que consigues. Suele ser la cuenta más grande asociada a un programa.

## Errores comunes

- **El ELF empieza en el offset 45, no en el 0.** Las herramientas que buscan el magic `7F454C46` deben saltar la cabecera de estado. Leer el byte 0 como magic ELF falla — el byte 0 es el discriminador `03`.
- **`upgrade_authority = None` significa inmutable.** Poner la autoridad en None (una acción de un solo sentido) hace el programa permanentemente no actualizable — una señal de confianza común de que «este código nunca puede cambiar».
- **`slot` es el slot de la última actualización, no el de creación.** Se actualiza en cada redespliegue. Útil para «¿cuándo cambió por última vez este programa?».
- **La cuenta se dimensiona para el ELF más grande jamás desplegado.** Actualizar a un programa más pequeño no encoge la cuenta; el espacio extra sigue asignado (y con rent pagado).
