-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS PARA CUENTAS
-- SQL Server Stored Procedures for Accounts
-- =====================================================

USE FinanzasApiApp
GO

-- =====================================================
-- Crear Cuenta (sp_cuenta_create)
-- Crea una nueva cuenta para un usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_create
    @UsuarioId BIGINT,
    @Nombre NVARCHAR(100),
    @Tipo NVARCHAR(30) = 'BANCARIA',
    @Moneda NVARCHAR(10) = 'COP',
    @SaldoInicial DECIMAL(18,2) = 0,
    @Color NVARCHAR(7) = NULL,
    @Icono NVARCHAR(50) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @CuentaId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar el tipo
    IF @Tipo NOT IN ('BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION')
    BEGIN
        RAISERROR('El tipo de cuenta no es válido', 16, 1);
        RETURN;
    END
    
    -- Verificar si ya existe una cuenta con este nombre para este usuario
    IF EXISTS (SELECT 1 FROM cuentas WHERE usuario_id = @UsuarioId AND nombre = @Nombre AND activa = 1)
    BEGIN
        RAISERROR('Ya existe una cuenta con este nombre', 16, 1);
        RETURN;
    END
    
    -- Insertar la nueva cuenta
    INSERT INTO cuentas (
        usuario_id,
        nombre,
        tipo,
        moneda,
        saldo_inicial,
        color,
        icono,
        descripcion,
        activa,
        fecha_creacion
    )
    VALUES (
        @UsuarioId,
        @Nombre,
        @Tipo,
        @Moneda,
        @SaldoInicial,
        @Color,
        @Icono,
        @Descripcion,
        1,
        GETDATE()
    );
    
    SET @CuentaId = SCOPE_IDENTITY();
    
    -- Retornar la cuenta creada
    SELECT 
        id,
        usuario_id,
        nombre,
        tipo,
        moneda,
        saldo_inicial,
        color,
        icono,
        descripcion,
        activa,
        fecha_creacion
    FROM cuentas
    WHERE id = @CuentaId;
END;
GO

-- =====================================================
-- Obtener Cuentas del Usuario (sp_cuenta_get_by_user)
-- Obtiene todas las cuentas activas de un usuario
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_by_user
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.id,
        c.usuario_id,
        c.nombre,
        c.tipo,
        c.moneda,
        c.saldo_inicial,
        c.color,
        c.icono,
        c.descripcion,
        c.activa,
        c.fecha_creacion,
        -- Calcular saldo actual
        c.saldo_inicial + ISNULL(
            SUM(CASE 
                WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
                WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
                ELSE 0
            END),
            0
        ) AS saldo_actual
    FROM cuentas c
    LEFT JOIN transacciones t ON c.id = t.cuenta_id 
        AND t.usuario_id = @UsuarioId 
        AND t.activa = 1
    WHERE c.usuario_id = @UsuarioId 
        AND c.activa = 1
    GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
             c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion
    ORDER BY c.nombre;
END;
GO

-- =====================================================
-- Obtener Cuenta por ID (sp_cuenta_get_by_id)
-- Obtiene una cuenta específica con su saldo actual
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_by_id
    @CuentaId BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que la cuenta existe y pertenece al usuario
    IF NOT EXISTS (
        SELECT 1 
        FROM cuentas 
        WHERE id = @CuentaId 
            AND usuario_id = @UsuarioId 
            AND activa = 1
    )
    BEGIN
        RAISERROR('Cuenta no encontrada', 16, 1);
        RETURN;
    END
    
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.id,
        c.usuario_id,
        c.nombre,
        c.tipo,
        c.moneda,
        c.saldo_inicial,
        c.color,
        c.icono,
        c.descripcion,
        c.activa,
        c.fecha_creacion,
        -- Calcular saldo actual
        c.saldo_inicial + ISNULL(
            SUM(CASE 
                WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
                WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
                ELSE 0
            END),
            0
        ) AS saldo_actual
    FROM cuentas c
    LEFT JOIN transacciones t ON c.id = t.cuenta_id 
        AND t.usuario_id = @UsuarioId 
        AND t.activa = 1
    WHERE c.id = @CuentaId
        AND c.usuario_id = @UsuarioId
        AND c.activa = 1
    GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
             c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion;
END;
GO

-- =====================================================
-- Actualizar Cuenta (sp_cuenta_update)
-- Actualiza los datos de una cuenta
-- No permite modificar si tiene transacciones asociadas
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_update
    @CuentaId BIGINT,
    @UsuarioId BIGINT,
    @Nombre NVARCHAR(100) = NULL,
    @Tipo NVARCHAR(30) = NULL,
    @Moneda NVARCHAR(10) = NULL,
    @SaldoInicial DECIMAL(18,2) = NULL,
    @Color NVARCHAR(7) = NULL,
    @Icono NVARCHAR(50) = NULL,
    @Descripcion NVARCHAR(500) = NULL,
    @Activa BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que la cuenta existe y pertenece al usuario
    IF NOT EXISTS (
        SELECT 1 
        FROM cuentas 
        WHERE id = @CuentaId 
            AND usuario_id = @UsuarioId 
            AND activa = 1
    )
    BEGIN
        RAISERROR('Cuenta no encontrada', 16, 1);
        RETURN;
    END
    
    -- Validar tipo si se proporciona
    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION')
    BEGIN
        RAISERROR('El tipo de cuenta no es válido', 16, 1);
        RETURN;
    END
    
    -- Actualizar solo los campos proporcionados
    UPDATE cuentas
    SET 
        nombre = ISNULL(@Nombre, nombre),
        tipo = ISNULL(@Tipo, tipo),
        moneda = ISNULL(@Moneda, moneda),
        saldo_inicial = ISNULL(@SaldoInicial, saldo_inicial),
        color = ISNULL(@Color, color),
        icono = ISNULL(@Icono, icono),
        descripcion = ISNULL(@Descripcion, descripcion),
        activa = ISNULL(@Activa, activa)
    WHERE id = @CuentaId;
    
    -- Retornar la cuenta actualizada con saldo
    EXEC sp_cuenta_get_by_id @CuentaId = @CuentaId, @UsuarioId = @UsuarioId;
END;
GO

-- =====================================================
-- Eliminar Cuenta (sp_cuenta_delete)
-- Elimina físicamente una cuenta de la base de datos
-- No se pueden eliminar si tienen transacciones asociadas
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_delete
    @CuentaId BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar que la cuenta existe
    IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId)
    BEGIN
        RAISERROR('La cuenta no existe', 16, 1);
        RETURN;
    END
    
    -- Validar que la cuenta pertenece al usuario
    IF NOT EXISTS (SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId)
    BEGIN
        RAISERROR('La cuenta no pertenece a este usuario', 16, 1);
        RETURN;
    END
    
    -- Verificar si la cuenta tiene transacciones asociadas
    IF EXISTS (SELECT 1 FROM transacciones WHERE cuenta_id = @CuentaId AND activa = 1)
    BEGIN
        DECLARE @TransaccionesCount INT;
        SELECT @TransaccionesCount = COUNT(*) 
        FROM transacciones 
        WHERE cuenta_id = @CuentaId AND activa = 1;
        
        RAISERROR('No se puede eliminar la cuenta porque tiene %d transacción(es) asociada(s)', 16, 1, @TransaccionesCount);
        RETURN;
    END
    
    -- Obtener saldo inicial
    DECLARE @SaldoInicial DECIMAL(18,2);
    SELECT @SaldoInicial = saldo_inicial FROM cuentas WHERE id = @CuentaId;
    
    -- Calcular movimientos
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    DECLARE @Movimientos DECIMAL(18,2);
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT @Movimientos = ISNULL(
        SUM(CASE 
            WHEN tipo_transaccion_id = @TipoIngresoId THEN monto
            WHEN tipo_transaccion_id = @TipoGastoId THEN -monto
            ELSE 0
        END),
        0
    )
    FROM transacciones
    WHERE cuenta_id = @CuentaId 
        AND usuario_id = @UsuarioId
        AND activa = 1;
    
    DECLARE @SaldoActual DECIMAL(18,2) = @SaldoInicial + ISNULL(@Movimientos, 0);
    
    IF @SaldoActual != 0
    BEGIN
        RAISERROR('No se puede eliminar la cuenta porque tiene saldo', 16, 1);
        RETURN;
    END
    
    -- Eliminación física de la base de datos
    DELETE FROM cuentas
    WHERE id = @CuentaId;
    
    SELECT 1 AS eliminado;
END;
GO

-- =====================================================
-- Obtener Saldo de Cuenta (sp_cuenta_get_saldo)
-- Obtiene el saldo actual de una cuenta
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_saldo
    @CuentaId BIGINT,
    @UsuarioId BIGINT,
    @Saldo DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SaldoInicial DECIMAL(18,2);
    DECLARE @Movimientos DECIMAL(18,2);
    
    -- Obtener saldo inicial
    SELECT @SaldoInicial = saldo_inicial
    FROM cuentas
    WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1;
    
    IF @SaldoInicial IS NULL
    BEGIN
        RAISERROR('Cuenta no encontrada', 16, 1);
        RETURN;
    END
    
    -- Calcular movimientos
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT @Movimientos = ISNULL(
        SUM(CASE 
            WHEN tipo_transaccion_id = @TipoIngresoId THEN monto
            WHEN tipo_transaccion_id = @TipoGastoId THEN -monto
            ELSE 0
        END),
        0
    )
    FROM transacciones
    WHERE cuenta_id = @CuentaId 
        AND usuario_id = @UsuarioId
        AND activa = 1;
    
    SET @Saldo = @SaldoInicial + ISNULL(@Movimientos, 0);
END;
GO

-- =====================================================
-- Obtener Resumen de Cuentas (sp_cuenta_get_summary)
-- Obtiene estadísticas de uso de cuentas
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_summary
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.id,
        c.nombre,
        c.tipo,
        c.moneda,
        c.saldo_inicial,
        c.color,
        c.icono,
        COUNT(t.id) AS total_transacciones,
        -- Saldo actual
        c.saldo_inicial + ISNULL(
            SUM(CASE 
                WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
                WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
                ELSE 0
            END),
            0
        ) AS saldo_actual,
        -- Total de ingresos
        ISNULL(SUM(CASE 
            WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
            ELSE 0
        END), 0) AS total_ingresos,
        -- Total de gastos
        ISNULL(SUM(CASE 
            WHEN t.tipo_transaccion_id = @TipoGastoId THEN t.monto
            ELSE 0
        END), 0) AS total_gastos
    FROM cuentas c
    LEFT JOIN transacciones t ON c.id = t.cuenta_id 
        AND t.usuario_id = @UsuarioId 
        AND t.activa = 1
    WHERE c.usuario_id = @UsuarioId 
        AND c.activa = 1
    GROUP BY c.id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, c.color, c.icono
    ORDER BY saldo_actual DESC, c.nombre;
END;
GO

-- =====================================================
-- Obtener Cuentas por Tipo (sp_cuenta_get_by_type)
-- Obtiene cuentas de un usuario filtradas por tipo
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_by_type
    @UsuarioId BIGINT,
    @Tipo NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar el tipo
    IF @Tipo NOT IN ('BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION')
    BEGIN
        RAISERROR('El tipo de cuenta no es válido', 16, 1);
        RETURN;
    END
    
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.id,
        c.usuario_id,
        c.nombre,
        c.tipo,
        c.moneda,
        c.saldo_inicial,
        c.color,
        c.icono,
        c.descripcion,
        c.activa,
        c.fecha_creacion,
        -- Calcular saldo actual
        c.saldo_inicial + ISNULL(
            SUM(CASE 
                WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
                WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
                ELSE 0
            END),
            0
        ) AS saldo_actual
    FROM cuentas c
    LEFT JOIN transacciones t ON c.id = t.cuenta_id 
        AND t.usuario_id = @UsuarioId 
        AND t.activa = 1
    WHERE c.usuario_id = @UsuarioId 
        AND c.tipo = @Tipo
        AND c.activa = 1
    GROUP BY c.id, c.usuario_id, c.nombre, c.tipo, c.moneda, c.saldo_inicial, 
             c.color, c.icono, c.descripcion, c.activa, c.fecha_creacion
    ORDER BY c.nombre;
END;
GO

-- =====================================================
-- Verificar si Cuenta es Usable (sp_cuenta_check_usage)
-- Verifica si una cuenta puede ser eliminada
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_check_usage
    @CuentaId BIGINT,
    @UsuarioId BIGINT,
    @TieneTransacciones BIT OUTPUT,
    @TieneSaldo BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si hay transacciones con esta cuenta
    IF EXISTS (SELECT 1 FROM transacciones WHERE cuenta_id = @CuentaId AND activa = 1)
    BEGIN
        SET @TieneTransacciones = 1;
    END
    ELSE
    BEGIN
        SET @TieneTransacciones = 0;
    END
    
    -- Verificar si tiene saldo
    DECLARE @SaldoActual DECIMAL(18,2);
    EXEC sp_cuenta_get_saldo @CuentaId = @CuentaId, @UsuarioId = @UsuarioId, @Saldo = @SaldoActual OUTPUT;
    
    IF @SaldoActual != 0
    BEGIN
        SET @TieneSaldo = 1;
    END
    ELSE
    BEGIN
        SET @TieneSaldo = 0;
    END
END;
GO

-- =====================================================
-- Obtener Total de Cuentas por Moneda (sp_cuenta_get_by_moneda)
-- Obtiene el total de todas las cuentas agrupadas por moneda
-- =====================================================
CREATE OR ALTER PROCEDURE sp_cuenta_get_by_moneda
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TipoIngresoId BIGINT;
    DECLARE @TipoGastoId BIGINT;
    
    SELECT @TipoIngresoId = id FROM tipos_transaccion WHERE nombre = 'INGRESO';
    SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO';
    
    SELECT 
        c.moneda,
        COUNT(c.id) AS total_cuentas,
        SUM(c.saldo_inicial) + ISNULL(
            SUM(CASE 
                WHEN t.tipo_transaccion_id = @TipoIngresoId THEN t.monto
                WHEN t.tipo_transaccion_id = @TipoGastoId THEN -t.monto
                ELSE 0
            END),
            0
        ) AS saldo_total
    FROM cuentas c
    LEFT JOIN transacciones t ON c.id = t.cuenta_id 
        AND t.usuario_id = @UsuarioId
        AND t.activa = 1
    WHERE c.usuario_id = @UsuarioId 
        AND c.activa = 1
    GROUP BY c.moneda
    ORDER BY moneda;
END;
GO

-- =====================================================
-- FIN DE PROCEDIMIENTOS ALMACENADOS PARA CUENTAS
-- =====================================================

PRINT 'Procedimientos almacenados de cuentas creados exitosamente';
GO

