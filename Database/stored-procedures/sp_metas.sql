-- Stored Procedures for Metas and Aportes (SQL Server)
-- Includes: create, update, delete, toggle, get by user/id,
--           aporte create/delete, list aportes, recalculo de presupuestos
-- Requiere ejecutar antes: Database/migration-aportes-transaccion.sql

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

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());
    DECLARE @FechaCreacion DATETIME2(0) = CAST(@FechaHoraLocal AS DATETIME2(0));

    INSERT INTO metas (
      usuario_id, nombre, descripcion, monto_objetivo, monto_actual,
      fecha_objetivo, icono, color, activa, fecha_creacion, fecha_actualizacion
    )
    VALUES (
      @UsuarioId, @Nombre, @Descripcion, @MontoObjetivo, 0,
      CAST(@FechaObjetivo AS DATETIME2(0)), @Icono, @Color, 1, @FechaCreacion, @FechaCreacion
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

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    -- NULL = campo no enviado (conservar). Cadena vacia = limpiar el campo.
    UPDATE metas
      SET nombre              = COALESCE(@Nombre, nombre),
          descripcion         = CASE
                                  WHEN @Descripcion IS NULL THEN descripcion
                                  WHEN LTRIM(RTRIM(@Descripcion)) = '' THEN NULL
                                  ELSE @Descripcion
                                END,
          monto_objetivo      = COALESCE(@MontoObjetivo, monto_objetivo),
          fecha_objetivo      = COALESCE(CAST(@FechaObjetivo AS DATETIME2(0)), fecha_objetivo),
          icono               = CASE
                                  WHEN @Icono IS NULL THEN icono
                                  WHEN LTRIM(RTRIM(@Icono)) = '' THEN NULL
                                  ELSE @Icono
                                END,
          color               = CASE
                                  WHEN @Color IS NULL THEN color
                                  WHEN LTRIM(RTRIM(@Color)) = '' THEN NULL
                                  ELSE @Color
                                END,
          activa              = COALESCE(@Activa, activa),
          fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
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

    -- Guardar las transacciones generadas por los aportes para revertirlas
    DECLARE @TransaccionesRevertir TABLE (transaccion_id BIGINT);

    INSERT INTO @TransaccionesRevertir (transaccion_id)
    SELECT transaccion_id
    FROM aportes_metas
    WHERE meta_id = @Id AND transaccion_id IS NOT NULL;

    BEGIN TRAN;

      DELETE FROM aportes_metas WHERE meta_id = @Id;

      DELETE FROM transacciones
      WHERE usuario_id = @UsuarioId
        AND id IN (SELECT transaccion_id FROM @TransaccionesRevertir);

      DELETE FROM metas WHERE id = @Id AND usuario_id = @UsuarioId;

    COMMIT TRAN;

    -- Los presupuestos que contaban esos gastos quedan desactualizados
    EXEC sp_meta_recalcular_presupuestos @UsuarioId = @UsuarioId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
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

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    UPDATE metas
      SET activa = @Activa,
          fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
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
  @Filtro      NVARCHAR(20) = 'TODAS'  -- 'ACTIVAS' | 'COMPLETADAS' | 'PAUSADAS' | 'TODAS'
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
        OR (@Filtro = 'PAUSADAS'    AND m.activa = 0 AND m.monto_actual < m.monto_objetivo)
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

-- Recalcula el gasto de los presupuestos vigentes del usuario.
-- Necesario porque presupuestos.monto_gastado es una columna almacenada que
-- se deriva de transacciones: si un aporte crea o borra un GASTO, queda obsoleta.
CREATE OR ALTER PROCEDURE sp_meta_recalcular_presupuestos
  @UsuarioId BIGINT,
  @Fecha     DATETIME2(7) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @FechaRef DATETIME2(7) = COALESCE(@Fecha, DATEADD(HOUR, -5, GETUTCDATE()));
  DECLARE @PresupuestoId BIGINT;

  DECLARE presupuestos_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id
    FROM presupuestos
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
      -- Un presupuesto que falle no debe tumbar la operacion de la meta
    END CATCH

    FETCH NEXT FROM presupuestos_cursor INTO @PresupuestoId;
  END

  CLOSE presupuestos_cursor;
  DEALLOCATE presupuestos_cursor;
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

    IF (@CuentaId IS NOT NULL AND NOT EXISTS (
          SELECT 1 FROM cuentas WHERE id = @CuentaId AND usuario_id = @UsuarioId AND activa = 1))
      RAISERROR('Cuenta no encontrada o inactiva', 16, 1);

    -- Convertir a zona horaria America/Bogota (UTC-5)
    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());
    DECLARE @FechaAporte DATETIME2(0) = CAST(@FechaHoraLocal AS DATETIME2(0));
    DECLARE @TransaccionId BIGINT = NULL;

    BEGIN TRAN;

      -- Con cuenta origen el aporte mueve dinero: genera un GASTO real.
      -- Sin cuenta el aporte es solo un marcador de progreso.
      IF @CuentaId IS NOT NULL
      BEGIN
        DECLARE @TipoGastoId  BIGINT;
        DECLARE @CategoriaId  BIGINT;
        DECLARE @Moneda       NVARCHAR(10);
        DECLARE @NombreMeta   NVARCHAR(200);

        SELECT @TipoGastoId = id FROM tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1;
        SELECT @CategoriaId = id FROM categorias WHERE usuario_id IS NULL AND nombre = 'Ahorro / Metas';
        SELECT @Moneda = moneda FROM cuentas WHERE id = @CuentaId;
        SELECT @NombreMeta = nombre FROM metas WHERE id = @MetaId;

        IF @TipoGastoId IS NULL
          RAISERROR('No existe el tipo de transaccion GASTO', 16, 1);

        INSERT INTO transacciones (
          usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
          monto, moneda, titulo, descripcion, fecha_transaccion,
          archivo_adjunto, notas, repetir, activa, fecha_creacion
        )
        VALUES (
          @UsuarioId, @CuentaId, @TipoGastoId, @CategoriaId, NULL,
          @MontoAporte, COALESCE(@Moneda, 'COP'),
          'Aporte a meta: ' + COALESCE(@NombreMeta, 'Meta'),
          NULL, @FechaAporte,
          NULL, @Notas, 0, 1, CAST(@FechaHoraLocal AS DATETIME2(0))
        );

        SET @TransaccionId = SCOPE_IDENTITY();
      END

      INSERT INTO aportes_metas (meta_id, cuenta_id, monto_aporte, fecha_aporte, notas, transaccion_id)
      VALUES (@MetaId, @CuentaId, @MontoAporte, @FechaAporte, @Notas, @TransaccionId);

      UPDATE metas
        SET monto_actual = monto_actual + @MontoAporte,
            fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
      WHERE id = @MetaId AND usuario_id = @UsuarioId;

    COMMIT TRAN;

    IF @TransaccionId IS NOT NULL
      EXEC sp_meta_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;

    SELECT m.* FROM metas m WHERE m.id = @MetaId AND m.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_meta_aporte_delete
  @UsuarioId BIGINT,
  @AporteId  BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @MetaId        BIGINT;
    DECLARE @Monto         DECIMAL(18,2);
    DECLARE @TransaccionId BIGINT;

    SELECT @MetaId = a.meta_id, @Monto = a.monto_aporte, @TransaccionId = a.transaccion_id
    FROM aportes_metas a
    INNER JOIN metas m ON m.id = a.meta_id
    WHERE a.id = @AporteId AND m.usuario_id = @UsuarioId;

    IF @MetaId IS NULL
      RAISERROR('Aporte no encontrado', 16, 1);

    DECLARE @FechaHoraLocal DATETIME2(7) = DATEADD(HOUR, -5, GETUTCDATE());

    BEGIN TRAN;

      DELETE FROM aportes_metas WHERE id = @AporteId;

      -- Devolver el dinero a la cuenta eliminando el GASTO que genero el aporte
      IF @TransaccionId IS NOT NULL
        DELETE FROM transacciones WHERE id = @TransaccionId AND usuario_id = @UsuarioId;

      UPDATE metas
        SET monto_actual = CASE
                             WHEN monto_actual - @Monto < 0 THEN 0
                             ELSE monto_actual - @Monto
                           END,
            fecha_actualizacion = CAST(@FechaHoraLocal AS DATETIME2(0))
      WHERE id = @MetaId AND usuario_id = @UsuarioId;

    COMMIT TRAN;

    IF @TransaccionId IS NOT NULL
      EXEC sp_meta_recalcular_presupuestos @UsuarioId = @UsuarioId, @Fecha = @FechaHoraLocal;

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

    SELECT
      a.id,
      a.meta_id,
      a.cuenta_id,
      c.nombre AS cuenta_nombre,
      c.color  AS cuenta_color,
      a.monto_aporte,
      a.fecha_aporte,
      a.notas,
      a.transaccion_id
    FROM aportes_metas a
    LEFT JOIN cuentas c ON c.id = a.cuenta_id
    WHERE a.meta_id = @MetaId
    ORDER BY a.fecha_aporte DESC, a.id DESC;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMsg, 16, 1);
  END CATCH
END;
GO


