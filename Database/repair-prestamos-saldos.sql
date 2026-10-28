-- =====================================================
-- Reparacion: recalcular saldos de todos los prestamos
-- =====================================================
-- Los bugs de aritmetica incremental pudieron dejar monto_pagado y
-- saldo_pendiente desfasados respecto a la suma real de pagos_prestamos.
-- Este script los vuelve a derivar de la fuente de verdad.
--
-- Ejecutar DESPUES de sp_prestamos.sql (necesita sp_prestamo_recalcular).
-- =====================================================

USE FinanzasApiApp;
GO

-- Prestamos cuyos valores almacenados no cuadran con sus pagos
SELECT
  p.id,
  p.nombre,
  p.monto_total,
  p.monto_pagado                          AS pagado_almacenado,
  ISNULL(x.pagado_real, 0)                AS pagado_real,
  p.saldo_pendiente                       AS saldo_almacenado,
  p.monto_total - ISNULL(x.pagado_real, 0) AS saldo_correcto
FROM dbo.prestamos p
OUTER APPLY (
  SELECT ISNULL(SUM(COALESCE(monto, monto_pago)), 0) AS pagado_real
  FROM dbo.pagos_prestamos WHERE prestamo_id = p.id
) x
WHERE ISNULL(p.monto_pagado, 0) <> ISNULL(x.pagado_real, 0)
   OR ISNULL(p.saldo_pendiente, 0) <> p.monto_total - ISNULL(x.pagado_real, 0);
GO

DECLARE @Id BIGINT;
DECLARE @Reparados INT = 0;

DECLARE prestamos_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT id FROM dbo.prestamos;

OPEN prestamos_cursor;
FETCH NEXT FROM prestamos_cursor INTO @Id;

WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC sp_prestamo_recalcular @PrestamoId = @Id;
  SET @Reparados = @Reparados + 1;
  FETCH NEXT FROM prestamos_cursor INTO @Id;
END

CLOSE prestamos_cursor;
DEALLOCATE prestamos_cursor;

PRINT 'Prestamos recalculados: ' + CAST(@Reparados AS NVARCHAR(10));
GO
