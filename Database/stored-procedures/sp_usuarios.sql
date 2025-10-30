-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS PARA USUARIOS
-- Sistema de Finanzas - NestJS API
-- =====================================================

USE FinanzasApiApp
GO

-- =====================================================
-- 1. SP: Iniciar Sesión (Login)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_login
    @Email NVARCHAR(255),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.id,
        u.nombre,
        u.email,
        u.telefono,
        u.fecha_nacimiento,
        u.moneda_predeterminada,
        u.activo,
        u.fecha_creacion,
        u.fecha_actualizacion
    FROM usuarios u
    WHERE u.email = @Email
        AND u.password_hash = @PasswordHash
        AND u.activo = 1;
END;
GO

-- =====================================================
-- 2. SP: Obtener Usuario por ID
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_get_by_id
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        id,
        nombre,
        email,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    FROM usuarios
    WHERE id = @UsuarioId
        AND activo = 1;
END;
GO

-- =====================================================
-- 3. SP: Registrar Nuevo Usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_create
    @Nombre NVARCHAR(100),
    @Email NVARCHAR(255),
    @PasswordHash NVARCHAR(255),
    @Telefono NVARCHAR(20) = NULL,
    @FechaNacimiento DATETIME2 = NULL,
    @MonedaPredeterminada NVARCHAR(10) = 'COP',
    @UsuarioId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si el email ya existe
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = @Email)
    BEGIN
        RAISERROR('El email ya está registrado', 16, 1);
        RETURN;
    END
    
    -- Insertar el nuevo usuario
    INSERT INTO usuarios (
        nombre,
        email,
        password_hash,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    )
    VALUES (
        @Nombre,
        @Email,
        @PasswordHash,
        @Telefono,
        @FechaNacimiento,
        @MonedaPredeterminada,
        1,
        GETDATE(),
        GETDATE()
    );
    
    SET @UsuarioId = SCOPE_IDENTITY();
    
    -- Retornar el usuario creado
    SELECT 
        id,
        nombre,
        email,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 4. SP: Actualizar Perfil de Usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_update_profile
    @UsuarioId BIGINT,
    @Nombre NVARCHAR(100),
    @Telefono NVARCHAR(20) = NULL,
    @FechaNacimiento DATETIME2 = NULL,
    @MonedaPredeterminada NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que el usuario exista y esté activo
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId AND activo = 1)
    BEGIN
        RAISERROR('Usuario no encontrado o inactivo', 16, 1);
        RETURN;
    END
    
    -- Actualizar los campos
    UPDATE usuarios
    SET 
        nombre = @Nombre,
        telefono = @Telefono,
        fecha_nacimiento = @FechaNacimiento,
        moneda_predeterminada = COALESCE(@MonedaPredeterminada, moneda_predeterminada),
        fecha_actualizacion = GETDATE()
    WHERE id = @UsuarioId;
    
    -- Retornar el usuario actualizado
    SELECT 
        id,
        nombre,
        email,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 5. SP: Cambiar Contraseña
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_change_password
    @UsuarioId BIGINT,
    @PasswordHashActual NVARCHAR(255),
    @PasswordHashNuevo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que el usuario exista y la contraseña actual sea correcta
    IF NOT EXISTS (
        SELECT 1 
        FROM usuarios 
        WHERE id = @UsuarioId 
            AND password_hash = @PasswordHashActual
            AND activo = 1
    )
    BEGIN
        RAISERROR('Contraseña actual incorrecta o usuario no encontrado', 16, 1);
        RETURN;
    END
    
    -- Actualizar la contraseña
    UPDATE usuarios
    SET 
        password_hash = @PasswordHashNuevo,
        fecha_actualizacion = GETDATE()
    WHERE id = @UsuarioId;
    
    -- Retornar confirmación
    SELECT 
        id,
        nombre,
        email,
        fecha_actualizacion AS password_actualizado_en
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 6. SP: Verificar si Email Existe
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_email_exists
    @Email NVARCHAR(255),
    @Existe BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = @Email)
        SET @Existe = 1
    ELSE
        SET @Existe = 0
    
    SELECT @Existe AS email_existe;
END;
GO

-- =====================================================
-- 7. SP: Desactivar Usuario (Soft Delete)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_deactivate
    @UsuarioId BIGINT,
    @AdminId BIGINT = NULL -- ID del admin que realiza la acción
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId)
    BEGIN
        RAISERROR('Usuario no encontrado', 16, 1);
        RETURN;
    END
    
    -- Desactivar el usuario
    UPDATE usuarios
    SET 
        activo = 0,
        fecha_actualizacion = GETDATE()
    WHERE id = @UsuarioId;
    
    -- Retornar confirmación
    SELECT 
        id,
        nombre,
        email,
        activo,
        fecha_actualizacion AS fecha_desactivacion
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 8. SP: Activar Usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_activate
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId)
    BEGIN
        RAISERROR('Usuario no encontrado', 16, 1);
        RETURN;
    END
    
    -- Activar el usuario
    UPDATE usuarios
    SET 
        activo = 1,
        fecha_actualizacion = GETDATE()
    WHERE id = @UsuarioId;
    
    -- Retornar confirmación
    SELECT 
        id,
        nombre,
        email,
        activo,
        fecha_actualizacion AS fecha_activacion
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 9. SP: Obtener Hash de Contraseña
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_get_password_hash
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        id,
        password_hash,
        activo
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 10. SP: Actualizar Email
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_update_email
    @UsuarioId BIGINT,
    @EmailNuevo NVARCHAR(255),
    @PasswordHash NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que el usuario exista y la contraseña sea correcta
    IF NOT EXISTS (
        SELECT 1 
        FROM usuarios 
        WHERE id = @UsuarioId 
            AND password_hash = @PasswordHash
            AND activo = 1
    )
    BEGIN
        RAISERROR('Contraseña incorrecta o usuario no encontrado', 16, 1);
        RETURN;
    END
    
    -- Verificar si el nuevo email ya existe
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = @EmailNuevo AND id != @UsuarioId)
    BEGIN
        RAISERROR('El nuevo email ya está en uso', 16, 1);
        RETURN;
    END
    
    -- Actualizar el email
    UPDATE usuarios
    SET 
        email = @EmailNuevo,
        fecha_actualizacion = GETDATE()
    WHERE id = @UsuarioId;
    
    -- Retornar el usuario actualizado
    SELECT 
        id,
        nombre,
        email,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    FROM usuarios
    WHERE id = @UsuarioId;
END;
GO

-- =====================================================
-- 11. SP: Listar Usuarios (Paginado)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuarios_list
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SearchTerm NVARCHAR(100) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Retornar total de registros
    SELECT COUNT(*) AS total_records
    FROM usuarios
    WHERE (activo = @Activo OR @Activo IS NULL)
        AND (
            @SearchTerm IS NULL 
            OR nombre LIKE '%' + @SearchTerm + '%'
            OR email LIKE '%' + @SearchTerm + '%'
        );
    
    -- Retornar registros paginados
    SELECT 
        id,
        nombre,
        email,
        telefono,
        fecha_nacimiento,
        moneda_predeterminada,
        activo,
        fecha_creacion,
        fecha_actualizacion
    FROM usuarios
    WHERE (activo = @Activo OR @Activo IS NULL)
        AND (
            @SearchTerm IS NULL 
            OR nombre LIKE '%' + @SearchTerm + '%'
            OR email LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY fecha_creacion DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- =====================================================
-- 12. SP: Actualizar Token de Recuperación de Contraseña
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuario_set_password_reset_token
    @UsuarioId BIGINT,
    @ResetToken NVARCHAR(255),
    @TokenExpiry DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nota: Este SP asume que agregarás un campo password_reset_token
    -- y token_expiry a la tabla usuarios
    
    RAISERROR('Funcionalidad no implementada. Agregar campos password_reset_token y token_expiry a la tabla usuarios.', 16, 1);
END;
GO

-- =====================================================
-- RESUMEN DE PROCEDIMIENTOS CREADOS
-- =====================================================
/*
PROCEDIMIENTOS ALMACENADOS CREADOS:
1. sp_usuario_login - Iniciar sesión
2. sp_usuario_get_by_id - Obtener usuario por ID
3. sp_usuario_create - Registrar nuevo usuario
4. sp_usuario_update_profile - Actualizar perfil
5. sp_usuario_change_password - Cambiar contraseña
6. sp_usuario_email_exists - Verificar si email existe
7. sp_usuario_deactivate - Desactivar usuario
8. sp_usuario_activate - Activar usuario
9. sp_usuario_get_password_hash - Obtener hash de contraseña
10. sp_usuario_update_email - Actualizar email
11. sp_usuarios_list - Listar usuarios (paginado)
12. sp_usuario_set_password_reset_token - Token recuperación (pendiente)

NOTA: Para implementar recuperación de contraseña, agregar campos:
- password_reset_token NVARCHAR(255) NULL
- token_expiry DATETIME2 NULL
*/

