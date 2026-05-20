---
name: Bytecode ELF
summary: El programa compilado en sí — un objeto compartido ELF estándar cuya cabecera de 64 bytes lo identifica como un binario eBPF little-endian, seguido de los segmentos de código y datos del programa.
---

## Qué es

El código real de un programa de Solana es un **ELF** (Executable and Linkable Format) estándar — el mismo contenedor que usa Linux — compilado al conjunto de instrucciones eBPF (SBF, la variante de Solana). Ya esté almacenado en una cuenta [ProgramData](/learn/programs/program-data) (actualizable) o directamente en la dirección del programa (loader heredado), los bytes empiezan con la cabecera ELF de 64 bytes.

## Por qué existe

En lugar de inventar un formato binario a medida, Solana reutiliza ELF — el herramental maduro (linkers, `readelf`, objdump) funciona de inmediato. Los validadores cargan el ELF, lo verifican y ejecutan (JIT o interpretado) sus instrucciones eBPF dentro de la SVM.

## Diseño de bytes

La cabecera ELF de 64 bytes (64 bits, little-endian) empieza cada binario de programa:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0  | 4 | `EI_MAG` | bytes | Magic: `7F 45 4C 46` (`\x7F` `E` `L` `F`). |
| 4  | 1 | `EI_CLASS` | `u8` | `2` = ELFCLASS64 (64 bits). |
| 5  | 1 | `EI_DATA` | `u8` | `1` = little-endian. |
| 6  | 1 | `EI_VERSION` | `u8` | `1`. |
| 7  | 9 | `EI_OSABI` + relleno | bytes | OS/ABI y luego relleno hasta el offset 16. |
| 16 | 2 | `e_type` | `u16` | `3` = ET_DYN (objeto compartido). |
| 18 | 2 | `e_machine` | `u16` | `247` = eBPF. |
| 20 | 4 | `e_version` | `u32` | `1`. |
| 24 | 8 | `e_entry` | `u64` | Dirección virtual del punto de entrada. |
| 32 | 8 | `e_phoff` | `u64` | Offset de la tabla de cabeceras de programa. |
| 40 | 8 | `e_shoff` | `u64` | Offset de la tabla de cabeceras de sección. |
| 48 | 4 | `e_flags` | `u32` | |
| 52 | 2 | `e_ehsize` | `u16` | Tamaño de la cabecera ELF (64). |
| 54 | 10 | `e_ph/sh entsize+num+shstrndx` | `u16`×5 | Tamaños/recuentos de cabeceras de programa/sección, índice de tabla de cadenas. |

Tras la cabecera vienen las cabeceras de programa, las secciones de código/datos y las reubicaciones — el programa compilado.

## Dónde lo encuentras

El contenido de una cuenta [ProgramData](/learn/programs/program-data) (salta su cabecera de ~45 bytes para llegar al ELF), o los datos de un programa desplegado con el loader heredado no actualizable. El magic `7F 45 4C 46` es la pista delatora en un volcado hex.

## Errores comunes

- **`e_machine = 247` es el marcador BPF.** Así confirmas que un blob hex es un ELF de programa de Solana y no algún otro binario ELF.
- **En los programas actualizables, el ELF está desplazado.** Una cuenta [ProgramData](/learn/programs/program-data) prefija el ELF con su propia cabecera de estado de ~45 bytes. El magic `7F454C46` aparece *después* de esa cabecera, no en el byte 0.
- **Es eBPF/SBF, no x86.** Desensamblar requiere una herramienta que entienda eBPF; un objdump x86 estándar no le encontrará sentido a las instrucciones.
- **Se verifica al cargar, no en cada llamada.** El runtime verifica el ELF (sin instrucciones ilegales, saltos válidos) cuando el programa se despliega/actualiza, luego lo cachea — las llamadas no lo reverifican.
