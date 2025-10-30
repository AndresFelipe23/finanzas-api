-- Stored Procedures for Metas and Aportes (SQL Server)
-- Includes: create, update, delete, toggle, get by user/id, aporte create, list aportes

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE sp_meta_create
  @UsuarioId       BIGINT,
  @Nombre          NVARCHAR(200),
  @Descripcion     NVARCHAR(1000) = NULL,
  @MontoObjetivo   DECIMAL(18,2),
  @FechaObjetivo   DATETIME2,
  @Icono           NVARCHAR(50) = NULL,
  @Color           NVARCHAR(7) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = '')
      RAISERROR('El nombre es requerido', 16, 1);
    IF (@MontoObjetivo IS NULL OR @MontoObjetivo <= 0)
      RAISERROR('El monto objetivo debe ser mayor a 0', 16, 1);

    INSERT INTO metas (
      usuario_id, nombre, descripcion, monto_objetivo, monto_actual,
      fecha_objetivo, icono, color, activa, fecha_creacion, fecha_actualizacion
    )
    VALUES (
      @UsuarioId, @Nombre, @Descripcion, @MontoObjetivo, 0,
      CAST(@FechaObjetivo AS DATETIME2(0)), @Icono, @Color, 1, CAST(GETDATE() AS DATETIME2(0)), CAST(GETDATE() AS DATETIME2(0))
    );

    DECLARE @NewId BIGINT = SCOPE_IDENTITY();

    SELECT m.*
    FROM metas m
    WHERE m.id = @NewId AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_update
  @Id              BIGINT,
  @UsuarioId       BIGINT,
  @Nombre          NVARCHAR(200) = NULL,
  @Descripcion     NVARCHAR(1000) = NULL,
  @MontoObjetivo   DECIMAL(18,2) = NULL,
  @FechaObjetivo   DATETIME2 = NULL,
  @Icono           NVARCHAR(50) = NULL,
  @Color           NVARCHAR(7) = NULL,
  @Activa          BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM metas WHERE id = @Id AND usuario_id = @UsuarioId)
      RAISERROR('Meta no encontrada', 16, 1);

    UPDATE metas
      SET nombre              = COALESCE(@Nombre, nombre),
          descripcion         = COALESCE(@Descripcion, descripcion),
          monto_objetivo      = COALESCE(@MontoObjetivo, monto_objetivo),
          fecha_objetivo      = COALESCE(CAST(@FechaObjetivo AS DATETIME2(0)), fecha_objetivo),
          icono               = COALESCE(@Icono, icono),
          color               = COALESCE(@Color, color),
          activa              = COALESCE(@Activa, activa),
          fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id = @Id AND usuario_id = @UsuarioId;

    SELECT m.* FROM metas m WHERE m.id = @Id AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_delete
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM metas WHERE id = @Id AND usuario_id = @UsuarioId)
      RAISERROR('Meta no encontrada', 16, 1);

    DELETE FROM aportes_metas WHERE meta_id = @Id;
    DELETE FROM metas WHERE id = @Id AND usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_toggle_activa
  @Id        BIGINT,
  @UsuarioId BIGINT,
  @Activa    BIT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM metas WHERE id = @Id AND usuario_id = @UsuarioId)
      RAISERROR('Meta no encontrada', 16, 1);

    UPDATE metas
      SET activa = @Activa,
          fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
    WHERE id = @Id AND usuario_id = @UsuarioId;

    SELECT m.* FROM metas m WHERE m.id = @Id AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_get_by_user
  @UsuarioId   BIGINT,
  @Filtro      NVARCHAR(20) = 'TODAS'  -- 'ACTIVAS' | 'COMPLETADAS' | 'TODAS'
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT m.*
    FROM metas m
    WHERE m.usuario_id = @UsuarioId
      AND (
        @Filtro = 'TODAS'
        OR (@Filtro = 'ACTIVAS'     AND m.activa = 1 AND m.monto_actual < m.monto_objetivo)
        OR (@Filtro = 'COMPLETADAS' AND m.monto_actual >= m.monto_objetivo)
      )
    ORDER BY m.fecha_creacion DESC;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_get_by_id
  @Id        BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT m.*
    FROM metas m
    WHERE m.id = @Id AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_aporte_create
  @UsuarioId     BIGINT,
  @MetaId        BIGINT,
  @CuentaId      BIGINT = NULL,
  @MontoAporte   DECIMAL(18,2),
  @Notas         NVARCHAR(500) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@MontoAporte IS NULL OR @MontoAporte <= 0)
      RAISERROR('El monto del aporte debe ser mayor a 0', 16, 1);

    IF NOT EXISTS (SELECT 1 FROM metas WHERE id = @MetaId AND usuario_id = @UsuarioId)
      RAISERROR('Meta no encontrada', 16, 1);

    IF EXISTS (SELECT 1 FROM metas WHERE id = @MetaId AND activa = 0)
      RAISERROR('La meta está inactiva', 16, 1);

    BEGIN TRAN;

      INSERT INTO aportes_metas (meta_id, cuenta_id, monto_aporte, fecha_aporte, notas)
      VALUES (@MetaId, @CuentaId, @MontoAporte, CAST(GETDATE() AS DATETIME2(0)), @Notas);

      UPDATE metas
        SET monto_actual = monto_actual + @MontoAporte,
            fecha_actualizacion = CAST(GETDATE() AS DATETIME2(0))
      WHERE id = @MetaId AND usuario_id = @UsuarioId;

    COMMIT TRAN;

    SELECT m.* FROM metas m WHERE m.id = @MetaId AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_aportes_get_by_meta
  @UsuarioId BIGINT,
  @MetaId    BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM metas WHERE id = @MetaId AND usuario_id = @UsuarioId)
      RAISERROR('Meta no encontrada', 16, 1);

    SELECT a.*
    FROM aportes_metas a
    WHERE a.meta_id = @MetaId
    ORDER BY a.fecha_aporte DESC, a.id DESC;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO


