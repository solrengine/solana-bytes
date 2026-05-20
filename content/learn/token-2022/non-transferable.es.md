---
name: NonTransferable (extensión)
summary: Extensión del lado Mint de Token-2022 que hace que un token sea soulbound — puede emitirse y quemarse pero nunca transferirse. Su carga útil está vacía; la presencia de la extensión es toda la señal.
---

## Qué es

`NonTransferable` hace que un token sea soulbound: una vez que aterriza en una cuenta, nunca puede moverse a otra. Aún puede emitirse y quemarse, pero `Transfer` y `TransferChecked` siempre fallan. Es la primitiva canónica para credenciales, insignias de logros, recibos no negociables y tokens de prueba de asistencia.

## Por qué existe

Antes de Token-2022, los tokens «soulbound» se aplicaban fuera de la cadena (un backend que se negaba a construir transacciones de transferencia) o congelando cada cuenta — frágil y eludible. Hacer de la no transferibilidad una regla a nivel de Mint significa que el *propio programa* rechaza las transferencias, sin importar qué cliente construya la transacción.

## Diseño de bytes

Esta es la extensión más simple de Token-2022 — **no tiene carga útil**. Toda su huella on-chain es la cabecera TLV de 4 bytes con longitud cero:

| Offset | Tamaño | Campo | Tipo | Notas |
|-------:|-------:|-------|------|-------|
| 0 | 2 | `extension_type` | `u16` LE | `9` = NonTransferable. |
| 2 | 2 | `length`         | `u16` LE | `0` — no hay carga útil. |

Entrada total: **4 bytes** (solo cabecera), **0 bytes** de carga útil.

La extensión es un indicador puro: su *presencia* en la lista TLV de la mint es toda la señal. Un decodificador no lee ningún valor — solo anota que existe la extensión de tipo 9 y concluye que el token es soulbound.

## La contraparte del lado cuenta

Las Mints llevan `NonTransferable` (tipo 9). Las Token Accounts que tienen ese token reciben automáticamente una extensión emparejada `NonTransferableAccount` (tipo 13), *también* vacía. El programa la añade al inicializar la cuenta para que las herramientas a nivel de cuenta puedan detectar la condición soulbound sin resolver la mint.

## Dónde lo encuentras

Tokens de credencial e identidad, POAPs de hackathon, recibos de vesting bloqueados y tokens de recompensa de «no puedes vender esto». Siempre que un emisor quiera un token que demuestre algo sobre el titular pero que no deba convertirse en un activo negociable.

## Errores comunes

- **Una carga útil vacía sigue siendo una extensión real.** Los decodificadores que asumen que cada entrada TLV tiene datos recorrerán mal la lista si intentan leer una carga útil aquí. El `length = 0` es correcto y significativo — avanza exactamente 4 bytes.
- **La quema sigue permitida.** NonTransferable bloquea `Transfer`, no `Burn`. Los titulares siempre pueden destruir el token; solo no pueden moverlo.
- **Las cuentas de una mint NonTransferable también reciben `ImmutableOwner`.** Esto evita la elusión obvia — transferir la *propiedad de la cuenta* en lugar de los tokens. El programa lo añade automáticamente; verás ImmutableOwner (tipo 7) junto a NonTransferableAccount en estas cuentas.
- **Es de toda la mint y permanente.** No hay autoridad para desactivarlo. Un token nace soulbound o no lo es.
