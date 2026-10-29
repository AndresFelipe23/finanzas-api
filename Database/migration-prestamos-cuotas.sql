-- =====================================================
-- Migración: préstamos en cuotas (créditos)
-- =====================================================
-- Para un crédito con cuota fija (sistema francés, como los bancos):
--   monto_prestado      -> capital que se recibió o prestó
--   tipo_tasa           -> 'EA' (efectiva anual) o 'MV' (mes vencido); la
--                          tasa sigue en tasa_interes (porcentaje)
--   numero_cuotas       -> plazo total en cuotas mensuales
--   valor_cuota         -> cuota mensual (calculada o la que dice el banco)
--   dia_pago            -> día del mes en que vence cada cuota
--   fecha_primera_cuota -> vencimiento de la cuota 1
--   cuotas_previas      -> cuotas ya pagadas antes de registrarlo en la app
--
-- Con cuotas, monto_total es lo que falta pagar CON intereses al registrarlo
-- (valor_cuota × cuotas restantes): cada pago baja el saldo por su valor
-- completo y llega a 0 en la última cuota. Los préstamos sin cuotas siguen
-- igual (todas estas columnas en NULL). Se puede ejecutar varias veces.
-- =====================================================

USE FinanzasApiApp;
GO

IF COL_LENGTH('dbo.prestamos', 'monto_prestado') IS NULL
  ALTER TABLE dbo.prestamos ADD monto_prestado DECIMAL(18,2) NULL;
GO
IF COL_LENGTH('dbo.prestamos', 'tipo_tasa') IS NULL
  ALTER TABLE dbo.prestamos ADD tipo_tasa NVARCHAR(3) NULL
    CONSTRAINT CK_prestamos_tipo_tasa CHECK (tipo_tasa IN ('EA', 'MV'));
GO
IF COL_LENGTH('dbo.prestamos', 'numero_cuotas') IS NULL
  ALTER TABLE dbo.prestamos ADD numero_cuotas INT NULL
    CONSTRAINT CK_prestamos_numero_cuotas CHECK (numero_cuotas BETWEEN 1 AND 600);
GO
IF COL_LENGTH('dbo.prestamos', 'valor_cuota') IS NULL
  ALTER TABLE dbo.prestamos ADD valor_cuota DECIMAL(18,2) NULL;
GO
IF COL_LENGTH('dbo.prestamos', 'dia_pago') IS NULL
  ALTER TABLE dbo.prestamos ADD dia_pago TINYINT NULL
    CONSTRAINT CK_prestamos_dia_pago CHECK (dia_pago BETWEEN 1 AND 31);
GO
IF COL_LENGTH('dbo.prestamos', 'fecha_primera_cuota') IS NULL
  ALTER TABLE dbo.prestamos ADD fecha_primera_cuota DATETIME2(0) NULL;
GO
IF COL_LENGTH('dbo.prestamos', 'cuotas_previas') IS NULL
  ALTER TABLE dbo.prestamos ADD cuotas_previas INT NULL;
GO
