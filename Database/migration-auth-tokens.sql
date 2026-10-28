-- =====================================================
-- Migración: tokens de refresco y de recuperación de contraseña
-- =====================================================
-- refresh_tokens         -> sesiones revocables; el access token JWT es corto
-- password_reset_tokens  -> enlaces de "olvidé mi contraseña", un solo uso
--
-- Ambos guardan el HASH del token (SHA-256), nunca el token en claro:
-- si se filtra la base de datos, los tokens no son utilizables.
-- =====================================================

USE FinanzasApiApp;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.refresh_tokens') AND type = 'U')
BEGIN
  CREATE TABLE dbo.refresh_tokens (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id     BIGINT        NOT NULL,
    token_hash     CHAR(64)      NOT NULL,       -- SHA-256 en hex
    expira         DATETIME2(0)  NOT NULL,
    revocado       BIT           NOT NULL DEFAULT 0,
    reemplazado_por BIGINT       NULL,           -- rotación: apunta al token que lo sustituyó
    user_agent     NVARCHAR(300) NULL,
    fecha_creacion DATETIME2(0)  NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    CONSTRAINT FK_refresh_tokens_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios(id) ON DELETE CASCADE
  );
  CREATE UNIQUE INDEX UX_refresh_tokens_hash ON dbo.refresh_tokens (token_hash);
  CREATE INDEX IX_refresh_tokens_usuario ON dbo.refresh_tokens (usuario_id);
  PRINT 'Tabla refresh_tokens creada';
END
ELSE
  PRINT 'Tabla refresh_tokens ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.password_reset_tokens') AND type = 'U')
BEGIN
  CREATE TABLE dbo.password_reset_tokens (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id     BIGINT        NOT NULL,
    token_hash     CHAR(64)      NOT NULL,       -- SHA-256 en hex
    expira         DATETIME2(0)  NOT NULL,
    usado          BIT           NOT NULL DEFAULT 0,
    fecha_creacion DATETIME2(0)  NOT NULL DEFAULT CAST(GETDATE() AS DATETIME2(0)),
    CONSTRAINT FK_password_reset_usuario FOREIGN KEY (usuario_id) REFERENCES dbo.usuarios(id) ON DELETE CASCADE
  );
  CREATE UNIQUE INDEX UX_password_reset_hash ON dbo.password_reset_tokens (token_hash);
  CREATE INDEX IX_password_reset_usuario ON dbo.password_reset_tokens (usuario_id);
  PRINT 'Tabla password_reset_tokens creada';
END
ELSE
  PRINT 'Tabla password_reset_tokens ya existe';
GO
