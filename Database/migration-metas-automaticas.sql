-- =====================================================
-- Migración: aporte automático a las metas
-- =====================================================
-- aporte_auto_porcentaje -> % de cada ingreso que se aparta para la meta
--                           (NULL: la meta no aparta nada sola)
-- aporte_auto_minimo     -> el aporte solo se hace con ingresos de este valor
--                           o más (evita apartar de ingresos pequeños)
--
-- Se aplica al registrar un INGRESO (en la app, por el registro automático de
-- compras o por un pago recurrente): ver sp_meta_aportes_automaticos_internal
-- en sp_metas.sql, que llama sp_transaccion_create. Ejecutar ESTE script
-- antes que sp_metas.sql y sp_transacciones.sql. Se puede repetir.
-- =====================================================

USE FinanzasApiApp;
GO

IF COL_LENGTH('dbo.metas', 'aporte_auto_porcentaje') IS NULL
  ALTER TABLE dbo.metas ADD aporte_auto_porcentaje DECIMAL(5,2) NULL
    CONSTRAINT CK_metas_aporte_auto_porcentaje
      CHECK (aporte_auto_porcentaje > 0 AND aporte_auto_porcentaje <= 100);
GO

IF COL_LENGTH('dbo.metas', 'aporte_auto_minimo') IS NULL
  ALTER TABLE dbo.metas ADD aporte_auto_minimo DECIMAL(18,2) NULL
    CONSTRAINT CK_metas_aporte_auto_minimo CHECK (aporte_auto_minimo >= 0);
GO
