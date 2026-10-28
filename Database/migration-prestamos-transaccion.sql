-- =====================================================
-- Migración: los préstamos y sus pagos mueven dinero real
-- =====================================================
-- 1. prestamos.transaccion_id       -> movimiento generado al crear el préstamo
-- 2. pagos_prestamos.transaccion_id -> movimiento generado por cada pago
-- 3. Categoría global 'Préstamos y deudas' (tipo AMBOS: genera ingresos y gastos)
--
-- Los registros existentes quedan con transaccion_id NULL: se crearon antes
-- de esta migración y nunca movieron saldo.
-- =====================================================

USE FinanzasApiApp;
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.prestamos') AND name = 'transaccion_id'
)
BEGIN
  ALTER TABLE dbo.prestamos ADD transaccion_id BIGINT NULL;
  PRINT 'Columna prestamos.transaccion_id creada';
END
ELSE
  PRINT 'Columna prestamos.transaccion_id ya existe';
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.pagos_prestamos') AND name = 'transaccion_id'
)
BEGIN
  ALTER TABLE dbo.pagos_prestamos ADD transaccion_id BIGINT NULL;
  PRINT 'Columna pagos_prestamos.transaccion_id creada';
END
ELSE
  PRINT 'Columna pagos_prestamos.transaccion_id ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_prestamos_transaccion')
BEGIN
  ALTER TABLE dbo.prestamos
    ADD CONSTRAINT FK_prestamos_transaccion
    FOREIGN KEY (transaccion_id) REFERENCES dbo.transacciones(id) ON DELETE NO ACTION;
  PRINT 'FK_prestamos_transaccion creada';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_pagos_prestamos_transaccion')
BEGIN
  ALTER TABLE dbo.pagos_prestamos
    ADD CONSTRAINT FK_pagos_prestamos_transaccion
    FOREIGN KEY (transaccion_id) REFERENCES dbo.transacciones(id) ON DELETE NO ACTION;
  PRINT 'FK_pagos_prestamos_transaccion creada';
END
GO

IF NOT EXISTS (
  SELECT 1 FROM dbo.categorias WHERE usuario_id IS NULL AND nombre = 'Préstamos y deudas'
)
BEGIN
  INSERT INTO dbo.categorias (usuario_id, nombre, icono, color, tipo)
  VALUES (NULL, 'Préstamos y deudas', 'payments', '#6366F1', 'AMBOS');
  PRINT 'Categoria global ''Préstamos y deudas'' creada';
END
ELSE
  PRINT 'Categoria global ''Préstamos y deudas'' ya existe';
GO
