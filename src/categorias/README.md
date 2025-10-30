# Módulo de Categorías

Este módulo gestiona las categorías de transacciones (ingresos y gastos) para los usuarios.

## Estructura

```
categorias/
├── categorias.module.ts          # Módulo de NestJS
├── categorias.controller.ts      # Controlador REST
├── categorias.service.ts         # Lógica de negocio
├── entities/
│   └── categoria.entity.ts       # Entidad TypeORM
├── dto/
│   ├── create-categoria.dto.ts   # DTO para crear categorías
│   ├── update-categoria.dto.ts   # DTO para actualizar categorías
│   └── categoria-response.dto.ts # DTO de respuesta
└── README.md                      # Este archivo
```

## Endpoints

### `POST /categorias`
Crea una nueva categoría personalizada para el usuario autenticado.

**Request Body:**
```json
{
  "nombre": "Alimentación",
  "icono": "restaurant",
  "color": "#FF6B6B",
  "tipo": "GASTO"
}
```

**Parámetros:**
- `nombre` (requerido): Nombre de la categoría
- `icono` (opcional): Icono de la categoría
- `color` (opcional): Color en formato hexadecimal
- `tipo` (opcional): Tipo de categoría: INGRESO, GASTO o AMBOS (default: GASTO)

### `GET /categorias`
Obtiene todas las categorías activas del usuario.

**Query Parameters:**
- `tipo` (opcional): Filtrar por tipo (INGRESO, GASTO, AMBOS)

**Ejemplo:** `GET /categorias?tipo=GASTO`

### `GET /categorias/:id`
Obtiene una categoría específica por su ID.

### `GET /categorias/summary`
Obtiene estadísticas de uso de las categorías para el usuario.

**Response:**
```json
[
  {
    "id": 1,
    "nombre": "Alimentación",
    "tipo": "GASTO",
    "color": "#FF6B6B",
    "icono": "restaurant",
    "total_transacciones": 45,
    "total_ingresos": 0,
    "total_gastos": 125000
  }
]
```

### `POST /categorias/default`
Crea categorías predeterminadas para el usuario si no tiene ninguna.

### `PATCH /categorias/:id`
Actualiza una categoría existente.

**Request Body:**
```json
{
  "nombre": "Comida",
  "color": "#FF0000",
  "activo": true
}
```

### `DELETE /categorias/:id`
Elimina una categoría (soft delete). No se puede eliminar si tiene transacciones asociadas.

## Tipos de Categorías

- **INGRESO**: Categoría para ingresos económicos
- **GASTO**: Categoría para gastos económicos
- **AMBOS**: Categoría que puede usarse tanto para ingresos como gastos

## Características

- ✅ Crear categorías personalizadas por usuario
- ✅ Categorías predeterminadas del sistema
- ✅ Eliminación física de categorías (DELETE de la BD)
- ✅ Validación de eliminación (no permite eliminar si hay transacciones)
- ✅ Protección de categorías del sistema (usuario_id = NULL) - no se pueden modificar ni eliminar
- ✅ Solo se muestran categorías del usuario (no del sistema)
- ✅ Estadísticas de uso de categorías
- ✅ Filtrado por tipo de categoría
- ✅ Colores e iconos personalizables

## Tabla de Base de Datos

```sql
CREATE TABLE categorias (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id BIGINT NULL, -- NULL para categorías globales del sistema
    nombre NVARCHAR(100) NOT NULL,
    icono NVARCHAR(50) NULL,
    color NVARCHAR(7) NULL,
    tipo NVARCHAR(20) NOT NULL CHECK (tipo IN ('INGRESO', 'GASTO', 'AMBOS')),
    activo BIT DEFAULT 1 NOT NULL,
    fecha_creacion DATETIME2 DEFAULT GETDATE() NOT NULL,
    CONSTRAINT FK_categorias_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT UQ_categorias_usuario_nombre UNIQUE (usuario_id, nombre)
);
```

## Notas de Implementación

⚠️ **TODO**: Actualmente el `usuarioId` está hardcodeado a 1. Es necesario implementar un JWT guard para extraer el usuario autenticado del token.

Ejemplo de implementación futura:
```typescript
@UseGuards(JwtAuthGuard)
async create(
  @Body() createCategoriaDto: CreateCategoriaDto,
  @CurrentUser() user: any
): Promise<CategoriaResponseDto> {
  return await this.categoriasService.create(user.id, createCategoriaDto);
}
```

## Validaciones

- No se puede crear una categoría duplicada para el mismo usuario
- No se puede eliminar una categoría si tiene transacciones activas asociadas (DELETE físico de BD)
- No se pueden modificar ni eliminar categorías del sistema (usuario_id = NULL)
- Solo se muestran las categorías que pertenecen al usuario
- El tipo debe ser uno de: INGRESO, GASTO o AMBOS
- El nombre es requerido

