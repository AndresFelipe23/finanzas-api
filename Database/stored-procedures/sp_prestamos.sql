/*
  Stored Procedures para Gestionar Prestamos y Pagos de Prestamos
  Tablas: prestamos, pagos_prestamos
  Notas:
  - Maneja fechas con DATETIME2(0)
  - Asegura actualizacion de saldo_pendiente al crear/actualizar/eliminar pagos
  - Reenvía errores capturados con THROW para preservar el mensaje original
*/

/* Crear tablas si no existen */
IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[prestamos]') AND type in (N'U')
)
BEGIN
  CREATE TABLE dbo.prestamos (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id       BIGINT        NOT NULL,
    cuenta_id        BIGINT        NULL, -- Cuenta relacionada (opcional)
    nombre           NVARCHAR(200) NOT NULL,
    tipo             NVARCHAR(20)  NOT NULL, -- 'PRESTAMO' (yo presto) | 'DEUDA' (yo debo)
    monto_total      DECIMAL(18,2) NOT NULL,
    saldo_pendiente  DECIMAL(18,2) NOT NULL,
    tasa_interes     DECIMAL(9,4)  NULL, -- anual en porcentaje opcional
    fecha_inicio     DATETIME2(0)  NOT NULL,
    fecha_fin        DATETIME2(0)  NULL,
    notas            NVARCHAR(1000) NULL,
    activa           BIT           NOT NULL DEFAULT 1,
    fecha_creacion   DATETIME2(0)  NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    fecha_actualizacion DATETIME2(0) NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    CONSTRAINT CK_prestamos_tipo CHECK (tipo IN ('PRESTAMO','DEUDA'))
  );
END;

/* Asegurar columnas requeridas en prestamos */
IF COL_LENGTH('dbo.prestamos', 'cuenta_id') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD cuenta_id BIGINT NULL;
END;
IF COL_LENGTH('dbo.prestamos', 'nombre') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD nombre NVARCHAR(200) NOT NULL CONSTRAINT DF_prestamos_nombre DEFAULT('');
END;
IF COL_LENGTH('dbo.prestamos', 'tipo') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD tipo NVARCHAR(20) NOT NULL CONSTRAINT DF_prestamos_tipo DEFAULT('DEUDA');
END;

/* Eliminar CHECK constraints antiguos en tipo y crear uno nuevo */
DECLARE @ConstraintName NVARCHAR(200);
DECLARE constraint_cursor CURSOR FOR
  SELECT OBJECT_NAME(object_id)
  FROM sys.check_constraints
  WHERE parent_object_id = OBJECT_ID('dbo.prestamos')
    AND COL_NAME(parent_object_id, parent_column_id) = 'tipo'
    AND OBJECT_NAME(object_id) <> 'CK_prestamos_tipo';

OPEN constraint_cursor;
FETCH NEXT FROM constraint_cursor INTO @ConstraintName;

WHILE @@FETCH_STATUS = 0
BEGIN
  DECLARE @SQL NVARCHAR(500) = 'ALTER TABLE dbo.prestamos DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
  EXEC sp_executesql @SQL;
  FETCH NEXT FROM constraint_cursor INTO @ConstraintName;
END;

CLOSE constraint_cursor;
DEALLOCATE constraint_cursor;

/* Crear el constraint correcto si no existe */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_prestamos_tipo' AND parent_object_id = OBJECT_ID('dbo.prestamos'))
BEGIN
  ALTER TABLE dbo.prestamos ADD CONSTRAINT CK_prestamos_tipo CHECK (tipo IN ('PRESTAMO','DEUDA'));
END;
IF COL_LENGTH('dbo.prestamos', 'monto_total') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD monto_total DECIMAL(18,2) NOT NULL CONSTRAINT DF_prestamos_monto_total DEFAULT(0);
END;
IF COL_LENGTH('dbo.prestamos', 'monto_pagado') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD monto_pagado DECIMAL(18,2) NOT NULL CONSTRAINT DF_prestamos_monto_pagado DEFAULT(0);
END;
IF COL_LENGTH('dbo.prestamos', 'monto_pendiente') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD monto_pendiente AS (monto_total - monto_pagado) PERSISTED;
END;
IF COL_LENGTH('dbo.prestamos', 'saldo_pendiente') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD saldo_pendiente DECIMAL(18,2) NOT NULL CONSTRAINT DF_prestamos_saldo_pendiente DEFAULT(0);
END;
IF COL_LENGTH('dbo.prestamos', 'estado') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD estado NVARCHAR(20) NOT NULL CONSTRAINT DF_prestamos_estado DEFAULT('PENDIENTE');
  ALTER TABLE dbo.prestamos ADD CONSTRAINT CK_prestamos_estado CHECK (estado IN ('PENDIENTE', 'PAGADO', 'CANCELADO'));
END;
IF COL_LENGTH('dbo.prestamos', 'tasa_interes') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD tasa_interes DECIMAL(9,4) NULL;
END;
IF COL_LENGTH('dbo.prestamos', 'fecha_inicio') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD fecha_inicio DATETIME2(0) NOT NULL CONSTRAINT DF_prestamos_fecha_inicio DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;
IF COL_LENGTH('dbo.prestamos', 'fecha_fin') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD fecha_fin DATETIME2(0) NULL;
END;
IF COL_LENGTH('dbo.prestamos', 'notas') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD notas NVARCHAR(1000) NULL;
END;
IF COL_LENGTH('dbo.prestamos', 'activa') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD activa BIT NOT NULL CONSTRAINT DF_prestamos_activa DEFAULT(1);
END;
IF COL_LENGTH('dbo.prestamos', 'fecha_creacion') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_prestamos_fecha_creacion DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;
IF COL_LENGTH('dbo.prestamos', 'fecha_actualizacion') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD fecha_actualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_prestamos_fecha_actualizacion DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pagos_prestamos]') AND type in (N'U')
)
BEGIN
  CREATE TABLE dbo.pagos_prestamos (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    prestamo_id    BIGINT        NOT NULL,
    cuenta_id      BIGINT        NULL,
    monto          DECIMAL(18,2) NOT NULL,
    fecha_pago     DATETIME2(0)  NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    notas          NVARCHAR(500) NULL,
    fecha_creacion DATETIME2(0)  NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    CONSTRAINT FK_pagos_prestamos_prestamo FOREIGN KEY (prestamo_id) REFERENCES dbo.prestamos(id) ON DELETE CASCADE
  );
END;

/* Asegurar columnas requeridas en pagos_prestamos */
IF COL_LENGTH('dbo.pagos_prestamos', 'prestamo_id') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD prestamo_id BIGINT NOT NULL;
END;
IF COL_LENGTH('dbo.pagos_prestamos', 'cuenta_id') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD cuenta_id BIGINT NULL;
END;
IF COL_LENGTH('dbo.pagos_prestamos', 'monto') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD monto DECIMAL(18,2) NOT NULL CONSTRAINT DF_pagos_prestamos_monto DEFAULT(0);
END;
IF COL_LENGTH('dbo.pagos_prestamos', 'fecha_pago') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD fecha_pago DATETIME2(0) NOT NULL CONSTRAINT DF_pagos_prestamos_fecha_pago DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;
IF COL_LENGTH('dbo.pagos_prestamos', 'notas') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD notas NVARCHAR(500) NULL;
END;
IF COL_LENGTH('dbo.pagos_prestamos', 'fecha_creacion') IS NULL
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_pagos_prestamos_fecha_creacion DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;

GO

/* ========================= PRESTAMOS ========================= */
CREATE OR ALTER PROCEDURE sp_prestamo_create
  @UsuarioId      BIGINT,
  @Nombre         NVARCHAR(200),
  @Tipo           NVARCHAR(20), -- 'PRESTAMO' | 'DEUDA'
  @MontoTotal     DECIMAL(18,2),
  @TasaInteres    DECIMAL(9,4) = NULL,
  @FechaInicio    DATETIME2 = NULL,
  @FechaFin       DATETIME2 = NULL,
  @CuentaId       BIGINT = NULL,
  @Notas          NVARCHAR(1000) = NULL,
  @NombreDeudorPrestador NVARCHAR(200) = NULL,
  @RegistrarMovimiento BIT = 0,
  -- Monto del movimiento inicial si no es @MontoTotal: en un crédito en
  -- cuotas @MontoTotal incluye intereses y el movimiento es lo prestado
  @MontoMovimiento DECIMAL(18,2) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0)
      RAISERROR('Usuario inválido', 16, 1);
    IF (@Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = '')
      RAISERROR('El nombre es requerido', 16, 1);
    IF (@Tipo NOT IN ('PRESTAMO','DEUDA'))
      RAISERROR('Tipo inválido. Debe ser PRESTAMO o DEUDA', 16, 1);
    IF (@MontoTotal IS NULL OR @MontoTotal <= 0)
      RAISERROR('El monto total debe ser mayor a 0', 16, 1);

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());
    
    SET @FechaInicio = CAST(ISNULL(@FechaInicio, @FechaHoraLocal) AS DATETIME2(0));
    IF (@FechaFin IS NOT NULL)
      SET @FechaFin = CAST(@FechaFin AS DATETIME2(0));

    DECLARE @NombrePersona NVARCHAR(200) = COALESCE(NULLIF(LTRIM(RTRIM(@NombreDeudorPrestador)), ''), @Nombre);
    DECLARE @FechaPrestamo DATETIME2(0) = @FechaInicio;

    DECLARE @FechaCreacion DATETIME2(0) = CAST(@FechaHoraLocal AS DATETIME2(0));
    DECLARE @MontoPagado DECIMAL(18,2) = 0;
    DECLARE @SaldoPendiente DECIMAL(18,2) = @MontoTotal;
    DECLARE @Estado NVARCHAR(20) = 'PENDIENTE';

    IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NOT NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NOT NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, monto_pagado, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, estado, fecha_creacion, fecha_actualizacion,
        nombre_deudor_prestador, fecha_prestamo
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoPagado, @SaldoPendiente,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, @Estado, @FechaCreacion, @FechaCreacion,
        @NombrePersona, @FechaPrestamo
      );
    END
    ELSE IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NOT NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, monto_pagado, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, estado, fecha_creacion, fecha_actualizacion,
        nombre_deudor_prestador
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoPagado, @SaldoPendiente,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, @Estado, @FechaCreacion, @FechaCreacion,
        @NombrePersona
      );
    END
    ELSE IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NOT NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, monto_pagado, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, estado, fecha_creacion, fecha_actualizacion,
        fecha_prestamo
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoPagado, @SaldoPendiente,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, @Estado, @FechaCreacion, @FechaCreacion,
        @FechaPrestamo
      );
    END
    ELSE
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, monto_pagado, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, estado, fecha_creacion, fecha_actualizacion
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoPagado, @SaldoPendiente,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, @Estado, @FechaCreacion, @FechaCreacion
      );
    END

    DECLARE @NewId BIGINT = SCOPE_IDENTITY();

    /*
      Movimiento real. Pedir prestado (DEUDA) es dinero que ENTRA;
      prestar (PRESTAMO) es dinero que SALE. Solo si el usuario lo pide
      explicitamente: registrar una deuda vieja no debe inflar el saldo de hoy.
    */
    IF (@RegistrarMovimiento = 1 AND @CuentaId IS NOT NULL
        AND COL_LENGTH('dbo.prestamos','transaccion_id') IS NOT NULL)
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM dbo.cuentas WHERE id=@CuentaId AND usuario_id=@UsuarioId AND activa=1)
        RAISERROR('Cuenta no encontrada o inactiva', 16, 1);

      DECLARE @TipoMovId BIGINT;
      DECLARE @CategoriaId BIGINT;
      DECLARE @MonedaCuenta NVARCHAR(10);

      SELECT @TipoMovId = id FROM dbo.tipos_transaccion
      WHERE nombre = CASE WHEN @Tipo = 'DEUDA' THEN 'INGRESO' ELSE 'GASTO' END AND activo = 1;

      SELECT @CategoriaId = id FROM dbo.categorias
      WHERE usuario_id IS NULL AND nombre = 'Préstamos y deudas';

      SELECT @MonedaCuenta = moneda FROM dbo.cuentas WHERE id = @CuentaId;

      IF @TipoMovId IS NULL
        RAISERROR('No existe el tipo de transaccion requerido', 16, 1);

      INSERT INTO dbo.transacciones (
        usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
        monto, moneda, titulo, descripcion, fecha_transaccion,
        archivo_adjunto, notas, repetir, activa, fecha_creacion
      )
      VALUES (
        @UsuarioId, @CuentaId, @TipoMovId, @CategoriaId, NULL,
        COALESCE(@MontoMovimiento, @MontoTotal), COALESCE(@MonedaCuenta, 'COP'),
        CASE WHEN @Tipo = 'DEUDA' THEN 'Préstamo recibido: ' ELSE 'Préstamo entregado: ' END + @Nombre,
        NULL, @FechaInicio,
        NULL, @Notas, 0, 1, @FechaCreacion
      );

      DECLARE @TransaccionId BIGINT = SCOPE_IDENTITY();

      UPDATE dbo.prestamos SET transaccion_id = @TransaccionId WHERE id = @NewId;

      IF (@Tipo = 'PRESTAMO')
        EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;
    END

    SELECT * FROM dbo.prestamos WHERE id = @NewId AND usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_update
  @Id             BIGINT,
  @UsuarioId      BIGINT,
  @Nombre         NVARCHAR(200) = NULL,
  @Tipo           NVARCHAR(20)  = NULL,
  @MontoTotal     DECIMAL(18,2) = NULL,
  @TasaInteres    DECIMAL(9,4)  = NULL,
  @FechaInicio    DATETIME2     = NULL,
  @FechaFin       DATETIME2     = NULL,
  @CuentaId       BIGINT        = NULL,
  @Notas          NVARCHAR(1000)= NULL,
  @Activa         BIT           = NULL,
  @NombreDeudorPrestador NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Id IS NULL OR @Id <= 0) RAISERROR('Id inválido',16,1);
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido',16,1);

    DECLARE @Exists INT = (SELECT COUNT(1) FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId);
    IF (@Exists = 0) RAISERROR('Préstamo no encontrado',16,1);

    -- Bajar el total por debajo de lo ya pagado dejaria saldos negativos
    IF (@MontoTotal IS NOT NULL)
    BEGIN
      IF (@MontoTotal <= 0)
        RAISERROR('El monto total debe ser mayor a 0',16,1);

      DECLARE @PagadoReal DECIMAL(18,2) = (
        SELECT ISNULL(SUM(COALESCE(monto, monto_pago)), 0)
        FROM dbo.pagos_prestamos WHERE prestamo_id = @Id
      );

      IF (@MontoTotal < @PagadoReal)
      BEGIN
        DECLARE @MsgMenor NVARCHAR(200) =
          'El monto total no puede ser menor a lo ya pagado (' +
          CONVERT(NVARCHAR(30), @PagadoReal) + ')';
        RAISERROR(@MsgMenor,16,1);
      END
    END

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NOT NULL
    BEGIN
      UPDATE dbo.prestamos
      SET
        nombre = COALESCE(NULLIF(LTRIM(RTRIM(@Nombre)), ''), nombre),
        tipo = CASE WHEN @Tipo IN ('PRESTAMO','DEUDA') THEN @Tipo ELSE tipo END,
        monto_total = COALESCE(@MontoTotal, monto_total),
        tasa_interes = COALESCE(@TasaInteres, tasa_interes),
        fecha_inicio = COALESCE(CAST(@FechaInicio AS DATETIME2(0)), fecha_inicio),
        fecha_fin = COALESCE(CAST(@FechaFin AS DATETIME2(0)), fecha_fin),
        cuenta_id = COALESCE(@CuentaId, cuenta_id),
        notas = COALESCE(@Notas, notas),
        activa = COALESCE(@Activa, activa),
        nombre_deudor_prestador = COALESCE(NULLIF(LTRIM(RTRIM(@NombreDeudorPrestador)), ''), nombre_deudor_prestador),
        fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
      WHERE id=@Id AND usuario_id=@UsuarioId;
    END
    ELSE
    BEGIN
      UPDATE dbo.prestamos
      SET
        nombre = COALESCE(NULLIF(LTRIM(RTRIM(@Nombre)), ''), nombre),
        tipo = CASE WHEN @Tipo IN ('PRESTAMO','DEUDA') THEN @Tipo ELSE tipo END,
        monto_total = COALESCE(@MontoTotal, monto_total),
        tasa_interes = COALESCE(@TasaInteres, tasa_interes),
        fecha_inicio = COALESCE(CAST(@FechaInicio AS DATETIME2(0)), fecha_inicio),
        fecha_fin = COALESCE(CAST(@FechaFin AS DATETIME2(0)), fecha_fin),
        cuenta_id = COALESCE(@CuentaId, cuenta_id),
        notas = COALESCE(@Notas, notas),
        activa = COALESCE(@Activa, activa),
        fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
      WHERE id=@Id AND usuario_id=@UsuarioId;
    END

    -- Cambiar monto_total desfasa monto_pagado y saldo_pendiente
    IF (@MontoTotal IS NOT NULL)
    BEGIN
      EXEC sp_prestamo_recalcular @PrestamoId = @Id;

      -- El movimiento creado al abrir el prestamo debe seguir el nuevo monto
      IF COL_LENGTH('dbo.prestamos','transaccion_id') IS NOT NULL
      BEGIN
        DECLARE @TxPrestamo BIGINT = (SELECT transaccion_id FROM dbo.prestamos WHERE id=@Id);
        IF (@TxPrestamo IS NOT NULL)
        BEGIN
          UPDATE dbo.transacciones
          SET monto = @MontoTotal
          WHERE id = @TxPrestamo AND usuario_id = @UsuarioId;

          EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;
        END
      END
    END

    SELECT * FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_toggle_activo
  @Id        BIGINT,
  @UsuarioId BIGINT,
  @Activa    BIT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Id IS NULL OR @Id <= 0) RAISERROR('Id inválido',16,1);
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido',16,1);

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    UPDATE dbo.prestamos
    SET activa = @Activa, fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_delete
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Id IS NULL OR @Id <= 0) RAISERROR('Id inválido',16,1);
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido',16,1);

    IF NOT EXISTS (SELECT 1 FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId)
      RAISERROR('Préstamo no encontrado',16,1);

    -- Recoger los movimientos generados por el prestamo y sus pagos
    DECLARE @Transacciones TABLE (transaccion_id BIGINT);

    IF COL_LENGTH('dbo.pagos_prestamos','transaccion_id') IS NOT NULL
      INSERT INTO @Transacciones (transaccion_id)
      SELECT transaccion_id FROM dbo.pagos_prestamos
      WHERE prestamo_id = @Id AND transaccion_id IS NOT NULL;

    IF COL_LENGTH('dbo.prestamos','transaccion_id') IS NOT NULL
      INSERT INTO @Transacciones (transaccion_id)
      SELECT transaccion_id FROM dbo.prestamos
      WHERE id = @Id AND transaccion_id IS NOT NULL;

    BEGIN TRAN;

      DELETE FROM dbo.pagos_prestamos WHERE prestamo_id=@Id;
      DELETE FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;

      DELETE FROM dbo.transacciones
      WHERE usuario_id = @UsuarioId
        AND id IN (SELECT transaccion_id FROM @Transacciones);

    COMMIT TRAN;

    IF EXISTS (SELECT 1 FROM @Transacciones)
      EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_get_by_id
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT * FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

/*
  Recalcula el gasto de los presupuestos vigentes del usuario.
  presupuestos.monto_gastado es una columna almacenada derivada de transacciones:
  si un prestamo o un pago crea o borra un GASTO, queda obsoleta.
*/
CREATE OR ALTER PROCEDURE sp_prestamo_recalcular_presupuestos
  @UsuarioId BIGINT,
  @Fecha     DATETIME2(7) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @FechaRef DATETIME2(7) = COALESCE(@Fecha, DATEADD(HOUR, -5, GETUTCDATE()));
  DECLARE @PresupuestoId BIGINT;

  DECLARE presupuestos_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id
    FROM dbo.presupuestos
    WHERE usuario_id = @UsuarioId
      AND activo = 1
      AND @FechaRef >= fecha_inicio
      AND @FechaRef <= DATEADD(SECOND, 86399, fecha_fin);

  OPEN presupuestos_cursor;
  FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    BEGIN TRY
      EXEC sp_presupuesto_recalc_gasto_internal @Id = @PresupuestoId, @UsuarioId = @UsuarioId;
    END TRY
    BEGIN CATCH
      -- Un presupuesto que falle no debe tumbar la operacion del prestamo
    END CATCH

    FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
  END

  CLOSE presupuestos_cursor;
  DEALLOCATE presupuestos_cursor;
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_get_by_user
  @UsuarioId   BIGINT,
  @ActivosSolo BIT = NULL,          -- compatibilidad: NULL=todos, 1=activos, 0=inactivos
  @Filtro      NVARCHAR(20) = NULL  -- 'ACTIVOS' | 'SALDADOS' | 'INACTIVOS' | 'TODOS'
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    -- Un prestamo saldado deja de ser 'activo' aunque su bandera siga en 1
    DECLARE @F NVARCHAR(20) = UPPER(LTRIM(RTRIM(COALESCE(
      @Filtro,
      CASE WHEN @ActivosSolo IS NULL THEN 'TODOS'
           WHEN @ActivosSolo = 1 THEN 'ACTIVOS'
           ELSE 'INACTIVOS' END
    ))));

    IF (@F NOT IN ('ACTIVOS','SALDADOS','INACTIVOS','TODOS'))
      SET @F = 'TODOS';

    SELECT *
    FROM dbo.prestamos
    WHERE usuario_id=@UsuarioId
      AND (
        @F = 'TODOS'
        OR (@F = 'ACTIVOS'   AND activa = 1 AND saldo_pendiente > 0)
        OR (@F = 'SALDADOS'  AND saldo_pendiente <= 0)
        OR (@F = 'INACTIVOS' AND activa = 0 AND saldo_pendiente > 0)
      )
    ORDER BY fecha_actualizacion DESC;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO

/* ========================= PAGOS PRESTAMOS ========================= */

/*
  Deriva monto_pagado y saldo_pendiente de la suma real de pagos_prestamos.
  Unica fuente de verdad: la tabla de pagos y monto_total.
  Sustituye a la aritmetica incremental, que se descuadraba al topar valores.
*/
CREATE OR ALTER PROCEDURE sp_prestamo_recalcular
  @PrestamoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @MontoTotal DECIMAL(18,2), @Pagado DECIMAL(18,2);

  SELECT @MontoTotal = monto_total FROM dbo.prestamos WHERE id = @PrestamoId;
  IF (@MontoTotal IS NULL) RETURN;

  SELECT @Pagado = ISNULL(SUM(COALESCE(monto, monto_pago)), 0)
  FROM dbo.pagos_prestamos
  WHERE prestamo_id = @PrestamoId;

  IF (@Pagado < 0) SET @Pagado = 0;
  IF (@Pagado > @MontoTotal) SET @Pagado = @MontoTotal;

  DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

  UPDATE dbo.prestamos
  SET monto_pagado = @Pagado,
      saldo_pendiente = @MontoTotal - @Pagado,
      estado = CASE WHEN @Pagado >= @MontoTotal THEN 'PAGADO' ELSE 'PENDIENTE' END,
      fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
  WHERE id = @PrestamoId;
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_pago_create
  @UsuarioId   BIGINT,
  @PrestamoId  BIGINT,
  @Monto       DECIMAL(18,2),
  @FechaPago   DATETIME2 = NULL,
  @CuentaId    BIGINT = NULL,
  @Notas       NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Monto IS NULL OR @Monto <= 0) RAISERROR('El monto del pago debe ser mayor a 0',16,1);
    IF (@PrestamoId IS NULL OR @PrestamoId <= 0) RAISERROR('Prestamo inválido',16,1);

    DECLARE @PUsuario BIGINT, @MontoTotal DECIMAL(18,2), @TipoPrestamo NVARCHAR(20), @NombrePrestamo NVARCHAR(200);
    SELECT @PUsuario = usuario_id, @MontoTotal = monto_total, @TipoPrestamo = tipo, @NombrePrestamo = nombre
    FROM dbo.prestamos WHERE id=@PrestamoId;

    IF (@PUsuario IS NULL) RAISERROR('Préstamo no encontrado',16,1);
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    IF (@CuentaId IS NOT NULL AND NOT EXISTS (
          SELECT 1 FROM dbo.cuentas WHERE id=@CuentaId AND usuario_id=@UsuarioId AND activa=1))
      RAISERROR('Cuenta no encontrada o inactiva',16,1);

    -- Saldo real segun los pagos registrados, no segun la columna almacenada
    DECLARE @PagadoReal DECIMAL(18,2) = (
      SELECT ISNULL(SUM(COALESCE(monto, monto_pago)), 0)
      FROM dbo.pagos_prestamos WHERE prestamo_id = @PrestamoId
    );
    DECLARE @Pendiente DECIMAL(18,2) = @MontoTotal - @PagadoReal;

    IF (@Pendiente <= 0)
      RAISERROR('El préstamo ya está saldado',16,1);

    IF (@Monto > @Pendiente)
    BEGIN
      DECLARE @MsgExceso NVARCHAR(200) =
        'El pago supera el saldo pendiente (' + CONVERT(NVARCHAR(30), @Pendiente) + ')';
      RAISERROR(@MsgExceso,16,1);
    END

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());
    SET @FechaPago = CAST(ISNULL(@FechaPago, @FechaHoraLocal) AS DATETIME2(0));

    BEGIN TRAN;

    DECLARE @FechaCreacion DATETIME2(0) = CAST(@FechaHoraLocal AS DATETIME2(0));
    DECLARE @TransaccionId BIGINT = NULL;

    /*
      Pagar una DEUDA es dinero que SALE; cobrar un PRESTAMO es dinero que ENTRA.
      Sin cuenta el pago solo mueve el saldo del prestamo, no el de ninguna cuenta.
    */
    IF (@CuentaId IS NOT NULL AND COL_LENGTH('dbo.pagos_prestamos','transaccion_id') IS NOT NULL)
    BEGIN
      DECLARE @TipoMovId BIGINT;
      DECLARE @CategoriaId BIGINT;
      DECLARE @MonedaCuenta NVARCHAR(10);

      SELECT @TipoMovId = id FROM dbo.tipos_transaccion
      WHERE nombre = CASE WHEN @TipoPrestamo = 'DEUDA' THEN 'GASTO' ELSE 'INGRESO' END AND activo = 1;

      SELECT @CategoriaId = id FROM dbo.categorias
      WHERE usuario_id IS NULL AND nombre = 'Préstamos y deudas';

      SELECT @MonedaCuenta = moneda FROM dbo.cuentas WHERE id = @CuentaId;

      IF @TipoMovId IS NULL
        RAISERROR('No existe el tipo de transaccion requerido',16,1);

      INSERT INTO dbo.transacciones (
        usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
        monto, moneda, titulo, descripcion, fecha_transaccion,
        archivo_adjunto, notas, repetir, activa, fecha_creacion
      )
      VALUES (
        @UsuarioId, @CuentaId, @TipoMovId, @CategoriaId, NULL,
        @Monto, COALESCE(@MonedaCuenta, 'COP'),
        CASE WHEN @TipoPrestamo = 'DEUDA' THEN 'Pago de: ' ELSE 'Cobro de: ' END
          + COALESCE(@NombrePrestamo, 'préstamo'),
        NULL, @FechaPago,
        NULL, @Notas, 0, 1, @FechaCreacion
      );

      SET @TransaccionId = SCOPE_IDENTITY();
    END

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.pagos_prestamos') AND name = 'monto_pago')
    BEGIN
      INSERT INTO dbo.pagos_prestamos (prestamo_id, cuenta_id, monto_pago, fecha_pago, notas, fecha_creacion, transaccion_id)
      VALUES (@PrestamoId, @CuentaId, @Monto, @FechaPago, @Notas, @FechaCreacion, @TransaccionId);
    END
    ELSE
    BEGIN
      INSERT INTO dbo.pagos_prestamos (prestamo_id, cuenta_id, monto, fecha_pago, notas, fecha_creacion, transaccion_id)
      VALUES (@PrestamoId, @CuentaId, @Monto, @FechaPago, @Notas, @FechaCreacion, @TransaccionId);
    END

    EXEC sp_prestamo_recalcular @PrestamoId = @PrestamoId;

    COMMIT TRAN;

    IF (@TransaccionId IS NOT NULL AND @TipoPrestamo = 'DEUDA')
      EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;

    SELECT p.*, (SELECT SUM(COALESCE(monto, monto_pago)) FROM dbo.pagos_prestamos WHERE prestamo_id=@PrestamoId) AS total_pagado
    FROM dbo.prestamos p WHERE p.id=@PrestamoId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_pago_update
  @UsuarioId   BIGINT,
  @PagoId      BIGINT,
  @Monto       DECIMAL(18,2) = NULL,
  @FechaPago   DATETIME2     = NULL,
  @CuentaId    BIGINT        = NULL,
  @Notas       NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@PagoId IS NULL OR @PagoId <= 0) RAISERROR('Pago inválido',16,1);

    DECLARE @PrestamoId BIGINT, @PUsuario BIGINT, @MontoAnterior DECIMAL(18,2), @MontoTotalPrestamo DECIMAL(18,2);
    SELECT @PrestamoId = prestamo_id, @MontoAnterior = COALESCE(monto, monto_pago)
    FROM dbo.pagos_prestamos WHERE id=@PagoId;

    IF (@PrestamoId IS NULL) RAISERROR('Pago no encontrado',16,1);
    SELECT @PUsuario = usuario_id, @MontoTotalPrestamo = monto_total
    FROM dbo.prestamos WHERE id=@PrestamoId;
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    -- El nuevo monto no puede hacer que la suma de pagos supere el total
    IF (@Monto IS NOT NULL)
    BEGIN
      DECLARE @PagadoOtros DECIMAL(18,2) = (
        SELECT ISNULL(SUM(COALESCE(monto, monto_pago)), 0)
        FROM dbo.pagos_prestamos
        WHERE prestamo_id = @PrestamoId AND id <> @PagoId
      );
      IF (@Monto <= 0)
        RAISERROR('El monto del pago debe ser mayor a 0',16,1);
      IF (@PagadoOtros + @Monto > @MontoTotalPrestamo)
      BEGIN
        DECLARE @MsgTope NVARCHAR(200) =
          'El pago supera el saldo pendiente (' +
          CONVERT(NVARCHAR(30), @MontoTotalPrestamo - @PagadoOtros) + ')';
        RAISERROR(@MsgTope,16,1);
      END
    END

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    BEGIN TRAN;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.pagos_prestamos') AND name = 'monto_pago')
    BEGIN
      UPDATE dbo.pagos_prestamos
      SET monto_pago = COALESCE(@Monto, monto_pago),
          fecha_pago = COALESCE(CAST(@FechaPago AS DATETIME2(0)), fecha_pago),
          cuenta_id = COALESCE(@CuentaId, cuenta_id),
          notas = COALESCE(@Notas, notas)
      WHERE id=@PagoId;
    END
    ELSE
    BEGIN
      UPDATE dbo.pagos_prestamos
      SET monto = COALESCE(@Monto, monto),
          fecha_pago = COALESCE(CAST(@FechaPago AS DATETIME2(0)), fecha_pago),
          cuenta_id = COALESCE(@CuentaId, cuenta_id),
          notas = COALESCE(@Notas, notas)
      WHERE id=@PagoId;
    END

    -- Mantener el movimiento asociado en linea con el pago editado
    IF COL_LENGTH('dbo.pagos_prestamos','transaccion_id') IS NOT NULL
    BEGIN
      DECLARE @TxPago BIGINT = (SELECT transaccion_id FROM dbo.pagos_prestamos WHERE id=@PagoId);
      IF (@TxPago IS NOT NULL)
      BEGIN
        UPDATE dbo.transacciones
        SET monto = COALESCE(@Monto, monto),
            fecha_transaccion = COALESCE(CAST(@FechaPago AS DATETIME2(0)), fecha_transaccion),
            cuenta_id = COALESCE(@CuentaId, cuenta_id),
            notas = COALESCE(@Notas, notas)
        WHERE id = @TxPago AND usuario_id = @UsuarioId;
      END
    END

    EXEC sp_prestamo_recalcular @PrestamoId = @PrestamoId;

    COMMIT TRAN;

    EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;

    SELECT * FROM dbo.pagos_prestamos WHERE id=@PagoId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_pago_delete
  @UsuarioId   BIGINT,
  @PagoId      BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@PagoId IS NULL OR @PagoId <= 0) RAISERROR('Pago inválido',16,1);

    DECLARE @PrestamoId BIGINT, @PUsuario BIGINT, @TransaccionId BIGINT = NULL;
    SELECT @PrestamoId = prestamo_id FROM dbo.pagos_prestamos WHERE id=@PagoId;
    IF (@PrestamoId IS NULL) RAISERROR('Pago no encontrado',16,1);
    SELECT @PUsuario = usuario_id FROM dbo.prestamos WHERE id=@PrestamoId;
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    IF COL_LENGTH('dbo.pagos_prestamos','transaccion_id') IS NOT NULL
      SELECT @TransaccionId = transaccion_id FROM dbo.pagos_prestamos WHERE id=@PagoId;

    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    BEGIN TRAN;

    DELETE FROM dbo.pagos_prestamos WHERE id=@PagoId;

    -- Devolver el dinero a la cuenta eliminando el movimiento que genero el pago
    IF (@TransaccionId IS NOT NULL)
      DELETE FROM dbo.transacciones WHERE id=@TransaccionId AND usuario_id=@UsuarioId;

    EXEC sp_prestamo_recalcular @PrestamoId = @PrestamoId;

    COMMIT TRAN;

    IF (@TransaccionId IS NOT NULL)
      EXEC sp_prestamo_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_pagos_get_by_prestamo
  @UsuarioId  BIGINT,
  @PrestamoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @PUsuario BIGINT = (SELECT usuario_id FROM dbo.prestamos WHERE id=@PrestamoId);
    IF (@PUsuario IS NULL) RAISERROR('Préstamo no encontrado',16,1);
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    SELECT *
    FROM dbo.pagos_prestamos
    WHERE prestamo_id=@PrestamoId
    ORDER BY fecha_pago DESC, id DESC;
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH
END;
GO
