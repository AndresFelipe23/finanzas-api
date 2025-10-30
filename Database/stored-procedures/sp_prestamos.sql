/*
  Stored Procedures para Gestionar Prestamos y Pagos de Prestamos
  Tablas: prestamos, pagos_prestamos
  Notas:
  - Maneja fechas con DATETIME2(0)
  - Asegura actualizacion de saldo_pendiente al crear/actualizar/eliminar pagos
  - Usa RAISERROR con captura de ERROR_MESSAGE() en variable
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
IF COL_LENGTH('dbo.prestamos', 'saldo_pendiente') IS NULL
BEGIN
  ALTER TABLE dbo.prestamos ADD saldo_pendiente DECIMAL(18,2) NOT NULL CONSTRAINT DF_prestamos_saldo_pendiente DEFAULT(0);
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
  @NombreDeudorPrestador NVARCHAR(200) = NULL
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

    SET @FechaInicio = CAST(ISNULL(@FechaInicio, GETDATE()) AS DATETIME2(0));
    IF (@FechaFin IS NOT NULL)
      SET @FechaFin = CAST(@FechaFin AS DATETIME2(0));

    DECLARE @NombrePersona NVARCHAR(200) = COALESCE(NULLIF(LTRIM(RTRIM(@NombreDeudorPrestador)), ''), NULLIF(LTRIM(RTRIM(@Notas)), ''), @Nombre);
    DECLARE @FechaPrestamo DATETIME2(0) = @FechaInicio;

    IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NOT NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NOT NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, fecha_creacion, fecha_actualizacion,
        nombre_deudor_prestador, fecha_prestamo
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoTotal,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, CAST(GETDATE() AS DATETIME2(0)), CAST(GETDATE() AS DATETIME2(0)),
        @NombrePersona, @FechaPrestamo
      );
    END
    ELSE IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NOT NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, fecha_creacion, fecha_actualizacion,
        nombre_deudor_prestador
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoTotal,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, CAST(GETDATE() AS DATETIME2(0)), CAST(GETDATE() AS DATETIME2(0)),
        @NombrePersona
      );
    END
    ELSE IF COL_LENGTH('dbo.prestamos','nombre_deudor_prestador') IS NULL AND COL_LENGTH('dbo.prestamos','fecha_prestamo') IS NOT NULL
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, fecha_creacion, fecha_actualizacion,
        fecha_prestamo
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoTotal,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, CAST(GETDATE() AS DATETIME2(0)), CAST(GETDATE() AS DATETIME2(0)),
        @FechaPrestamo
      );
    END
    ELSE
    BEGIN
      INSERT INTO dbo.prestamos (
        usuario_id, cuenta_id, nombre, tipo, monto_total, saldo_pendiente,
        tasa_interes, fecha_inicio, fecha_fin, notas, activa, fecha_creacion, fecha_actualizacion
      )
      VALUES (
        @UsuarioId, @CuentaId, @Nombre, @Tipo, @MontoTotal, @MontoTotal,
        @TasaInteres, @FechaInicio, @FechaFin, @Notas, 1, CAST(GETDATE() AS DATETIME2(0)), CAST(GETDATE() AS DATETIME2(0))
      );
    END

    DECLARE @NewId BIGINT = SCOPE_IDENTITY();

    SELECT * FROM dbo.prestamos WHERE id = @NewId AND usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
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
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
      WHERE id=@Id AND usuario_id=@UsuarioId;
    END

    SELECT * FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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

    UPDATE dbo.prestamos
    SET activa = @Activa, fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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

    DELETE FROM dbo.prestamos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_prestamo_get_by_user
  @UsuarioId BIGINT,
  @ActivosSolo BIT = NULL -- NULL = todos, 1=activos, 0=inactivos
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT *
    FROM dbo.prestamos
    WHERE usuario_id=@UsuarioId
      AND (@ActivosSolo IS NULL OR activa=@ActivosSolo)
    ORDER BY fecha_actualizacion DESC;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= PAGOS PRESTAMOS ========================= */
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

    DECLARE @PUsuario BIGINT, @Saldo DECIMAL(18,2), @MontoTotal DECIMAL(18,2);
    SELECT @PUsuario = usuario_id, @Saldo = saldo_pendiente, @MontoTotal = monto_total
    FROM dbo.prestamos WHERE id=@PrestamoId;

    IF (@PUsuario IS NULL) RAISERROR('Préstamo no encontrado',16,1);
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    SET @FechaPago = CAST(ISNULL(@FechaPago, GETDATE()) AS DATETIME2(0));

    BEGIN TRAN;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.pagos_prestamos') AND name = 'monto_pago')
    BEGIN
      INSERT INTO dbo.pagos_prestamos (prestamo_id, cuenta_id, monto_pago, fecha_pago, notas)
      VALUES (@PrestamoId, @CuentaId, @Monto, @FechaPago, @Notas);
    END
    ELSE
    BEGIN
      INSERT INTO dbo.pagos_prestamos (prestamo_id, cuenta_id, monto, fecha_pago, notas)
      VALUES (@PrestamoId, @CuentaId, @Monto, @FechaPago, @Notas);
    END

    UPDATE dbo.prestamos
    SET saldo_pendiente = CASE 
                             WHEN @Saldo - @Monto < 0 THEN 0 
                             ELSE @Saldo - @Monto 
                           END,
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@PrestamoId;

    COMMIT TRAN;

    SELECT p.*, (SELECT SUM(COALESCE(monto, monto_pago)) FROM dbo.pagos_prestamos WHERE prestamo_id=@PrestamoId) AS total_pagado
    FROM dbo.prestamos p WHERE p.id=@PrestamoId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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

    DECLARE @PrestamoId BIGINT, @PUsuario BIGINT, @MontoAnterior DECIMAL(18,2);
    SELECT @PrestamoId = prestamo_id, @MontoAnterior = COALESCE(monto, monto_pago)
    FROM dbo.pagos_prestamos WHERE id=@PagoId;

    IF (@PrestamoId IS NULL) RAISERROR('Pago no encontrado',16,1);
    SELECT @PUsuario = usuario_id FROM dbo.prestamos WHERE id=@PrestamoId;
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

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

    -- Recalcular saldo en base a la diferencia del pago
    DECLARE @MontoNuevo DECIMAL(18,2) = (SELECT COALESCE(monto, monto_pago) FROM dbo.pagos_prestamos WHERE id=@PagoId);
    DECLARE @Diff DECIMAL(18,2) = ISNULL(@MontoNuevo,0) - ISNULL(@MontoAnterior,0);

    UPDATE dbo.prestamos
    SET saldo_pendiente = CASE 
                             WHEN saldo_pendiente - @Diff < 0 THEN 0
                             ELSE saldo_pendiente - @Diff
                           END,
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@PrestamoId;

    COMMIT TRAN;

    SELECT * FROM dbo.pagos_prestamos WHERE id=@PagoId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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

    DECLARE @PrestamoId BIGINT, @PUsuario BIGINT, @Monto DECIMAL(18,2);
    SELECT @PrestamoId = prestamo_id, @Monto = COALESCE(monto, monto_pago) FROM dbo.pagos_prestamos WHERE id=@PagoId;
    IF (@PrestamoId IS NULL) RAISERROR('Pago no encontrado',16,1);
    SELECT @PUsuario = usuario_id FROM dbo.prestamos WHERE id=@PrestamoId;
    IF (@PUsuario <> @UsuarioId) RAISERROR('No autorizado',16,1);

    BEGIN TRAN;

    DELETE FROM dbo.pagos_prestamos WHERE id=@PagoId;

    UPDATE dbo.prestamos
    SET saldo_pendiente = saldo_pendiente + ISNULL(@Monto,0),
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@PrestamoId;

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
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
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO


