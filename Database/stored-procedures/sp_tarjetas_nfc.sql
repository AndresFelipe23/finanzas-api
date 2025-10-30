/*
  Tarjetas NFC - Stored Procedures
  Esquema de tabla definido en database-schema.sql:
  dbo.tarjetas_nfc(id, usuario_id, cuenta_id, nombre_portador, numero_tarjeta_hash,
                   tipo, banco, color, activa, fecha_creacion)
*/

/* ========================= CREATE ========================= */
CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_create
  @UsuarioId           BIGINT,
  @CuentaId            BIGINT = NULL,
  @NombrePortador      NVARCHAR(100),
  @NumeroTarjetaHash   NVARCHAR(100),
  @Tipo                NVARCHAR(20),    -- 'DEBITO' | 'CREDITO'
  @Banco               NVARCHAR(100) = NULL,
  @Color               NVARCHAR(7) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido', 16, 1);
    IF (@NombrePortador IS NULL OR LTRIM(RTRIM(@NombrePortador))='') RAISERROR('Nombre del portador requerido', 16, 1);
    IF (@NumeroTarjetaHash IS NULL OR LTRIM(RTRIM(@NumeroTarjetaHash))='') RAISERROR('Hash de tarjeta requerido', 16, 1);
    IF (@Tipo NOT IN ('DEBITO','CREDITO')) RAISERROR('Tipo inválido', 16, 1);

    IF EXISTS (
      SELECT 1 FROM dbo.tarjetas_nfc
      WHERE usuario_id=@UsuarioId AND numero_tarjeta_hash=@NumeroTarjetaHash
    ) RAISERROR('La tarjeta ya está registrada para este usuario', 16, 1);

    INSERT INTO dbo.tarjetas_nfc (
      usuario_id, cuenta_id, nombre_portador, numero_tarjeta_hash, tipo, banco, color, activa, fecha_creacion
    )
    VALUES (
      @UsuarioId, @CuentaId, LTRIM(RTRIM(@NombrePortador)), LTRIM(RTRIM(@NumeroTarjetaHash)), @Tipo, NULLIF(LTRIM(RTRIM(@Banco)), ''), NULLIF(LTRIM(RTRIM(@Color)), ''), 1, GETDATE()
    );

    SELECT TOP 1 * FROM dbo.tarjetas_nfc WHERE usuario_id=@UsuarioId AND numero_tarjeta_hash=@NumeroTarjetaHash;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= UPDATE ========================= */
CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_update
  @Id                 BIGINT,
  @UsuarioId          BIGINT,
  @CuentaId           BIGINT        = NULL,
  @NombrePortador     NVARCHAR(100) = NULL,
  @Tipo               NVARCHAR(20)  = NULL,
  @Banco              NVARCHAR(100) = NULL,
  @Color              NVARCHAR(7)   = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    IF (@Id IS NULL OR @Id <= 0) RAISERROR('Id inválido', 16, 1);
    IF (@UsuarioId IS NULL OR @UsuarioId <= 0) RAISERROR('Usuario inválido', 16, 1);

    UPDATE dbo.tarjetas_nfc
    SET cuenta_id = COALESCE(@CuentaId, cuenta_id),
        nombre_portador = COALESCE(NULLIF(LTRIM(RTRIM(@NombrePortador)), ''), nombre_portador),
        tipo = COALESCE(@Tipo, tipo),
        banco = COALESCE(NULLIF(LTRIM(RTRIM(@Banco)), ''), banco),
        color = COALESCE(NULLIF(LTRIM(RTRIM(@Color)), ''), color)
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.tarjetas_nfc WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= TOGGLE ========================= */
CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_toggle
  @Id         BIGINT,
  @UsuarioId  BIGINT,
  @Activa     BIT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    UPDATE dbo.tarjetas_nfc
    SET activa = @Activa
    WHERE id=@Id AND usuario_id=@UsuarioId;

    SELECT * FROM dbo.tarjetas_nfc WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= DELETE ========================= */
CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_delete
  @Id         BIGINT,
  @UsuarioId  BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    DELETE FROM dbo.tarjetas_nfc WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

/* ========================= GETTERS ========================= */
CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_get_by_id
  @Id         BIGINT,
  @UsuarioId  BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT * FROM dbo.tarjetas_nfc WHERE id=@Id AND usuario_id=@UsuarioId;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_tarjeta_nfc_get_by_user
  @UsuarioId  BIGINT,
  @SoloActivas BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    SELECT *
    FROM dbo.tarjetas_nfc
    WHERE usuario_id=@UsuarioId
      AND (@SoloActivas IS NULL OR activa=@SoloActivas)
    ORDER BY fecha_creacion DESC;
  END TRY
  BEGIN CATCH
    DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Msg, 16, 1);
  END CATCH
END;
GO



