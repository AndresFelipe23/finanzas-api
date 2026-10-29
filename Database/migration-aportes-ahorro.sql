-- =====================================================
-- Migración: los aportes a metas son ahorro, no gasto
-- =====================================================
-- Un aporte con cuenta genera un GASTO (baja el saldo de la cuenta) y una fila
-- en aportes_metas que apunta a él (transaccion_id). Esa fila es la marca:
-- las sumas de gastos (presupuestos, resúmenes, dashboard) excluyen las
-- transacciones que tienen un aporte, con
--   NOT EXISTS (SELECT 1 FROM aportes_metas am WHERE am.transaccion_id = t.id)
-- Los saldos de las cuentas NO cambian: siguen contando el aporte.
--
-- Este índice hace rápida esa consulta. Después de ejecutarlo hay que
-- volver a ejecutar sp_presupuestos.sql, sp_transacciones.sql y
-- repair-presupuestos-gasto.sql. Se puede ejecutar varias veces.
-- =====================================================

USE FinanzasApiApp;
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.aportes_metas') AND name = 'IX_aportes_metas_transaccion'
)
  CREATE INDEX IX_aportes_metas_transaccion
    ON dbo.aportes_metas (transaccion_id)
    WHERE transaccion_id IS NOT NULL;
GO
