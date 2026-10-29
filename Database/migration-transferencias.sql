-- =====================================================
-- Migración: marcar las transferencias
-- =====================================================
-- Una transferencia se guarda como dos filas: un GASTO en la cuenta de
-- origen y un INGRESO en la de destino. Así los saldos cuadran, pero nada
-- las distinguía de un gasto o ingreso real: inflaban los totales del mes,
-- las gráficas y los presupuestos de "todos los gastos".
--
-- transferencia_id = id de la otra fila de la pareja (NULL si no es
-- transferencia). Sirve para no contarlas y para borrar las dos juntas.
--
-- Se puede ejecutar varias veces: solo agrega lo que falta y solo marca
-- parejas que aún no están marcadas.
-- =====================================================

USE FinanzasApiApp;
GO

IF COL_LENGTH('dbo.transacciones', 'transferencia_id') IS NULL
BEGIN
  ALTER TABLE dbo.transacciones ADD transferencia_id BIGINT NULL;
END
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.transacciones') AND name = 'IX_transacciones_transferencia'
)
BEGIN
  CREATE INDEX IX_transacciones_transferencia
    ON dbo.transacciones (usuario_id, transferencia_id)
    WHERE transferencia_id IS NOT NULL;
END
GO

-- Transferencias ya existentes: el procedimiento de transferencias inserta
-- el GASTO y enseguida el INGRESO, así que son filas con ids consecutivos,
-- mismo usuario, monto, fechas y título, sin categoría y en cuentas distintas
DECLARE @Gasto BIGINT = (SELECT id FROM dbo.tipos_transaccion WHERE nombre = 'GASTO');
DECLARE @Ingreso BIGINT = (SELECT id FROM dbo.tipos_transaccion WHERE nombre = 'INGRESO');

;WITH pares AS (
  SELECT g.id AS gasto_id, i.id AS ingreso_id
  FROM dbo.transacciones g
  JOIN dbo.transacciones i ON i.id = g.id + 1
  WHERE g.usuario_id = i.usuario_id
    AND g.tipo_transaccion_id = @Gasto
    AND i.tipo_transaccion_id = @Ingreso
    AND g.categoria_id IS NULL AND i.categoria_id IS NULL
    AND g.monto = i.monto
    AND g.fecha_transaccion = i.fecha_transaccion
    AND g.fecha_creacion = i.fecha_creacion
    AND ISNULL(g.titulo, '') = ISNULL(i.titulo, '')
    AND ISNULL(g.cuenta_id, -1) <> ISNULL(i.cuenta_id, -1)
    AND g.transferencia_id IS NULL AND i.transferencia_id IS NULL
)
UPDATE t
SET transferencia_id = CASE WHEN t.id = p.gasto_id THEN p.ingreso_id ELSE p.gasto_id END
FROM dbo.transacciones t
JOIN pares p ON t.id IN (p.gasto_id, p.ingreso_id);

PRINT CONCAT('Filas marcadas como transferencia: ', @@ROWCOUNT);
GO

-- Recalcular los presupuestos (ya sin transferencias) se hace al ejecutar
-- sp_presupuestos.sql y luego repair-presupuestos-gasto.sql
