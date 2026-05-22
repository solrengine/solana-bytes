---
name: Discriminador de Cuenta de Anchor
summary: El prefijo de 8 bytes que Anchor estampa en cada cuenta que posee, derivado del nombre de la struct de la cuenta. Es cómo un programa de Anchor distingue sus propios tipos de cuenta.
---

## Qué es

Cada cuenta creada por un programa de Anchor empieza con un **discriminador** de 8 bytes — una huella derivada del nombre de la struct de Rust de la cuenta. Cuando el programa carga una cuenta, comprueba primero estos 8 bytes para confirmar «sí, esto es un `UserStats`, no un `Vault`», antes de deserializar el resto.

## Por qué existe

Un solo programa a menudo posee muchos tipos de cuenta, todos propiedad del mismo id de programa. Sin una etiqueta de tipo, el programa no podría distinguir con seguridad un `Vault` de un `Config` — alguien podría pasar la cuenta equivocada y el programa deserializaría basura a ciegas. El discriminador convierte la confusión de tipos en un error limpio en lugar de una corrupción silenciosa.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 8 | `discriminator` | `[u8; 8]` | Primeros 8 bytes de `sha256("account:<NombreDeStruct>")`. |
| 8 | … | campos de la cuenta | Borsh | La struct serializada con Borsh sigue a continuación. |

El discriminador se calcula en tiempo de compilación como:

```text
discriminator = sha256("account:" + NombreDeStruct)[0..8]
```

Así que una struct llamada `UserStats` se prefija con los primeros 8 bytes de `sha256("account:UserStats")`. La cadena de espacio de nombres es literalmente `account:` — distinta del espacio `global:` usado para los [discriminadores de instrucción](/learn/anchor/instruction-discriminator).

## Dónde lo encuentras

Los primeros 8 bytes de cualquier cuenta propiedad de un programa de Anchor. Cuando haces un volcado hex de una cuenta de Anchor y los primeros 8 bytes parecen ruido aleatorio antes de que empiecen los campos reconocibles, ese es el discriminador.

## Errores comunes

- **Son 8 bytes del hash, no el hash completo.** Solo se usan los primeros 8 bytes del SHA-256. Las colisiones son astronómicamente improbables en el conjunto de cuentas de un programa.
- **El *nombre* de la struct es la entrada, no el diseño de campos.** Renombrar una struct cambia su discriminador y rompe cada cuenta existente de ese tipo — un peligro de migración. Renombrar un *campo* no.
- **El espacio de la cuenta debe incluir los 8 bytes.** Al asignar, reservas `8 + sizeof(campos)`. Olvidar los 8 es el error de espacio de Anchor más común — ver [init y espacio](/learn/anchor/anchor-init-and-space).
- **Las versiones recientes de Anchor permiten discriminadores personalizados**, pero el valor por defecto `sha256("account:Nombre")[0..8]` es lo que verás en la inmensa mayoría de las cuentas.
