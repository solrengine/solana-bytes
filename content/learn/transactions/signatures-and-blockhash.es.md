---
name: Firmas y Blockhash Reciente
summary: Cómo se firma una transacción y se mantiene fresca — firmas Ed25519 sobre los bytes del mensaje, un blockhash reciente que expira en ~80 segundos, y nonces duraderos para transacciones que deben sobrevivir a esa ventana.
---

## Qué es

Dos mecanismos mantienen las transacciones auténticas y frescas: las **firmas** prueban que las claves requeridas autorizaron la transacción, y el **blockhash reciente** prueba que se creó hace poco (y evita la repetición). Juntos son la envoltura de seguridad alrededor del cuerpo del mensaje.

## Por qué existe

Sin firmas, cualquiera podría mover los tokens de cualquiera. Sin un marcador de frescura, una transacción capturada podría repetirse para siempre. El blockhash resuelve ambos — expira rápido *e* identifica de forma única la transacción, así que los mismos bytes firmados no pueden reenviarse después de que el blockhash caduque.

## Diseño de bytes

| Campo | Ubicación | Tipo | Notas |
|-------|-----------|------|-------|
| `signatures` | parte superior de la transacción | recuento `compact-u16` + 64 bytes c/u | Firmas Ed25519 sobre los bytes del **mensaje** serializado. El orden coincide con las primeras `num_required_signatures` claves de cuenta. |
| `recent_blockhash` | dentro del mensaje | 32 bytes | Un blockhash de los últimos ~150 bloques. Funciona también como nonce de protección contra repetición. |

Una firma es la firma Ed25519 estándar de 64 bytes: firma el rango exacto de bytes del mensaje (todo lo que sigue al vector de firmas), y se verifica contra la pubkey de firmante correspondiente de `account_keys`.

## Caducidad del blockhash

Un blockhash reciente es válido durante **150 bloques** — aproximadamente 80–90 segundos a los tiempos de bloque de mainnet. Pasado eso, los validadores rechazan la transacción con un error «blockhash not found». Por eso una transacción que se queda demasiado tiempo en una billetera falla: su blockhash caducó. Los clientes deben obtener un blockhash fresco poco antes de firmar y enviar con prontitud.

## Nonces duraderos — escapar de la ventana de 80 segundos

Algunos flujos (firma offline, recogida de multifirma durante horas, aprobaciones de custodia) no pueden firmar y enviar en 80 segundos. Los **nonces duraderos** resuelven esto: una cuenta Nonce almacena un valor de nonce fijo que actúa como blockhash, y solo avanza cuando se ejecuta una instrucción `AdvanceNonceAccount`. Una transacción duradera:

1. Usa el valor almacenado de la cuenta Nonce en el campo `recent_blockhash` en lugar de un blockhash real.
2. Tiene `AdvanceNonceAccount` como su **primera instrucción**, que consume-y-rota el nonce para que la transacción no pueda repetirse.

La transacción sigue siendo válida hasta que el nonce avanza — días o semanas después si hace falta.

## Dónde lo encuentras

Cada transacción tiene firmas y un blockhash. Los nonces duraderos aparecen en productos de custodia, multifirma de Squads, tuberías de retiro de exchanges y cualquier flujo de firma offline.

## Errores comunes

- **Las firmas cubren el mensaje, no toda la transacción.** La verificación empieza en el offset del mensaje (tras el vector de firmas), no en el byte 0. Firmar el rango de bytes equivocado es un error clásico.
- **El blockhash es protección contra repetición, no solo frescura.** Dos transacciones idénticas con el mismo blockhash son *la misma transacción* y solo aterrizan una vez. Cambia el blockhash y es una transacción nueva que aterriza por separado.
- **Una transacción con nonce duradero debe poner `AdvanceNonceAccount` primero.** Si no es la primera instrucción, el runtime no tratará el nonce almacenado como un blockhash válido y la transacción falla.
- **El pagador de comisiones firma aunque no haga nada más.** El primer firmante requerido es el pagador de comisiones; debe firmar y tener suficiente SOL para las comisiones, sin importar qué hagan las instrucciones.
