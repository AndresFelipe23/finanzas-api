/* ========================= PAGOS NFC ========================= */

/* CREATE */
CREATE OR ALTER PROCEDURE sp_pago_nfc_create
  @UsuarioId          BIGINT,
  @TarjetaId          BIGINT,
  @DispositivoNfcId   BIGINT,
  @Monto              DECIMAL(18,2),
  @FechaTransaccion   DATETIME2(7) = NULL,
  @CuentaId           BIGINT        = NULL,
  @CategoriaId        BIGINT        = NULL,
  @Descripcion        NVARCHAR(500) = NULL,
  @Ubicacion          NVARCHAR(200) = NULL,
  @Lat                DECIMAL(10,8) = NULL,
  @Lon                DECIMAL(11,8) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido', 16, 1);
    IF (@TarjetaId IS NULL OR @TarjetaId <= 0) RAISERROR('Tarjeta inválida', 16, 1);
    IF (@DispositivoNfcId IS NULL OR @DispositivoNfcId <= 0) RAISERROR('Dispositivo NFC inválido', 16, 1);
    IF (@Monto IS NULL OR @Monto <= 0) RAISERROR('Monto inválido', 16, 1);

    -- Validar tarjeta y obtener cuenta por defecto
    DECLARE @CuentaIdFinal BIGINT = @CuentaId;
    DECLARE @TarjetaActiva BIT;
    SELECT TOP 1 @TarjetaActiva = activa,
                 @CuentaIdFinal = COALESCE(@CuentaId, cuenta_id)
    FROM dbo.tarjetas_nfc
    WHERE id = @TarjetaId AND usuario_id = @UsuarioId;

    IF (@TarjetaActiva IS NULL) RAISERROR('Tarjeta no encontrada', 16, 1);
    IF (@TarjetaActiva = 0) RAISERROR('Tarjeta desactivada', 16, 1);
    IF (@CuentaIdFinal IS NULL) RAISERROR('La tarjeta no tiene cuenta asociada y no se envió CuentaId', 16, 1);

    -- Moneda de la cuenta
    DECLARE @Moneda NVARCHAR(10) = 'COP';
    SELECT TOP 1 @Moneda = ISNULL(moneda, 'COP') FROM dbo.cuentas WHERE id=@CuentaIdFinal AND usuario_id=@UsuarioId;
    IF (@Moneda IS NULL) RAISERROR('Cuenta no encontrada para el usuario', 16, 1);

    -- Id de tipo GASTO
    DECLARE @TipoGastoId BIGINT;
    SELECT TOP 1 @TipoGastoId = id FROM dbo.tipos_transaccion WHERE nombre = 'GASTO';
    IF (@TipoGastoId IS NULL) RAISERROR('Tipo de transacción GASTO no definido', 16, 1);

    -- Insertar transacción (GASTO)
    DECLARE @TransaccionId BIGINT;
    INSERT INTO dbo.transacciones (
      usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id,
      monto, moneda, titulo, descripcion, fecha_transaccion, archivo_adjunto, notas, repetir, activa, fecha_creacion
    )
    VALUES (
      @UsuarioId, @CuentaIdFinal, @TipoGastoId, @CategoriaId, NULL,
      @Monto, @Moneda, N'Pago NFC', @Descripcion, COALESCE(@FechaTransaccion, GETDATE()), NULL, NULL, 0, 1, GETDATE()
    );
    SET @TransaccionId = SCOPE_IDENTITY();

    -- Insertar pago NFC
    INSERT INTO dbo.pagos_nfc (
      usuario_id, tarjeta_nfc_id, transaccion_id, dispositivo_nfc_id,
      ubicacion, latitud, longitud, fecha_pago
    )
    VALUES (
      @UsuarioId, @TarjetaId, @TransaccionId, @DispositivoNfcId,
      @Ubicacion, @Lat, @Lon, COALESCE(@FechaTransaccion, GETDATE())
    );

    -- Resultado
    SELECT 
      t.*, p.id AS pago_nfc_id, p.dispositivo_nfc_id, p.ubicacion, p.latitud, p.longitud, p.fecha_pago
    FROM dbo.transacciones t
    INNER JOIN dbo.pagos_nfc p ON p.transaccion_id = t.id
    WHERE t.id = @TransaccionId AND t.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* GET BY USER */
CREATE OR ALTER PROCEDURE sp_pago_nfc_get_by_user
  @UsuarioId BIGINT,
  @TarjetaId BIGINT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT 
      p.*, t.monto, t.moneda, t.descripcion, t.fecha_transaccion, t.cuenta_id, t.categoria_id
    FROM dbo.pagos_nfc p
    INNER JOIN dbo.transacciones t ON t.id = p.transaccion_id AND t.usuario_id = @UsuarioId
    WHERE p.usuario_id = @UsuarioId
      AND (@TarjetaId IS NULL OR p.tarjeta_nfc_id = @TarjetaId)
    ORDER BY p.fecha_pago DESC;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* GET BY ID */
CREATE OR ALTER PROCEDURE sp_pago_nfc_get_by_id
  @Id BIGINT,
  @UsuarioId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT TOP 1 
      p.*, t.monto, t.moneda, t.descripcion, t.fecha_transaccion, t.cuenta_id, t.categoria_id
    FROM dbo.pagos_nfc p
    INNER JOIN dbo.transacciones t ON t.id = p.transaccion_id AND t.usuario_id = @UsuarioId
    WHERE p.id = @Id AND p.usuario_id = @UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO


