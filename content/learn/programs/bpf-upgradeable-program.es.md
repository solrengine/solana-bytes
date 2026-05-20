---
name: Programa BPF Actualizable
summary: Un puntero fino de 36 bytes desde la dirección pública de un programa a su cuenta ProgramData, que contiene el bytecode ELF real. La indirección es lo que permite actualizar un programa manteniendo su dirección.
---

## Qué es

Cuando invocas un programa en una dirección como la de Jupiter `JUP6Lkb…`, esa cuenta es diminuta — solo 36 bytes. No contiene el bytecode; es un estado `Program` que apunta a una cuenta [ProgramData](/learn/programs/program-data) separada que contiene el ELF real. Esta indirección es lo que hace posibles las actualizaciones.

## Por qué existe

Si el bytecode de un programa viviera directamente en su dirección pública, actualizar cambiaría la dirección y rompería cada integración. El BPF Upgradeable Loader lo divide: una cuenta `Program` pequeña y estable en la dirección pública, y una cuenta `ProgramData` separada que puede reescribirse al actualizar. La dirección que invocas nunca cambia; el código tras ella sí.

## Diseño de bytes

La cuenta contiene la variante `Program` de `UpgradeableLoaderState`, codificada con bincode:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 4 | `state_discriminator` | `u32` LE | `2` = Program (la variante del enum: `0` Uninitialized, `1` Buffer, `2` Program, `3` ProgramData). |
| 4 | 32 | `programdata_address` | `Pubkey` | Dirección de la cuenta [ProgramData](/learn/programs/program-data) que contiene el ELF + la autoridad de actualización. |

Total: **36 bytes**.

## Dónde lo encuentras

La dirección principal de cada programa actualizable: Jupiter, Drift, Kamino, programas de Anchor desplegados normalmente. Cuando consultas una cuenta de programa y mide exactamente 36 bytes propiedad del BPF Upgradeable Loader, es esto — sigue `programdata_address` para encontrar el código.

## Errores comunes

- **La cuenta del programa no contiene código.** Decodificarla te da un puntero, no bytecode. Los kilobytes de ELF que podrías esperar viven en la cuenta [ProgramData](/learn/programs/program-data) que referencia.
- **Discriminador bincode de 4 bytes.** Como otros estados del loader nativo, la etiqueta de variante es un `u32` de 4 bytes, no de 1 byte.
- **Los programas no actualizables tienen otro aspecto.** Los programas desplegados con el antiguo BPF Loader no actualizable (`BPFLoader2…`) almacenan el [ELF](/learn/programs/elf-bytecode) directamente en la dirección del programa — sin indirección ProgramData. El programa propietario te dice qué loader es.
- **Cerrar/actualizar lo controla la autoridad de ProgramData**, no nada de esta cuenta de 36 bytes. La autoridad de actualización vive en ProgramData.
