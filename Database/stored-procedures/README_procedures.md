# 📋 Procedimientos Almacenados - Sistema de Finanzas

## 📁 Archivo: `sp_usuarios.sql`

### Procedimientos de Autenticación y Registro

#### 1. **sp_usuario_login**
- **Propósito**: Iniciar sesión de usuario
- **Parámetros**:
  - `@Email` NVARCHAR(255)
  - `@PasswordHash` NVARCHAR(255)
- **Retorna**: Datos del usuario si las credenciales son correctas

#### 2. **sp_usuario_create**
- **Propósito**: Registrar nuevo usuario
- **Parámetros**:
  - `@Nombre` NVARCHAR(100)
  - `@Email` NVARCHAR(255)
  - `@PasswordHash` NVARCHAR(255)
  - `@Telefono` NVARCHAR(20) - Opcional
  - `@FechaNacimiento` DATETIME2 - Opcional
  - `@MonedaPredeterminada` NVARCHAR(10) - Opcional (default: 'COP')
  - `@UsuarioId` BIGINT OUTPUT - ID del usuario creado
- **Retorna**: Usuario creado

#### 3. **sp_usuario_email_exists**
- **Propósito**: Verificar si un email ya está registrado
- **Parámetros**:
  - `@Email` NVARCHAR(255)
  - `@Existe` BIT OUTPUT
- **Retorna**: 1 si existe, 0 si no existe

### Procedimientos de Perfil

#### 4. **sp_usuario_get_by_id**
- **Propósito**: Obtener información de un usuario por ID
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Datos del usuario

#### 5. **sp_usuario_update_profile**
- **Propósito**: Actualizar perfil del usuario
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@Nombre` NVARCHAR(100)
  - `@Telefono` NVARCHAR(20) - Opcional
  - `@FechaNacimiento` DATETIME2 - Opcional
  - `@MonedaPredeterminada` NVARCHAR(10) - Opcional
- **Retorna**: Usuario actualizado

### Procedimientos de Seguridad

#### 6. **sp_usuario_change_password**
- **Propósito**: Cambiar contraseña
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@PasswordHashActual` NVARCHAR(255)
  - `@PasswordHashNuevo` NVARCHAR(255)
- **Retorna**: Confirmación de cambio

#### 7. **sp_usuario_update_email**
- **Propósito**: Actualizar email
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@EmailNuevo` NVARCHAR(255)
  - `@PasswordHash` NVARCHAR(255)
- **Retorna**: Usuario actualizado

#### 8. **sp_usuario_get_password_hash**
- **Propósito**: Obtener hash de contraseña (para validación)
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Hash de contraseña y estado activo

### Procedimientos de Administración

#### 9. **sp_usuarios_list**
- **Propósito**: Listar usuarios con paginación y búsqueda
- **Parámetros**:
  - `@PageNumber` INT - Default: 1
  - `@PageSize` INT - Default: 10
  - `@SearchTerm` NVARCHAR(100) - Opcional
  - `@Activo` BIT - Opcional (NULL = todos)
- **Retorna**: Total de registros + Lista paginada

#### 10. **sp_usuario_deactivate**
- **Propósito**: Desactivar usuario (soft delete)
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@AdminId` BIGINT - Opcional
- **Retorna**: Usuario desactivado

#### 11. **sp_usuario_activate**
- **Propósito**: Activar usuario
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Usuario activado

### Procedimientos Pendientes

#### 12. **sp_usuario_set_password_reset_token**
- **Propósito**: Token de recuperación de contraseña
- **Estado**: Pendiente - Requiere agregar campos a la tabla usuarios:
  - `password_reset_token` NVARCHAR(255) NULL
  - `token_expiry` DATETIME2 NULL

---

## 🚀 Ejemplos de Uso

### Ejemplo 1: Registrar Usuario

```sql
DECLARE @NuevoUsuarioId BIGINT;

EXEC sp_usuario_create
    @Nombre = 'Juan Pérez',
    @Email = 'juan@example.com',
    @PasswordHash = 'hash_de_la_contraseña',
    @Telefono = '+50212345678',
    @FechaNacimiento = '1990-01-15',
    @MonedaPredeterminada = 'COP',
    @UsuarioId = @NuevoUsuarioId OUTPUT;
```

### Ejemplo 2: Iniciar Sesión

```sql
EXEC sp_usuario_login
    @Email = 'juan@example.com',
    @PasswordHash = 'hash_de_la_contraseña';
```

### Ejemplo 3: Actualizar Perfil

```sql
EXEC sp_usuario_update_profile
    @UsuarioId = 1,
    @Nombre = 'Juan Carlos Pérez',
    @Telefono = '+50212345679',
    @FechaNacimiento = '1990-01-15',
    @MonedaPredeterminada = 'EUR';
```

### Ejemplo 4: Listar Usuarios

```sql
EXEC sp_usuarios_list
    @PageNumber = 1,
    @PageSize = 20,
    @SearchTerm = 'juan',
    @Activo = 1;
```

### Ejemplo 5: Cambiar Contraseña

```sql
EXEC sp_usuario_change_password
    @UsuarioId = 1,
    @PasswordHashActual = 'hash_actual',
    @PasswordHashNuevo = 'hash_nuevo';
```

---

## 📝 Notas Importantes

### Seguridad
- **NUNCA** almacenar contraseñas en texto plano
- Usar hash (SHA-256, bcrypt, etc.) antes de guardar
- Validar credenciales antes de permitir acceso

### Contraseñas
- En NestJS, usar `bcrypt` para hashear contraseñas
- Ejemplo: `const hash = await bcrypt.hash(password, 10);`

### Next Steps
1. Implementar recuperación de contraseña (agregar campos a tabla)
2. Agregar logs de auditoría
3. Implementar rate limiting en API
4. Agregar validación de email único en Frontend

---

## 📁 Archivo: `sp_categorias.sql`

### Procedimientos de Gestión de Categorías

#### 1. **sp_categoria_create**
- **Propósito**: Crear una nueva categoría
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@Nombre` NVARCHAR(100)
  - `@Icono` NVARCHAR(50) - Opcional
  - `@Color` NVARCHAR(7) - Opcional
  - `@Tipo` NVARCHAR(20) - Opcional (default: 'GASTO')
  - `@CategoriaId` BIGINT OUTPUT
- **Retorna**: Categoría creada

#### 2. **sp_categoria_get_by_user**
- **Propósito**: Obtener todas las categorías de un usuario
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Lista de categorías activas ordenadas por tipo y nombre

#### 3. **sp_categoria_get_by_id**
- **Propósito**: Obtener una categoría específica del usuario (no del sistema)
- **Parámetros**:
  - `@CategoriaId` BIGINT
  - `@UsuarioId` BIGINT
- **Retorna**: Datos de la categoría
- **Validaciones**: Solo devuelve categorías del usuario, NO del sistema (usuario_id = NULL)

#### 4. **sp_categoria_update**
- **Propósito**: Actualizar categoría
- **Parámetros**: Todos opcionales
  - `@CategoriaId` BIGINT
  - `@UsuarioId` BIGINT
  - `@Nombre` NVARCHAR(100)
  - `@Icono` NVARCHAR(50)
  - `@Color` NVARCHAR(7)
  - `@Tipo` NVARCHAR(20)
  - `@Activo` BIT
- **Retorna**: Categoría actualizada
- **Validaciones**: 
  - No permite modificar categorías del sistema (usuario_id = NULL)
  - Verifica que la categoría pertenece al usuario

#### 5. **sp_categoria_delete**
- **Propósito**: Eliminar categoría físicamente (DELETE físico, no soft delete)
- **Parámetros**:
  - `@CategoriaId` BIGINT
  - `@UsuarioId` BIGINT
- **Retorna**: Confirmación
- **Validaciones**:
  - **NO** permite eliminar categorías del sistema (usuario_id = NULL)
  - Verifica que la categoría pertenece al usuario
  - No permite eliminar si tiene transacciones asociadas
  - Realiza DELETE físico de la base de datos

#### 6. **sp_categoria_get_by_type**
- **Propósito**: Obtener categorías por tipo
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@Tipo` NVARCHAR(20) - ('INGRESO', 'GASTO', 'AMBOS')
- **Retorna**: Categorías filtradas por tipo

#### 7. **sp_categoria_check_usage**
- **Propósito**: Verificar si una categoría tiene transacciones
- **Parámetros**:
  - `@CategoriaId` BIGINT
  - `@TieneTransacciones` BIT OUTPUT
- **Retorna**: 1 si tiene transacciones, 0 si no

#### 8. **sp_categoria_get_summary**
- **Propósito**: Estadísticas de uso de categorías
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Resumen con total de transacciones, ingresos y gastos por categoría

#### 9. **sp_categoria_insert_defaults**
- **Propósito**: Crear categorías predeterminadas para un usuario
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Confirmación

---

---

## 📁 Archivo: `sp_cuentas.sql`

### Procedimientos de Gestión de Cuentas

#### 1. **sp_cuenta_create**
- **Propósito**: Crear una nueva cuenta
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@Nombre` NVARCHAR(100)
  - `@Tipo` NVARCHAR(30) - Opcional (default: 'BANCARIA')
  - `@Moneda` NVARCHAR(10) - Opcional (default: 'COP')
  - `@SaldoInicial` DECIMAL(18,2) - Opcional (default: 0)
  - `@Color` NVARCHAR(7) - Opcional
  - `@Icono` NVARCHAR(50) - Opcional
  - `@Descripcion` NVARCHAR(500) - Opcional
  - `@CuentaId` BIGINT OUTPUT
- **Retorna**: Cuenta creada
- **Tipos válidos**: 'BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'

#### 2. **sp_cuenta_get_by_user**
- **Propósito**: Obtener todas las cuentas activas del usuario con su saldo actual
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Lista de cuentas con saldo actual calculado
- **Incluye**: Cálculo automático de saldo actual (saldo_inicial + movimientos)

#### 3. **sp_cuenta_get_by_id**
- **Propósito**: Obtener una cuenta específica con su saldo actual
- **Parámetros**:
  - `@CuentaId` BIGINT
  - `@UsuarioId` BIGINT
- **Retorna**: Datos de la cuenta con saldo actual
- **Validaciones**: Solo devuelve cuentas del usuario

#### 4. **sp_cuenta_update**
- **Propósito**: Actualizar cuenta
- **Parámetros**: Todos opcionales
  - `@CuentaId` BIGINT
  - `@UsuarioId` BIGINT
  - `@Nombre` NVARCHAR(100)
  - `@Tipo` NVARCHAR(30)
  - `@Moneda` NVARCHAR(10)
  - `@SaldoInicial` DECIMAL(18,2)
  - `@Color` NVARCHAR(7)
  - `@Icono` NVARCHAR(50)
  - `@Descripcion` NVARCHAR(500)
  - `@Activa` BIT
- **Retorna**: Cuenta actualizada con saldo
- **Validaciones**: 
  - Verifica que la cuenta pertenece al usuario
  - Valida tipo de cuenta

#### 5. **sp_cuenta_delete**
- **Propósito**: Eliminar cuenta físicamente (DELETE físico, no soft delete)
- **Parámetros**:
  - `@CuentaId` BIGINT
  - `@UsuarioId` BIGINT
- **Retorna**: Confirmación
- **Validaciones**:
  - No permite eliminar si tiene transacciones asociadas
  - No permite eliminar si tiene saldo != 0
  - Verifica que la cuenta pertenece al usuario
  - Realiza DELETE físico de la base de datos

#### 6. **sp_cuenta_get_saldo**
- **Propósito**: Obtener el saldo actual de una cuenta
- **Parámetros**:
  - `@CuentaId` BIGINT
  - `@UsuarioId` BIGINT
  - `@Saldo` DECIMAL(18,2) OUTPUT
- **Retorna**: Saldo actual (saldo_inicial + movimientos)
- **Uso**: Calcular saldo en tiempo real

#### 7. **sp_cuenta_get_summary**
- **Propósito**: Estadísticas de uso de cuentas
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Resumen con:
  - Total de transacciones por cuenta
  - Saldo actual de cada cuenta
  - Total de ingresos por cuenta
  - Total de gastos por cuenta

#### 8. **sp_cuenta_get_by_type**
- **Propósito**: Obtener cuentas filtradas por tipo
- **Parámetros**:
  - `@UsuarioId` BIGINT
  - `@Tipo` NVARCHAR(30)
- **Retorna**: Cuentas filtradas por tipo con saldo actual
- **Tipos**: 'BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'

#### 9. **sp_cuenta_check_usage**
- **Propósito**: Verificar si una cuenta puede ser eliminada
- **Parámetros**:
  - `@CuentaId` BIGINT
  - `@UsuarioId` BIGINT
  - `@TieneTransacciones` BIT OUTPUT
  - `@TieneSaldo` BIT OUTPUT
- **Retorna**: Indicadores de si tiene transacciones o saldo

#### 10. **sp_cuenta_get_by_moneda**
- **Propósito**: Obtener total de cuentas agrupadas por moneda
- **Parámetros**:
  - `@UsuarioId` BIGINT
- **Retorna**: Total de cuentas y saldo total por moneda

---

## 🔜 Próximos Procedimientos

- [x] Procedimientos para Cuentas
- [ ] Procedimientos para Transacciones
- [x] Procedimientos para Categorías
- [ ] Procedimientos para Presupuestos
- [ ] Procedimientos para Metas
- [ ] Procedimientos para Préstamos
- [ ] Procedimientos para NFC

