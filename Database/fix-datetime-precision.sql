-- =====================================================
-- Script para quitar milisegundos de las columnas de fecha
-- =====================================================

-- Opción A: Cambiar precisión de las columnas a segundos
-- Esto eliminará los milisegundos de futuras inserciones
ALTER TABLE dbo.transacciones
ALTER COLUMN fecha_transaccion DATETIME2(0) NOT NULL;

ALTER TABLE dbo.transacciones
ALTER COLUMN fecha_creacion DATETIME2(0) NOT NULL;

-- Opción B: Si prefieres mantener DATETIME2 con precisión pero truncar en el SP
-- No ejecutes esto si ya ejecutaste la Opción A
-- Solo actualiza el stored procedure para truncar antes de insertar

PRINT 'Columnas de fecha actualizadas a precisión de segundos (sin milisegundos)'
GO
