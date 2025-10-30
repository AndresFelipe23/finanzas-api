# Módulo de Transacciones

Este módulo gestiona todas las transacciones financieras (ingresos y gastos) de los usuarios.

## Estructura

```
transacciones/
├── transacciones.module.ts          # Módulo de NestJS
├── transacciones.controller.ts      # Controlador REST
├── transacciones.service.ts         # Lógica de negocio
├── entities/
│   └── transaccion.entity.ts         # Entidad TypeORM
├── dto/
│   ├── create-transaccion.dto.ts    # DTO para crear transacciones
│   ├── update-transaccion.dto.ts    # DTO para actualizar transacciones
│   └── transaccion-response.dto.ts   # DTO de respuesta
└── README.md                         # Este archivo
```

## Endpoints

### `POST /api/transacciones`
Crea una nueva transacción.

**Request Body:**
```json
{
  "cuentaId": 1,
  "tipoTransaccionId": 1,
  "categoriaId": 1,
  "metodoPagoId": 1,
  "monto": 50000.00,
  "moneda": "COP",
  "descripcion": "Compra de supermercado",
  "fechaTransaccion": "2024-01-15T10:30:00",
  "notas": "Notas adicionales"
}
```

### `GET /api/transacciones`
Obtiene todas las transacciones del usuario.

**Query Parameters:**
- `fechaInicio` (opcional): Fecha de inicio del filtro
- `fechaFin` (opcional): Fecha de fin del filtro

**Ejemplo:** `GET /api/transacciones?fechaInicio=2024-01-01&fechaFin=2024-01-31`

### `GET /api/transacciones/summary`
Obtiene un resumen estadístico de transacciones.

**Response:** Resumen con totales, balance, y estadísticas por categoría

### `GET /api/transacciones/cuenta/:cuentaId`
Obtiene todas las transacciones de una cuenta específica.

**Query Parameters:** `fechaInicio`, `fechaFin` (opcionales)

### `GET /api/transacciones/categoria/:categoriaId`
Obtiene todas las transacciones de una categoría específica.

**Query Parameters:** `fechaInicio`, `fechaFin` (opcionales)

### `GET /api/transacciones/:id`
Obtiene una transacción específica por su ID.

### `PATCH /api/transacciones/:id`
Actualiza una transacción existente.

**Request Body:** Todos los campos son opcionales
```json
{
  "monto": 60000.00,
  "descripcion": "Compra actualizada"
}
```

### `DELETE /api/transacciones/:id`
Elimina una transacción (soft delete - marca como inactiva).

## Características

- ✅ Crear transacciones con toda la información necesaria
- ✅ Filtrar por fecha (inicio y fin)
- ✅ Filtrar por cuenta
- ✅ Filtrar por categoría
- ✅ Obtener resumen estadístico
- ✅ Soft delete (mantiene histórico)
- ✅ Validaciones de datos relacionados
- ✅ Soporte para archivos adjuntos
- ✅ Notas y descripciones
- ✅ Transacciones recurrentes

## Tabla de Base de Datos

```sql
CREATE TABLE transacciones (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    cuenta_id BIGINT NULL,
    tipo_transaccion_id BIGINT NOT NULL,
    categoria_id BIGINT NULL,
    metodo_pago_id BIGINT NULL,
    monto DECIMAL(18,2) NOT NULL,
    moneda NVARCHAR(10) DEFAULT 'COP' NOT NULL,
    descripcion NVARCHAR(500) NULL,
    fecha_transaccion DATETIME2 NOT NULL,
    archivo_adjunto NVARCHAR(500) NULL,
    notas NVARCHAR(1000) NULL,
    repetir BIT DEFAULT 0 NOT NULL,
    activa BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    ...
);
```

## Validaciones

- El monto debe ser mayor que cero
- La cuenta debe existir y pertenecer al usuario
- La categoría debe existir y ser accesible por el usuario
- El método de pago debe existir
- El tipo de transacción debe ser válido

## Relaciones

Las transacciones se relacionan con:
- **Usuario**: Cada transacción pertenece a un usuario
- **Cuenta**: Desde/cuenta origen de la transacción
- **Categoría**: Categorización de la transacción
- **Método de Pago**: Método utilizado
- **Tipo de Transacción**: INGRESO, GASTO o TRANSFERENCIA

## Notas de Implementación

⚠️ **Nota**: El backend actualmente tiene el `usuarioId` hardcodeado a 1. Una vez que se implemente el JWT guard, el frontend automáticamente enviará el token correcto a través del interceptor de Dio configurado en `ApiClient`.

## Ejemplos de Uso

### Crear un ingreso
```typescript
POST /api/transacciones
{
  "cuentaId": 1,
  "tipoTransaccionId": 1, // INGRESO
  "categoriaId": 5,
  "monto": 2000000.00,
  "moneda": "COP",
  "descripcion": "Salario enero",
  "fechaTransaccion": "2024-01-01T08:00:00"
}
```

### Crear un gasto
```typescript
POST /api/transacciones
{
  "cuentaId": 1,
  "tipoTransaccionId": 2, // GASTO
  "categoriaId": 3,
  "metodoPagoId": 1,
  "monto": 50000.00,
  "descripcion": "Supermercado",
  "fechaTransaccion": "2024-01-15T10:30:00"
}
```

### Obtener resumen mensual
```typescript
GET /api/transacciones/summary?fechaInicio=2024-01-01&fechaFin=2024-01-31
```

