---
name: Bumps Canónicos
summary: El bump es el único byte que empuja una PDA fuera de la curva ed25519. El bump canónico es el primero que se encuentra contando hacia atrás desde 255 — y usar cualquier otro es un fallo de seguridad.
---

## Qué es

Al derivar una [PDA](/learn/addressing/pda-derivation), aproximadamente la mitad de los hashes candidatos caen *sobre* la curva ed25519 (y por tanto son PDA inválidas). El **bump** es una semilla de un byte añadida para empujar el hash hasta que caiga fuera de la curva. El **bump canónico** es el primero válido encontrado contando hacia atrás desde 255.

## Por qué existe

Para cualquier conjunto de semillas suele haber varios valores de bump que producen una dirección válida fuera de la curva. Si un programa aceptara *cualquiera* de ellos, un atacante podría aportar un bump no canónico para derivar una PDA válida *distinta* para las mismas semillas lógicas — eludiendo una suposición de unicidad. Estandarizar el bump canónico (el más alto) hace que cada conjunto de semillas mapee exactamente a una dirección.

## Diseño de bytes

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| (última semilla) | 1 | `bump` | `u8` | Añadido tras las semillas del usuario, antes del id del programa, en la preimagen del hash de la PDA. |

`find_program_address` ejecuta:

```text
para bump en 255, 254, 253, … 0:
  candidato = create_program_address(seeds + [bump], program_id)
  si candidato está fuera de la curva: devolver (candidato, bump)   # canónico = primer acierto
```

El bump devuelto es el canónico. Los programas lo almacenan (a menudo en la propia cuenta) para no repetir la búsqueda en cada llamada.

## Dónde lo encuentras

Cada programa que usa PDA. El `#[account(seeds = …, bump)]` de Anchor encuentra e impone el bump canónico por ti; los programas en bruto llaman a `find_program_address` y luego pasan el bump a `invoke_signed`.

## Errores comunes

- **Valida siempre el bump canónico.** Si tu programa acepta un bump aportado por el invocador sin comprobar que es canónico, un atacante puede derivar una PDA válida alternativa. La restricción `bump` de Anchor (sin valor) re-deriva e impone el canónico; `bump = algun_bump_almacenado` confía en un valor que debiste validar al inicializar.
- **`find_program_address` es caro; `create_program_address` es barato.** Buscar el bump cuesta cómputo. Los programas lo encuentran una vez (al inicializar), almacenan el bump y a partir de ahí usan `create_program_address` con el bump almacenado.
- **El más alto primero, no el más bajo.** Canónico = el primer acierto fuera de la curva contando hacia *abajo* desde 255, así que los bumps canónicos suelen ser 255, 254, etc. Un bump de, digamos, 251 significa que 255–252 cayeron todos sobre la curva.
