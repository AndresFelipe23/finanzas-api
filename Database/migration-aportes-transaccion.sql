-- =====================================================
-- Migración: los aportes a metas mueven dinero real
-- =====================================================
-- 1. aportes_metas.transaccion_id  -> enlaza el aporte con el GASTO que genera
-- 2. Categoría global 'Ahorro / Metas' -> permite separar ahorro de consumo
-- 3. Backfill: los aportes existentes quedan con transaccion_id NULL
--    (se crearon antes de esta migración y nunca movieron saldo)
-- =====================================================

USE FinanzasApiApp;
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.aportes_metas') AND name = 'transaccion_id'
)
BEGIN
  ALTER TABLE dbo.aportes_metas ADD transaccion_id BIGINT NULL;
  PRINT 'Columna aportes_metas.transaccion_id creada';
END
ELSE
  PRINT 'Columna aportes_metas.transaccion_id ya existe';
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_aportes_metas_transaccion'
)
BEGIN
  ALTER TABLE dbo.aportes_metas
    ADD CONSTRAINT FK_aportes_metas_transaccion
    FOREIGN KEY (transaccion_id) REFERENCES dbo.transacciones(id) ON DELETE NO ACTION;
  PRINT 'FK_aportes_metas_transaccion creada';
END
GO

IF NOT EXISTS (
  SELECT 1 FROM dbo.categorias WHERE usuario_id IS NULL AND nombre = 'Ahorro / Metas'
)
BEGIN
  INSERT INTO dbo.categorias (usuario_id, nombre, icono, color, tipo)
  VALUES (NULL, 'Ahorro / Metas', 'savings', '#1EB256', 'GASTO');
  PRINT 'Categoria global ''Ahorro / Metas'' creada';
END
ELSE
  PRINT 'Categoria global ''Ahorro / Metas'' ya existe';
GO
