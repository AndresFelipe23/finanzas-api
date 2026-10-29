-- =====================================================
-- Migración: datos de las tarjetas de crédito
-- =====================================================
-- cupo      -> límite de la tarjeta (para mostrar el cupo disponible)
-- dia_corte -> día del mes en que el banco corta el periodo
-- dia_pago  -> día del mes en que vence el pago (recordatorio en la app)
--
-- Todas opcionales; las demás cuentas las dejan en NULL. Se puede ejecutar
-- varias veces.
-- =====================================================

USE FinanzasApiApp;
GO

IF COL_LENGTH('dbo.cuentas', 'cupo') IS NULL
  ALTER TABLE dbo.cuentas ADD cupo DECIMAL(18,2) NULL;
GO

IF COL_LENGTH('dbo.cuentas', 'dia_corte') IS NULL
  ALTER TABLE dbo.cuentas ADD dia_corte TINYINT NULL
    CONSTRAINT CK_cuentas_dia_corte CHECK (dia_corte BETWEEN 1 AND 31);
GO

IF COL_LENGTH('dbo.cuentas', 'dia_pago') IS NULL
  ALTER TABLE dbo.cuentas ADD dia_pago TINYINT NULL
    CONSTRAINT CK_cuentas_dia_pago CHECK (dia_pago BETWEEN 1 AND 31);
GO
