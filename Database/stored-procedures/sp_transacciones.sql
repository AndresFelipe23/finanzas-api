-- =====================================================
-- STORED PROCEDURES PARA GESTIÓN DE TRANSACCIONES
-- =====================================================

-- SP: Crear nueva transacción
CREATE OR ALTER PROCEDURE sp_transaccion_create
    @UsuarioId BIGINT,
    @CuentaId BIGINT = NULL,
    @TipoTransaccionId BIGINT,
    @CategoriaId BIGINT = NULL,
    @MetodoPagoId BIGINT = NULL,
    @Monto DECIMAL(18,2),
    @Moneda NVARCHAR(10) = 'COP',
    @Titulo NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @FechaTransaccion DATETIME2(7) = NULL,
    @ArchivoAdjunto NVARCHAR(500) = NULL,
    @Notas NVARCHAR(1000) = NULL,
    @Repetir BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @UsuarioId AND activo = 1)
        BEGIN
            RAISERROR('Usuario no encontrado o inactivo', 16, 1);
            RETURN;
        END
        
        -- Validar que el tipo de transacción existe
        IF NOT EXISTS (SELECT 1 FROM tipos_transaccion WHERE id = @TipoTransaccionId AND activo = 1)
        BEGIN
            RAISERROR('Tipo de transacción no válido', 16, 1);
            RETURN;
        END
        
        -- Validar cuenta si se proporciona
        IF @CuentaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1)
            BEGIN
                RAISERROR('Cuenta no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar categoría si se proporciona
        IF @CategoriaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND (usuario_id IS NULL OR usuario_id = @UsuarioId) AND activo = 1)
            BEGIN
                RAISERROR('Categoría no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar método de pago si se proporciona
        IF @MetodoPagoId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM metodos_pago WHERE id = @MetodoPagoId AND activo = 1)
            BEGIN
                RAISERROR('Método de pago no válido', 16, 1);
                RETURN;
            END
        END
        
        -- Usar fecha actual si no se proporciona (con precisión), sin truncar
        IF @FechaTransaccion IS NULL
            SET @FechaTransaccion = GETDATE()
        
        -- Insertar la transacción
        INSERT INTO transacciones (
            usuario_id,
            cuenta_id,
            tipo_transaccion_id,
            categoria_id,
            metodo_pago_id,
            monto,
            moneda,
            titulo,
            descripcion,
            fecha_transaccion,
            archivo_adjunto,
            notas,
            repetir,
            activa,
            fecha_creacion
        )
        VALUES (
            @UsuarioId,
            @CuentaId,
            @TipoTransaccionId,
            @CategoriaId,
            @MetodoPagoId,
            @Monto,
            @Moneda,
            @Titulo,
            @Descripcion,
            @FechaTransaccion,
            @ArchivoAdjunto,
            @Notas,
            @Repetir,
            1,
            CAST(GETDATE() AS DATETIME2(0))
        )
        
        -- Retornar la transacción creada
        SELECT 
            t.id,
            t.usuario_id,
            t.cuenta_id,
            t.tipo_transaccion_id,
            tt.nombre AS tipo_nombre,
            t.categoria_id,
            c.nombre AS categoria_nombre,
            c.color AS categoria_color,
            c.icono AS categoria_icono,
            t.metodo_pago_id,
            mp.nombre AS metodo_pago_nombre,
            t.monto,
            t.moneda,
            t.titulo,
            t.descripcion,
            t.fecha_transaccion,
            t.archivo_adjunto,
            t.notas,
            t.repetir,
            t.activa,
            t.fecha_creacion
        FROM transacciones t
        LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
        LEFT JOIN categorias c ON t.categoria_id = c.id
        LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
        WHERE t.id = SCOPE_IDENTITY()
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Actualizar transacción
CREATE OR ALTER PROCEDURE sp_transaccion_update
    @Id BIGINT,
    @UsuarioId BIGINT,
    @CuentaId BIGINT = NULL,
    @TipoTransaccionId BIGINT = NULL,
    @CategoriaId BIGINT = NULL,
    @MetodoPagoId BIGINT = NULL,
    @Monto DECIMAL(18,2) = NULL,
    @Moneda NVARCHAR(10) = NULL,
    @Titulo NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @FechaTransaccion DATETIME2(0) = NULL,
    @ArchivoAdjunto NVARCHAR(500) = NULL,
    @Notas NVARCHAR(1000) = NULL,
    @Repetir BIT = NULL,
    @Activa BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la transacción existe y pertenece al usuario
        IF NOT EXISTS (SELECT 1 FROM transacciones WHERE id = @Id AND usuario_id = @UsuarioId AND activa = 1)
        BEGIN
            RAISERROR('Transacción no encontrada o no pertenece al usuario', 16, 1);
            RETURN;
        END
        
        -- Validar tipo de transacción si se proporciona
        IF @TipoTransaccionId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM tipos_transaccion WHERE id = @TipoTransaccionId AND activo = 1)
            BEGIN
                RAISERROR('Tipo de transacción no válido', 16, 1);
                RETURN;
            END
        END
        
        -- Validar cuenta si se proporciona
        IF @CuentaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1)
            BEGIN
                RAISERROR('Cuenta no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Validar categoría si se proporciona
        IF @CategoriaId IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM categorias WHERE id = @CategoriaId AND (usuario_id IS NULL OR usuario_id = @UsuarioId) AND activo = 1)
            BEGIN
                RAISERROR('Categoría no encontrada o no pertenece al usuario', 16, 1);
                RETURN;
            END
        END
        
        -- Actualizar solo los campos proporcionados
        UPDATE transacciones
        SET
            cuenta_id = ISNULL(@CuentaId, cuenta_id),
            tipo_transaccion_id = ISNULL(@TipoTransaccionId, tipo_transaccion_id),
            categoria_id = ISNULL(@CategoriaId, categoria_id),
            metodo_pago_id = ISNULL(@MetodoPagoId, metodo_pago_id),
            monto = ISNULL(@Monto, monto),
            moneda = ISNULL(@Moneda, moneda),
            titulo = ISNULL(@Titulo, titulo),
            descripcion = ISNULL(@Descripcion, descripcion),
            fecha_transaccion = ISNULL(CAST(@FechaTransaccion AS DATETIME2(0)), fecha_transaccion),
            archivo_adjunto = ISNULL(@ArchivoAdjunto, archivo_adjunto),
            notas = ISNULL(@Notas, notas),
            repetir = ISNULL(@Repetir, repetir),
            activa = ISNULL(@Activa, activa)
        WHERE id = @Id
        
        -- Retornar la transacción actualizada
        SELECT 
            t.id,
            t.usuario_id,
            t.cuenta_id,
            t.tipo_transaccion_id,
            tt.nombre AS tipo_nombre,
            t.categoria_id,
            c.nombre AS categoria_nombre,
            c.color AS categoria_color,
            c.icono AS categoria_icono,
            t.metodo_pago_id,
            mp.nombre AS metodo_pago_nombre,
            t.monto,
            t.moneda,
            t.titulo,
            t.descripcion,
            t.fecha_transaccion,
            t.archivo_adjunto,
            t.notas,
            t.repetir,
            t.activa,
            t.fecha_creacion
        FROM transacciones t
        LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
        LEFT JOIN categorias c ON t.categoria_id = c.id
        LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
        WHERE t.id = @Id
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Eliminar transacción (soft delete)
CREATE OR ALTER PROCEDURE sp_transaccion_delete
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la transacción existe y pertenece al usuario
        IF NOT EXISTS (SELECT 1 FROM transacciones WHERE id = @Id AND usuario_id = @UsuarioId)
        BEGIN
            RAISERROR('Transacción no encontrada o no pertenece al usuario', 16, 1);
            RETURN;
        END
        
        -- Soft delete
        UPDATE transacciones
        SET activa = 0
        WHERE id = @Id
        
        SELECT 1 AS success
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- SP: Obtener transacción por ID
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_id
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    WHERE t.id = @Id AND t.usuario_id = @UsuarioId AND t.activa = 1
END;
GO

-- SP: Obtener todas las transacciones del usuario
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_user
    @UsuarioId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por cuenta
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_account
    @UsuarioId BIGINT,
    @CuentaId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.cuenta_id = @CuentaId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por categoría
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_category
    @UsuarioId BIGINT,
    @CategoriaId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.categoria_id = @CategoriaId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Obtener transacciones por tipo (INGRESO/GASTO)
CREATE OR ALTER PROCEDURE sp_transaccion_get_by_type
    @UsuarioId BIGINT,
    @TipoTransaccionId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.id,
        t.usuario_id,
        t.cuenta_id,
        ct.nombre AS cuenta_nombre,
        t.tipo_transaccion_id,
        tt.nombre AS tipo_nombre,
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        t.metodo_pago_id,
        mp.nombre AS metodo_pago_nombre,
        t.monto,
        t.moneda,
        t.titulo,
        t.descripcion,
        t.fecha_transaccion,
        t.archivo_adjunto,
        t.notas,
        t.repetir,
        t.activa,
        t.fecha_creacion
    FROM transacciones t
    LEFT JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
    LEFT JOIN categorias c ON t.categoria_id = c.id
    LEFT JOIN metodos_pago mp ON t.metodo_pago_id = mp.id
    LEFT JOIN cuentas ct ON t.cuenta_id = ct.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.tipo_transaccion_id = @TipoTransaccionId
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    ORDER BY t.fecha_transaccion DESC
END;
GO

-- SP: Resumen de transacciones del usuario
CREATE OR ALTER PROCEDURE sp_transaccion_get_summary
    @UsuarioId BIGINT,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declarar variables para los tipos
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    -- Obtener IDs de tipos
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO' AND activo = 1;
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
    
    SELECT 
        -- Resumen general
        COUNT(*) AS total_transacciones,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END) AS total_ingresos,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END) AS total_gastos,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto ELSE 0 END) - 
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto ELSE 0 END) AS balance,
        -- Por categoría
        t.categoria_id,
        c.nombre AS categoria_nombre,
        c.color AS categoria_color,
        c.icono AS categoria_icono,
        COUNT(CASE WHEN t.categoria_id IS NOT NULL THEN 1 END) AS transacciones_categoria,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoIngresoId AND t.categoria_id IS NOT NULL THEN t.monto ELSE 0 END) AS ingresos_categoria,
        SUM(CASE WHEN t.tipo_transaccion_id = @TipoGastoId AND t.categoria_id IS NOT NULL THEN t.monto ELSE 0 END) AS gastos_categoria
    FROM transacciones t
    LEFT JOIN categorias c ON t.categoria_id = c.id
    WHERE t.usuario_id = @UsuarioId 
        AND t.activa = 1
        AND (@FechaInicio IS NULL OR t.fecha_transaccion >= @FechaInicio)
        AND (@FechaFin IS NULL OR t.fecha_transaccion <= @FechaFin)
    GROUP BY t.categoria_id, c.nombre, c.color, c.icono
    ORDER BY transacciones_categoria DESC
END;
GO

PRINT 'Procedimientos almacenados de transacciones creados exitosamente'
GO

