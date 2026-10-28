-- =====================================================
-- Reparación: recalcular monto_gastado de todos los presupuestos
-- =====================================================
-- Como sp_transaccion_create no recalculaba presupuestos, monto_gastado
-- pudo quedar desfasado respecto a las transacciones reales.
-- Este script lo vuelve a derivar de la tabla transacciones.
--
-- Ejecutar DESPUES de sp_transacciones.sql y sp_presupuestos.sql.
-- Es idempotente: puede correrse las veces que haga falta.
-- =====================================================

USE FinanzasApiApp;
GO

-- Presupuestos cuyo monto_gastado no coincide con el gasto real del periodo
SELECT
  p.id,
  p.nombre,
  p.monto_gastado                       AS gastado_almacenado,
  ISNULL(x.gastado_real, 0)             AS gastado_real,
  p.monto_gastado - ISNULL(x.gastado_real, 0) AS diferencia
FROM dbo.presupuestos p
OUTER APPLY (
  SELECT ISNULL(SUM(t.monto), 0) AS gastado_real
  FROM dbo.transacciones t
  WHERE t.usuario_id = p.usuario_id
    AND t.activa = 1
    AND t.tipo_transaccion_id = (SELECT id FROM dbo.tipos_transaccion WHERE nombre = 'GASTO' AND activo = 1)
    AND t.fecha_transaccion >= p.fecha_inicio
    AND t.fecha_transaccion <= DATEADD(SECOND, 86399, p.fecha_fin)
    AND (p.categoria_id IS NULL OR t.categoria_id = p.categoria_id)
    AND (p.cuenta_id IS NULL OR t.cuenta_id = p.cuenta_id)
) x
WHERE ISNULL(p.monto_gastado, 0) <> ISNULL(x.gastado_real, 0);
GO

DECLARE @Id BIGINT, @Usuario BIGINT;
DECLARE @Reparados INT = 0;

DECLARE presupuestos_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT id, usuario_id FROM dbo.presupuestos;

OPEN presupuestos_cursor;
FETCH NEXT FROM presupuestos_cursor INTO @Id, @Usuario;

WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    EXEC sp_presupuesto_recalc_gasto_internal @Id = @Id, @UsuarioId = @Usuario;
    SET @Reparados = @Reparados + 1;
  END TRY
  BEGIN CATCH
    -- Continuar con el siguiente presupuesto si hay error
  END CATCH

  FETCH NEXT FROM presupuestos_cursor INTO @Id, @Usuario;
END

CLOSE presupuestos_cursor;
DEALLOCATE presupuestos_cursor;

PRINT 'Presupuestos recalculados: ' + CAST(@Reparados AS NVARCHAR(10));
GO
