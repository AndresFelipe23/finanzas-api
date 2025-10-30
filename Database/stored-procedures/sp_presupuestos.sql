/*
  Stored Procedures para Presupuestos
  - Tablas: presupuestos
  - Cálculo de gasto usando tabla de transacciones existente
  - Manejo de fechas con DATETIME2(0) y validaciones
*/

/* Crear tabla si no existe */
IF NOT EXISTS (
  SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[presupuestos]') AND type in (N'U')
)
BEGIN
  CREATE TABLE dbo.presupuestos (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id          BIGINT         NOT NULL,
    nombre              NVARCHAR(200)  NOT NULL,
    categoria_id        BIGINT         NULL,
    cuenta_id           BIGINT         NULL,
    periodo             NVARCHAR(20)   NOT NULL,  -- 'SEMANAL' | 'MENSUAL' | 'ANUAL' | 'PERSONALIZADO'
    fecha_inicio        DATETIME2(0)   NOT NULL,
    fecha_fin           DATETIME2(0)   NOT NULL,
    monto_limite        DECIMAL(18,2)  NOT NULL,
    monto_gastado       DECIMAL(18,2)  NOT NULL DEFAULT 0,
    activo              BIT            NOT NULL DEFAULT 1,
    notas               NVARCHAR(1000) NULL,
    fecha_creacion      DATETIME2(0)   NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    fecha_actualizacion DATETIME2(0)   NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0))
  );
END;

/* Asegurar columnas requeridas */
IF COL_LENGTH('dbo.presupuestos','monto_gastado') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD monto_gastado DECIMAL(18,2) NOT NULL CONSTRAINT DF_presup_monto_gastado DEFAULT (0);
END;
IF COL_LENGTH('dbo.presupuestos','activo') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD activo BIT NOT NULL CONSTRAINT DF_presup_activo DEFAULT(1);
END;

/* Asegurar todas las columnas usadas por los SP (para tablas ya existentes con otro esquema) */
IF COL_LENGTH('dbo.presupuestos','nombre') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD nombre NVARCHAR(200) NOT NULL CONSTRAINT DF_presup_nombre DEFAULT('');
END;
IF COL_LENGTH('dbo.presupuestos','categoria_id') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD categoria_id BIGINT NULL;
END;
IF COL_LENGTH('dbo.presupuestos','cuenta_id') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD cuenta_id BIGINT NULL;
END;
/* Forzar nullabilidad si existen como NOT NULL en esquemas previos */
IF EXISTS (
  SELECT 1 FROM sys.columns 
  WHERE object_id = OBJECT_ID('dbo.presupuestos') AND name = 'categoria_id' AND is_nullable = 0
)
BEGIN
  ALTER TABLE dbo.presupuestos ALTER COLUMN categoria_id BIGINT NULL;
END;
IF EXISTS (
  SELECT 1 FROM sys.columns 
  WHERE object_id = OBJECT_ID('dbo.presupuestos') AND name = 'cuenta_id' AND is_nullable = 0
)
BEGIN
  ALTER TABLE dbo.presupuestos ALTER COLUMN cuenta_id BIGINT NULL;
END;
IF COL_LENGTH('dbo.presupuestos','periodo') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD periodo NVARCHAR(20) NOT NULL CONSTRAINT DF_presup_periodo DEFAULT('MENSUAL');
END;
IF COL_LENGTH('dbo.presupuestos','fecha_inicio') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD fecha_inicio DATETIME2(0) NOT NULL CONSTRAINT DF_presup_fecha_inicio DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;
IF COL_LENGTH('dbo.presupuestos','fecha_fin') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD fecha_fin DATETIME2(0) NOT NULL CONSTRAINT DF_presup_fecha_fin DEFAULT (CAST(GETDATE() AS DATETIME2(0)));
END;
IF COL_LENGTH('dbo.presupuestos','monto_limite') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD monto_limite DECIMAL(18,2) NOT NULL CONSTRAINT DF_presup_monto_limite DEFAULT(0);
END;
IF COL_LENGTH('dbo.presupuestos','notas') IS NULL
BEGIN
  ALTER TABLE dbo.presupuestos ADD notas NVARCHAR(1000) NULL;
END;

GO

/* ========================= UTIL: Recalcular Gasto ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_recalc_gasto
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @FInicio DATETIME2(7), @FFin DATETIME2(7), @CategoriaId BIGINT, @CuentaId BIGINT;

    SELECT TOP 1
      @FInicio = fecha_inicio,
      @FFin    = fecha_fin,
      @CategoriaId = categoria_id,
      @CuentaId    = cuenta_id
    FROM dbo.presupuestos
    WHERE id=@Id AND usuario_id=@UsuarioId;

    IF (@FInicio IS NULL OR @FFin IS NULL)
      RAISERROR('Presupuesto no encontrado', 16, 1);

    /* Calcular gasto desde tabla transacciones: solo GASTOS en rango */
    DECLARE @Gastado DECIMAL(18,2) = 0;

    ;WITH tx AS (
      SELECT t.monto AS monto,
             t.fecha_transaccion AS fecha,
             t.categoria_id AS categoria_id,
             t.cuenta_id AS cuenta_id,
             t.tipo_transaccion_id AS tipo_id
      FROM dbo.transacciones t
      WHERE t.usuario_id = @UsuarioId
        AND t.fecha_transaccion >= @FInicio
        AND t.fecha_transaccion <= DATEADD(SECOND, 86399, @FFin) -- fin del día
    )
    SELECT @Gastado = ISNULL(SUM(CASE WHEN (tipo_id = 2 /* GASTO */) THEN monto ELSE 0 END), 0)
    FROM tx
    WHERE (@CategoriaId IS NULL OR categoria_id = @CategoriaId)
      AND (@CuentaId IS NULL OR cuenta_id = @CuentaId);

    UPDATE dbo.presupuestos
    SET monto_gastado = @Gastado,
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.presupuestos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= CREATE ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_create
  @UsuarioId     BIGINT,
  @Nombre        NVARCHAR(200),
  @Periodo       NVARCHAR(20),
  @FechaInicio   DATETIME2(7) = NULL,
  @FechaFin      DATETIME2(7) = NULL,
  @MontoLimite   DECIMAL(18,2),
  @CategoriaId   BIGINT = NULL,
  @CuentaId      BIGINT = NULL,
  @Notas         NVARCHAR(1000) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido',16,1);
    IF (@Nombre IS NULL OR LTRIM(RTRIM(@Nombre))='') RAISERROR('El nombre es requerido',16,1);
    IF (@MontoLimite IS NULL OR @MontoLimite <= 0) RAISERROR('El monto límite debe ser mayor a 0',16,1);
    IF (@Periodo NOT IN ('SEMANAL','MENSUAL','ANUAL','PERSONALIZADO')) RAISERROR('Periodo inválido',16,1);

    -- Procesar fecha inicio: usar directamente o fecha actual
    DECLARE @Ini DATETIME2(7);
    
    IF @FechaInicio IS NOT NULL
      SET @Ini = @FechaInicio;
    ELSE
      SET @Ini = GETDATE();

    -- Calcular fecha fin según el periodo
    DECLARE @Fin DATETIME2(7);
    
    IF (@Periodo = 'SEMANAL')
      SET @Fin = DATEADD(DAY, 6, @Ini);
    ELSE IF (@Periodo = 'MENSUAL')
    BEGIN
      -- Obtener el último día del mes de fecha_inicio
      -- Primero obtener el primer día del mes siguiente, luego restar 1 día
      SET @Fin = DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(@Ini), MONTH(@Ini), 1)));
    END
    ELSE IF (@Periodo = 'ANUAL')
    BEGIN
      SET @Fin = CAST(DATEFROMPARTS(YEAR(@Ini), 12, 31) AS DATETIME2(7));
    END
    ELSE -- PERSONALIZADO
      SET @Fin = ISNULL(@FechaFin, @Ini);

    INSERT INTO dbo.presupuestos (
      usuario_id, nombre, categoria_id, cuenta_id, periodo,
      fecha_inicio, fecha_fin, monto_limite, monto_gastado, activo, notas,
      fecha_creacion, fecha_actualizacion
    )
    VALUES (
      @UsuarioId, @Nombre, @CategoriaId, @CuentaId, @Periodo,
      @Ini, @Fin, @MontoLimite, 0, 1, @Notas,
      GETDATE(), GETDATE()
    );

    DECLARE @NewId BIGINT = SCOPE_IDENTITY();

    EXEC sp_presupuesto_recalc_gasto @Id=@NewId, @UsuarioId=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= UPDATE ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_update
  @Id            BIGINT,
  @UsuarioId     BIGINT,
  @Nombre        NVARCHAR(200) = NULL,
  @Periodo       NVARCHAR(20)  = NULL,
  @FechaInicio   DATETIME2(7)  = NULL,
  @FechaFin      DATETIME2(7)  = NULL,
  @MontoLimite   DECIMAL(18,2) = NULL,
  @CategoriaId   BIGINT        = NULL,
  @CuentaId      BIGINT        = NULL,
  @Activo        BIT           = NULL,
  @Notas         NVARCHAR(1000)= NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Id IS NULL OR @Id <= 0) RAISERROR('Id inválido',16,1);
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido',16,1);

    UPDATE dbo.presupuestos
    SET nombre = COALESCE(NULLIF(LTRIM(RTRIM(@Nombre)),''), nombre),
        periodo = COALESCE(@Periodo, periodo),
        fecha_inicio = COALESCE(@FechaInicio, fecha_inicio),
        fecha_fin = COALESCE(@FechaFin, fecha_fin),
        monto_limite = COALESCE(@MontoLimite, monto_limite),
        categoria_id = COALESCE(@CategoriaId, categoria_id),
        cuenta_id = COALESCE(@CuentaId, cuenta_id),
        activo = COALESCE(@Activo, activo),
        notas = COALESCE(@Notas, notas),
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@Id AND usuario_id=@UsuarioId;

    -- Recalcular gasto si cambia rango/criterios o límite
    EXEC sp_presupuesto_recalc_gasto @Id=@Id, @UsuarioId=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= TOGGLE ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_toggle
  @Id        BIGINT,
  @UsuarioId BIGINT,
  @Activo    BIT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    UPDATE dbo.presupuestos
    SET activo = @Activo,
        fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.presupuestos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= DELETE ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_delete
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DELETE FROM dbo.presupuestos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= GETTERS ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_get_by_id
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT * FROM dbo.presupuestos WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_presupuesto_get_by_user
  @UsuarioId BIGINT,
  @SoloActivos BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT *
    FROM dbo.presupuestos
    WHERE usuario_id=@UsuarioId
      AND (@SoloActivos IS NULL OR activo=@SoloActivos)
    ORDER BY fecha_fin DESC, fecha_actualizacion DESC;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= RESUMEN ========================= */
CREATE OR ALTER PROCEDURE sp_presupuesto_resumen
  @UsuarioId BIGINT,
  @Fecha DATETIME2 = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @Hoy DATETIME2(0) = CAST(ISNULL(@Fecha, GETDATE()) AS DATETIME2(0));
    SELECT 
      COUNT(1) AS total_presupuestos,
      SUM(CASE WHEN monto_gastado >= monto_limite THEN 1 ELSE 0 END) AS sobrepasados,
      SUM(CASE WHEN monto_gastado < monto_limite THEN 1 ELSE 0 END) AS dentro_presupuesto,
      SUM(monto_limite) AS suma_limites,
      SUM(monto_gastado) AS suma_gastado
    FROM dbo.presupuestos
    WHERE usuario_id=@UsuarioId
      AND activo = 1
      AND @Hoy BETWEEN fecha_inicio AND DATEADD(SECOND,86399,fecha_fin);
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO


