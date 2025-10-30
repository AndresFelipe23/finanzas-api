# Módulo de Cuentas

Este módulo gestiona las cuentas bancarias, efectivo, y wallets digitales de los usuarios.

## Estructura

```
cuentas/
├── cuentas.module.ts           # Módulo de NestJS
├── cuentas.controller.ts       # Controlador REST
├── cuentas.service.ts          # Lógica de negocio
├── entities/
│   └── cuenta.entity.ts         # Entidad TypeORM
├── dto/
│   ├── create-cuenta.dto.ts    # DTO para crear cuentas
│   ├── update-cuenta.dto.ts    # DTO para actualizar cuentas
│   └── cuenta-response.dto.ts   # DTO de respuesta
└── README.md                    # Este archivo
```

## Endpoints

### `POST /cuentas`
Crea una nueva cuenta para el usuario autenticado.

**Request Body:**
```json
{
  "nombre": "Cuenta Principal",
  "tipo": "BANCARIA",
  "moneda": "COP",
  "saldoInicial": 1000.00,
  "color": "#10B981",
  "icono": "account_balance",
  "descripcion": "Cuenta bancaria principal"
}
```

**Parámetros:**
- `nombre` (requerido): Nombre de la cuenta
- `tipo` (opcional): Tipo de cuenta (default: 'BANCARIA')
- `moneda` (opcional): Código de moneda (default: 'COP')
- `saldoInicial` (opcional): Saldo inicial (default: 0)
- `color` (opcional): Color en formato hexadecimal
- `icono` (opcional): Icono de la cuenta
- `descripcion` (opcional): Descripción de la cuenta

### `GET /cuentas`
Obtiene todas las cuentas activas del usuario con su saldo actual calculado.

**Query Parameters:**
- `tipo` (opcional): Filtrar por tipo

**Ejemplo:** `GET /cuentas?tipo=BANCARIA`

**Response:** Lista de cuentas con `saldo_actual` calculado automáticamente

### `GET /cuentas/:id`
Obtiene una cuenta específica con su saldo actual.

### `GET /cuentas/summary`
Obtiene estadísticas de uso de las cuentas.

**Response:**
```json
[
  {
    "id": 1,
    "nombre": "Cuenta Principal",
    "tipo": "BANCARIA",
    "moneda": "COP",
    "saldo_inicial": 1000,
    "total_transacciones": 25,
    "saldo_actual": 1500,
    "total_ingresos": 2000,
    "total_gastos": 500
  }
]
```

### `PATCH /cuentas/:id`
Actualiza una cuenta existente.

**Request Body:** Todos los campos son opcionales
```json
{
  "nombre": "Cuenta Actualizada",
  "color": "#FF0000"
}
```

### `DELETE /cuentas/:id`
Elimina una cuenta físicamente. 
- ❌ No se puede eliminar si tiene transacciones asociadas
- ❌ No se puede eliminar si tiene saldo != 0
- ✅ Eliminación física (DELETE de BD)

## Tipos de Cuentas

- **BANCARIA**: Cuenta bancaria tradicional
- **EFECTIVO**: Efectivo físico
- **TARJETA_CREDITO**: Tarjeta de crédito
- **TARJETA_DEBITO**: Tarjeta de débito
- **DIGITAL**: Wallet digital (PayPal, Venmo, etc.)
- **AHORRO**: Cuenta de ahorros
- **INVERSION**: Cuenta de inversión

## Características

- ✅ Cálculo automático de saldo actual (saldo_inicial + transacciones)
- ✅ Eliminación física de cuentas (DELETE de la BD)
- ✅ Validación de eliminación:
  - No permite eliminar si tiene transacciones
  - No permite eliminar si tiene saldo != 0
- ✅ Filtrado por tipo de cuenta
- ✅ Estadísticas de uso de cuentas
- ✅ Soporte para múltiples monedas
- ✅ Colores e iconos personalizables

## Tabla de Base de Datos

```sql
CREATE TABLE cuentas (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    tipo NVARCHAR(30) NOT NULL CHECK (tipo IN ('BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION')),
    moneda NVARCHAR(10) DEFAULT 'COP' NOT NULL,
    saldo_inicial DECIMAL(18,2) DEFAULT 0 NOT NULL,
    color NVARCHAR(7) NULL,
    icono NVARCHAR(50) NULL,
    descripcion NVARCHAR(500) NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_cuentas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);
```

## Cálculo de Saldo Actual

El saldo actual se calcula automáticamente:
```
saldo_actual = saldo_inicial + (suma de ingresos) - (suma de gastos)
```

Los ingresos y gastos se obtienen de las transacciones relacionadas con la cuenta.

## Validaciones

- No se puede crear una cuenta duplicada para el mismo usuario (mismo nombre)
- No se puede eliminar una cuenta si tiene transacciones activas
- No se puede eliminar una cuenta si tiene saldo diferente de cero
- El tipo de cuenta debe ser uno de los valores permitidos
- El saldo inicial no puede ser negativo
- El nombre es requerido

## Notas de Implementación

⚠️ **Nota**: El backend actualmente tiene el `usuarioId` hardcodeado a 1. Una vez que se implemente el JWT guard, el frontend automáticamente enviará el token correcto a través del interceptor de Dio configurado en `ApiClient`.

## Ejemplos de Uso

### Crear una cuenta bancaria
```typescript
POST /api/cuentas
{
  "nombre": "Banco Nacional",
  "tipo": "BANCARIA",
  "moneda": "COP",
  "saldoInicial": 5000,
  "color": "#10B981",
  "icono": "account_balance"
}
```

### Obtener todas las cuentas con saldo
```typescript
GET /api/cuentas
// Retorna array de cuentas con saldo_actual calculado
```

### Actualizar cuenta
```typescript
PATCH /api/cuentas/1
{
  "nombre": "Cuenta Personal",
  "color": "#6366F1"
}
```

### Eliminar cuenta
```typescript
DELETE /api/cuentas/1
// Solo si no tiene transacciones ni saldo
```

