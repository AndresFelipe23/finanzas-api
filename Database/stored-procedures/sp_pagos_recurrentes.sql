-- =====================================================
-- STORED PROCEDURES - PAGOS RECURRENTES
-- Tabla base: pagos_recurrentes
-- =====================================================

-- Crear pago recurrente
CREATE OR ALTER PROCEDURE sp_pago_recurrente_create
    @UsuarioId       BIGINT,
    @CategoriaId     BIGINT,
    @CuentaId        BIGINT = NULL,
    @MetodoPagoId    BIGINT = NULL,
    @Monto           DECIMAL(18,2),
    @Descripcion     NVARCHAR(500),
    @Frecuencia      NVARCHAR(20), -- DIARIO, SEMANAL, MENSUAL, BIMESTRAL, TRIMESTRAL, SEMESTRAL, ANUAL
    @DiaVencimiento  INT = NULL,   -- 1..31 para mensual en adelante
    @DiaSemana       INT = NULL,   -- 1..7 (1=Lunes)
    @FechaInicio     DATETIME2,
    @FechaFin        DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pagos_recurrentes (
        usuario_id, categoria_id, cuenta_id, metodo_pago_id, monto, descripcion,
        frecuencia, dia_vencimiento, dia_semana, fecha_inicio, fecha_fin, activo, fecha_creacion
    )
    VALUES (
        @UsuarioId, @CategoriaId, @CuentaId, @MetodoPagoId, @Monto, @Descripcion,
        @Frecuencia, @DiaVencimiento, @DiaSemana, @FechaInicio, @FechaFin, 1, GETDATE()
    );

    SELECT *
    FROM pagos_recurrentes
    WHERE id = SCOPE_IDENTITY();
END;
GO

-- Actualizar pago recurrente
CREATE OR ALTER PROCEDURE sp_pago_recurrente_update
    @Id              BIGINT,
    @UsuarioId       BIGINT,
    @CategoriaId     BIGINT = NULL,
    @CuentaId        BIGINT = NULL,
    @MetodoPagoId    BIGINT = NULL,
    @Monto           DECIMAL(18,2) = NULL,
    @Descripcion     NVARCHAR(500) = NULL,
    @Frecuencia      NVARCHAR(20) = NULL,
    @DiaVencimiento  INT = NULL,
    @DiaSemana       INT = NULL,
    @FechaInicio     DATETIME2 = NULL,
    @FechaFin        DATETIME2 = NULL,
    @Activo          BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar pertenencia
    IF NOT EXISTS(SELECT 1 FROM pagos_recurrentes WHERE id=@Id AND usuario_id=@UsuarioId)
    BEGIN
        RAISERROR('Pago recurrente no encontrado', 16, 1);
        RETURN;
    END

    UPDATE pagos_recurrentes
    SET
        categoria_id    = ISNULL(@CategoriaId, categoria_id),
        cuenta_id       = ISNULL(@CuentaId, cuenta_id),
        metodo_pago_id  = ISNULL(@MetodoPagoId, metodo_pago_id),
        monto           = ISNULL(@Monto, monto),
        descripcion     = ISNULL(@Descripcion, descripcion),
        frecuencia      = ISNULL(@Frecuencia, frecuencia),
        dia_vencimiento = COALESCE(@DiaVencimiento, dia_vencimiento),
        dia_semana      = COALESCE(@DiaSemana, dia_semana),
        fecha_inicio    = ISNULL(@FechaInicio, fecha_inicio),
        fecha_fin       = COALESCE(@FechaFin, fecha_fin),
        activo          = ISNULL(@Activo, activo)
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT *
    FROM pagos_recurrentes
    WHERE id=@Id;
END;
GO

-- Activar / Desactivar
CREATE OR ALTER PROCEDURE sp_pago_recurrente_toggle
    @Id BIGINT,
    @UsuarioId BIGINT,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM pagos_recurrentes WHERE id=@Id AND usuario_id=@UsuarioId)
    BEGIN
        RAISERROR('Pago recurrente no encontrado', 16, 1);
        RETURN;
    END
    UPDATE pagos_recurrentes SET activo=@Activo WHERE id=@Id AND usuario_id=@UsuarioId;
    SELECT * FROM pagos_recurrentes WHERE id=@Id;
END;
GO

-- Eliminar (hard delete)
CREATE OR ALTER PROCEDURE sp_pago_recurrente_delete
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM pagos_recurrentes WHERE id=@Id AND usuario_id=@UsuarioId)
    BEGIN
        RAISERROR('Pago recurrente no encontrado', 16, 1);
        RETURN;
    END
    DELETE FROM pagos_recurrentes WHERE id=@Id AND usuario_id=@UsuarioId;
    SELECT 1 AS success;
END;
GO

-- Obtener por usuario
CREATE OR ALTER PROCEDURE sp_pago_recurrente_get_by_user
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pr.*, c.nombre AS categoria_nombre, ct.nombre AS cuenta_nombre, mp.nombre AS metodo_pago_nombre
    FROM pagos_recurrentes pr
    LEFT JOIN categorias c ON pr.categoria_id=c.id
    LEFT JOIN cuentas ct ON pr.cuenta_id=ct.id
    LEFT JOIN metodos_pago mp ON pr.metodo_pago_id=mp.id
    WHERE pr.usuario_id=@UsuarioId;
END;
GO

-- Obtener por id
CREATE OR ALTER PROCEDURE sp_pago_recurrente_get_by_id
    @Id BIGINT,
    @UsuarioId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pr.*, c.nombre AS categoria_nombre, ct.nombre AS cuenta_nombre, mp.nombre AS metodo_pago_nombre
    FROM pagos_recurrentes pr
    LEFT JOIN categorias c ON pr.categoria_id=c.id
    LEFT JOIN cuentas ct ON pr.cuenta_id=ct.id
    LEFT JOIN metodos_pago mp ON pr.metodo_pago_id=mp.id
    WHERE pr.id=@Id AND pr.usuario_id=@UsuarioId;
END;
GO

-- Ejecutar ahora un pago recurrente (crea transacción)
CREATE OR ALTER PROCEDURE sp_pago_recurrente_execute_now
    @Id BIGINT,
    @UsuarioId BIGINT,
    @FechaEjecucion DATETIME2(0) = NULL,
    @TipoTransaccionId BIGINT = NULL, -- si NULL, tomamos GASTO
    @Moneda NVARCHAR(10) = 'COP'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pr TABLE (
        id BIGINT, usuario_id BIGINT, categoria_id BIGINT, cuenta_id BIGINT, metodo_pago_id BIGINT,
        monto DECIMAL(18,2), descripcion NVARCHAR(500)
    );

    INSERT INTO @pr
    SELECT id, usuario_id, categoria_id, cuenta_id, metodo_pago_id, monto, descripcion
    FROM pagos_recurrentes
    WHERE id=@Id AND usuario_id=@UsuarioId AND activo=1;

    IF NOT EXISTS(SELECT 1 FROM @pr)
    BEGIN
        RAISERROR('Pago recurrente no encontrado o inactivo', 16, 1);
        RETURN;
    END

    IF @FechaEjecucion IS NULL SET @FechaEjecucion = CAST(GETDATE() AS DATETIME2(0));

    IF @TipoTransaccionId IS NULL
    BEGIN
        SELECT @TipoTransaccionId = id FROM tipos_transaccion WHERE nombre='GASTO' AND activo=1;
    END

    DECLARE @CuentaId BIGINT, @CategoriaId BIGINT, @MetodoPagoId BIGINT, @Monto DECIMAL(18,2), @Descripcion NVARCHAR(500);
    SELECT @CuentaId=cuenta_id, @CategoriaId=categoria_id, @MetodoPagoId=metodo_pago_id, @Monto=monto, @Descripcion=descripcion FROM @pr;

    -- Crear transacción usando SP existente
    EXEC sp_transaccion_create
        @UsuarioId=@UsuarioId,
        @CuentaId=@CuentaId,
        @TipoTransaccionId=@TipoTransaccionId,
        @CategoriaId=@CategoriaId,
        @MetodoPagoId=@MetodoPagoId,
        @Monto=@Monto,
        @Moneda=@Moneda,
        @Titulo=NULL,
        @Descripcion=@Descripcion,
        @FechaTransaccion=@FechaEjecucion,
        @ArchivoAdjunto=NULL,
        @Notas=NULL,
        @Repetir=1; -- marcar como transacción recurrente
END;
GO

PRINT 'Stored procedures de pagos recurrentes creados/actualizados'
GO


