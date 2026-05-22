---
name: Transacción Heredada
summary: El formato de transacción original de Solana — un array de firmas seguido de un mensaje (cabecera, claves de cuenta, blockhash reciente, instrucciones). Byte a byte, cada array prefijado con compact-u16.
---

## Qué es

Una transacción heredada es el formato original de Solana: un vector de firmas seguido de un *mensaje* que nombra las cuentas implicadas, ancla un blockhash reciente y lista las instrucciones a ejecutar. Es «heredada» solo en contraste con las [transacciones v0](/learn/transactions/v0-transaction) (que añaden búsquedas en tablas de direcciones) — el cuerpo del mensaje es por lo demás idéntico, y las transacciones heredadas siguen siendo válidas y comunes.

## Por qué existe

Cada cambio de estado en Solana llega como una transacción. Entender su diseño de bytes es lo que te permite decodificar un blob de transacción en bruto, depurar una instrucción malformada o construir una a mano. El formato es deliberadamente compacto: cada array variable se prefija con [compact-u16](/learn/transactions/compact-u16) en lugar de un recuento de ancho fijo.

## Diseño de bytes

Una transacción tiene dos partes de nivel superior — `signatures` y luego `message`:

| Sección | Campo | Tipo | Notas |
|---------|-------|------|-------|
| signatures | recuento | `compact-u16` | Número de firmas. |
| signatures | `signature[]` | 64 bytes c/u | Firmas Ed25519 sobre los bytes del mensaje, en el mismo orden que las claves de firmante requeridas. |
| message | `num_required_signatures` | 1 byte | Cuántas claves de cuenta iniciales deben firmar. |
| message | `num_readonly_signed_accounts` | 1 byte | De los firmantes, cuántos son de solo lectura. |
| message | `num_readonly_unsigned_accounts` | 1 byte | De los no firmantes, cuántos son de solo lectura. |
| message | recuento de claves | `compact-u16` | Número de claves de cuenta. |
| message | `account_keys[]` | 32 bytes c/u | Todas las pubkeys que toca esta transacción, ordenadas: firmantes-escribibles, firmantes-solo-lectura, no-firmantes-escribibles, no-firmantes-solo-lectura. |
| message | `recent_blockhash` | 32 bytes | Un blockhash reciente; la transacción se rechaza si es demasiado antiguo. |
| message | recuento de instrucciones | `compact-u16` | Número de instrucciones. |
| message | `instructions[]` | (ver abajo) | Cada instrucción, ejecutada en orden. |

Cada **instrucción** es:

| Campo | Tipo | Notas |
|-------|------|-------|
| `program_id_index` | 1 byte | Índice en `account_keys` del programa a invocar. |
| recuento de cuentas | `compact-u16` | Número de índices de cuenta. |
| `accounts[]` | 1 byte c/u | Índices en `account_keys` de las cuentas de esta instrucción. |
| longitud de datos | `compact-u16` | Longitud en bytes de los datos de la instrucción. |
| `data[]` | N bytes | Carga útil opaca de la instrucción (el programa la decodifica). |

## La cabecera de 3 bytes es la lista de acceso

`num_required_signatures` + los dos recuentos `num_readonly_*`, combinados con el orden estricto de `account_keys`, son la forma en que Solana deriva qué cuentas son escribibles frente a solo lectura y cuáles deben firmar — sin almacenar un indicador por cuenta. Las primeras `num_required_signatures` claves son firmantes; dentro de cada bloque de firmantes/no firmantes, las últimas `num_readonly_*` claves son de solo lectura.

## Dónde lo encuentras

Cualquier transacción en bruto que obtengas de `getTransaction`, simules o construyas con un SDK cliente. Las pantallas de «aprobar» de las billeteras decodifican esta estructura para mostrarte qué estás firmando.

## Errores comunes

- **Las cuentas se referencian por índice, no por pubkey.** Las instrucciones almacenan índices de 1 byte en `account_keys`, no las claves de 32 bytes. Esa es toda la razón por la que existe el techo de ~35 cuentas en las transacciones heredadas y por la que se añadieron las [Address Lookup Tables](/learn/transactions/address-lookup-table).
- **El orden de las claves codifica los permisos.** El orden en cuatro vías (firmante-escribible → firmante-solo-lectura → no-firmante-escribible → no-firmante-solo-lectura) es funcional. Reordena las claves y cambias qué cuentas son escribibles. Los decodificadores deben respetar los recuentos de la cabecera para clasificar cada clave.
- **Las firmas firman el mensaje, no toda la transacción.** Las firmas Ed25519 cubren solo los bytes del *mensaje* serializado. Al verificar, hashea/verifica desde el inicio del mensaje, no desde el byte 0.
- **`recent_blockhash` es también la clave de deduplicación.** Dos transacciones por lo demás idénticas con el mismo blockhash son la misma transacción. No es solo frescura — es protección contra repetición.
- **Una transacción heredada frente a una v0 se distingue por el primer byte del mensaje.** Si el bit alto del primer byte del mensaje está a 1, es una transacción versionada (v0) y el byte es un prefijo de versión; de lo contrario es heredada y ese byte es `num_required_signatures`. Los valores reales de `num_required_signatures` son pequeños, así que el bit alto queda libre para usarse como discriminador.
