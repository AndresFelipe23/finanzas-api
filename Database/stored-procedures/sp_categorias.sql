-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS PARA CATEGORÍAS
-- SQL Server Stored Procedures for Categories
-- =====================================================

USE FinanzasApiApp
GO

-- =====================================================
-- Crear Categoría (sp_categoria_create)
-- Crea una nueva categoría para un usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_create
    @UsuarioId BIGINT,
    @Nombre NVARCHAR(100),
    @Icono NVARCHAR(50) = NULL,
    @Color NVARCHAR(7) = NULL,
    @Tipo NVARCHAR(20) = 'GASTO',
    @CategoriaId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar el tipo
    IF @Tipo NOT IN ('INGRESO', 'GASTO', 'AMBOS')
    BEGIN
        RAISERROR('El tipo debe ser INGRESO, GASTO o AMBOS', 16, 1);
        RETURN;
    END
    
    -- Verificar si la categoría ya existe para este usuario
    IF EXISTS (SELECT 1 FROM categorias WHERE usuario_id = @UsuarioId AND nombre = @Nombre)
    BEGIN
        RAISERROR('Ya existe una categoría con este nombre', 16, 1);
        RETURN;
    END
    
    -- Insertar la nueva categoría
    INSERT INTO categorias (
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    )
    VALUES (
        @UsuarioId,
        @Nombre,
        @Icono,
        @Color,
        @Tipo,
        1,
        GETDATE()
    );
    
    SET @CategoriaId = SCOPE_IDENTITY();
    
    -- Retornar la categoría creada
    SELECT 
        id,
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    FROM categorias
    WHERE id = @CategoriaId;
END;
GO

-- =====================================================
-- Obtener Categorías del Usuario (sp_categoria_get_by_user)
-- Obtiene todas las categorías activas de un usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_get_by_user
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        id,
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    FROM categorias
    WHERE usuario_id = @UsuarioId 
        AND activo = 1
    ORDER BY tipo, nombre;
END;
GO

-- =====================================================
-- Obtener Categoría por ID (sp_categoria_get_by_id)
-- Obtiene una categoría específica por su ID
-- Solo devuelve categorías del usuario (no del sistema)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_get_by_id
    @CategoriaId BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que la categoría pertenece al usuario y NO es del sistema
    IF NOT EXISTS (
        SELECT 1 
        FROM categorias 
        WHERE id = @CategoriaId 
            AND usuario_id = @UsuarioId 
            AND activo = 1
    )
    BEGIN
        RAISERROR('Categoría no encontrada', 16, 1);
        RETURN;
    END
    
    SELECT 
        id,
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    FROM categorias
    WHERE id = @CategoriaId 
        AND usuario_id = @UsuarioId
        AND activo = 1;
END;
GO

-- =====================================================
-- Actualizar Categoría (sp_categoria_update)
-- Actualiza los datos de una categoría
-- No se pueden modificar categorías del sistema (usuario_id = NULL)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_update
    @CategoriaId BIGINT,
    @UsuarioId BIGINT,
    @Nombre NVARCHAR(100) = NULL,
    @Icono NVARCHAR(50) = NULL,
    @Color NVARCHAR(7) = NULL,
    @Tipo NVARCHAR(20) = NULL,
    @Activo BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que la categoría existe
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId)
    BEGIN
        RAISERROR('La categoría no existe', 16, 1);
        RETURN;
    END
    
    -- Validar que NO es una categoría del sistema (usuario_id = NULL)
    IF EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND usuario_id IS NULL)
    BEGIN
        RAISERROR('No se pueden modificar categorías del sistema', 16, 1);
        RETURN;
    END
    
    -- Validar que la categoría pertenece al usuario
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND usuario_id = @UsuarioId)
    BEGIN
        RAISERROR('La categoría no pertenece a este usuario', 16, 1);
        RETURN;
    END
    
    -- Validar tipo si se proporciona
    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('INGRESO', 'GASTO', 'AMBOS')
    BEGIN
        RAISERROR('El tipo debe ser INGRESO, GASTO o AMBOS', 16, 1);
        RETURN;
    END
    
    -- Actualizar solo los campos proporcionados
    UPDATE categorias
    SET 
        nombre = ISNULL(@Nombre, nombre),
        icono = ISNULL(@Icono, icono),
        color = ISNULL(@Color, color),
        tipo = ISNULL(@Tipo, tipo),
        activo = ISNULL(@Activo, activo)
    WHERE id = @CategoriaId;
    
    -- Retornar la categoría actualizada
    SELECT 
        id,
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    FROM categorias
    WHERE id = @CategoriaId;
END;
GO

-- =====================================================
-- Eliminar Categoría (sp_categoria_delete)
-- Elimina físicamente una categoría de la base de datos
-- No se pueden eliminar categorías del sistema (usuario_id = NULL)
-- No se pueden eliminar si tienen transacciones asociadas
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_delete
    @CategoriaId BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que la categoría existe
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId)
    BEGIN
        RAISERROR('La categoría no existe', 16, 1);
        RETURN;
    END
    
    -- Validar que NO es una categoría del sistema (usuario_id = NULL)
    IF EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND usuario_id IS NULL)
    BEGIN
        RAISERROR('No se pueden eliminar categorías del sistema', 16, 1);
        RETURN;
    END
    
    -- Validar que la categoría pertenece al usuario
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND usuario_id = @UsuarioId)
    BEGIN
        RAISERROR('La categoría no pertenece a este usuario', 16, 1);
        RETURN;
    END
    
    -- Verificar si la categoría tiene transacciones asociadas
    IF EXISTS (SELECT 1 FROM transacciones WHERE categoria_id = @CategoriaId AND activa = 1)
    BEGIN
        DECLARE @TransaccionesCount INT;
        SELECT @TransaccionesCount = COUNT(*) 
        FROM transacciones 
        WHERE categoria_id = @CategoriaId AND activa = 1;
        
        RAISERROR('No se puede eliminar la categoría porque tiene %d transacción(es) asociada(s)', 16, 1, @TransaccionesCount);
        RETURN;
    END
    
    -- Eliminación física de la base de datos
    DELETE FROM categorias
    WHERE id = @CategoriaId;
    
    SELECT 1 AS eliminado;
END;
GO

-- =====================================================
-- Obtener Categorías por Tipo (sp_categoria_get_by_type)
-- Obtiene categorías de un usuario filtradas por tipo
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_get_by_type
    @UsuarioId BIGINT,
    @Tipo NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar el tipo
    IF @Tipo NOT IN ('INGRESO', 'GASTO', 'AMBOS')
    BEGIN
        RAISERROR('El tipo debe ser INGRESO, GASTO o AMBOS', 16, 1);
        RETURN;
    END
    
    SELECT 
        id,
        usuario_id,
        nombre,
        icono,
        color,
        tipo,
        activo,
        fecha_creacion
    FROM categorias
    WHERE usuario_id = @UsuarioId 
        AND activo = 1
        AND (tipo = @Tipo OR tipo = 'AMBOS')
    ORDER BY nombre;
END;
GO

-- =====================================================
-- Verificar si Categoría es Usable (sp_categoria_check_usage)
-- Verifica si una categoría puede ser eliminada (no tiene transacciones)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_check_usage
    @CategoriaId BIGINT,
    @TieneTransacciones BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si hay transacciones con esta categoría
    IF EXISTS (SELECT 1 FROM transacciones WHERE categoria_id = @CategoriaId AND activa = 1)
    BEGIN
        SET @TieneTransacciones = 1;
    END
    ELSE
    BEGIN
        SET @TieneTransacciones = 0;
    END
END;
GO

-- =====================================================
-- Resumen de Categorías (sp_categoria_get_summary)
-- Obtiene estadísticas de uso de categorías para un usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_get_summary
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener IDs de tipos de transacción
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.id,
        c.nombre,
        c.tipo,
        c.color,
        c.icono,
        COUNT(t.id) AS total_transacciones,
        COALESCE(SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END), 0) AS total_ingresos,
        COALESCE(SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END), 0) AS total_gastos
    FROM categorias c
    LEFT JOIN transacciones t ON c.id = t.categoria_id 
        AND t.usuario_id = @UsuarioId 
        AND t.activa = 1
    WHERE c.usuario_id = @UsuarioId 
        AND c.activo = 1
    GROUP BY c.id, c.nombre, c.tipo, c.color, c.icono
    ORDER BY total_transacciones DESC, c.nombre;
END;
GO

-- =====================================================
-- Insertar Categorías Predeterminadas (sp_categoria_insert_defaults)
-- Inserta categorías predeterminadas para un usuario nuevo
-- =====================================================
CREATE OR ALTER PROCEDURE sp_categoria_insert_defaults
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Categorías de GASTO predeterminadas
    INSERT INTO categorias (usuario_id, nombre, tipo, color, icono)
    VALUES 
        (@UsuarioId, 'Alimentación', 'GASTO', '#FF6B6B', 'restaurant'),
        (@UsuarioId, 'Transporte', 'GASTO', '#4ECDC4', 'directions_car'),
        (@UsuarioId, 'Salud', 'GASTO', '#45B7D1', 'local_hospital'),
        (@UsuarioId, 'Educación', 'GASTO', '#FFA07A', 'school'),
        (@UsuarioId, 'Entretenimiento', 'GASTO', '#98D8C8', 'sports_esports'),
        (@UsuarioId, 'Ropa', 'GASTO', '#F7DC6F', 'checkroom'),
        (@UsuarioId, 'Vivienda', 'GASTO', '#BB8FCE', 'home'),
        (@UsuarioId, 'Facturas', 'GASTO', '#85C1E2', 'receipt'),
        (@UsuarioId, 'Supermercado', 'GASTO', '#F1948A', 'shopping_cart'),
        (@UsuarioId, 'Otros Gastos', 'GASTO', '#95A5A6', 'more_horiz');
    
    -- Categorías de INGRESO predeterminadas
    INSERT INTO categorias (usuario_id, nombre, tipo, color, icono)
    VALUES 
        (@UsuarioId, 'Salario', 'INGRESO', '#10B981', 'work'),
        (@UsuarioId, 'Freelance', 'INGRESO', '#6366F1', 'computer'),
        (@UsuarioId, 'Inversiones', 'INGRESO', '#8B5CF6', 'trending_up'),
        (@UsuarioId, 'Bonos', 'INGRESO', '#EC4899', 'card_giftcard'),
        (@UsuarioId, 'Otros Ingresos', 'INGRESO', '#14B8A6', 'attach_money');
    
    SELECT 'Categorías predeterminadas creadas' AS mensaje;
END;
GO

-- =====================================================
-- FIN DE PROCEDIMIENTOS ALMACENADOS PARA CATEGORÍAS
-- =====================================================

PRINT 'Procedimientos almacenados de categorías creados exitosamente';
GO

