-- =====================================================
-- ACTUALIZAR MONEDA PREDETERMINADA A COP (Colombia)
-- =====================================================

USE FinanzasApiApp
GO

-- Actualizar la moneda predeterminada para todos los usuarios existentes
UPDATE usuarios
SET moneda_predeterminada = 'COP'
WHERE moneda_predeterminada = 'COP' OR moneda_predeterminada IS NULL;

GO

-- Actualizar el valor predeterminado en la tabla
-- Primero eliminar el constraint existente con otro nombre si existe
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('usuarios') 
AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('usuarios'), 'moneda_predeterminada', 'ColumnId');

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE usuarios DROP CONSTRAINT ' + @ConstraintName);
END
GO

-- Agregar el nuevo constraint
ALTER TABLE usuarios
ADD CONSTRAINT DF_moneda_predeterminada DEFAULT 'COP' FOR moneda_predeterminada;
GO

-- Actualizar tabla CUENTAS
-- Primero actualizar datos existentes
UPDATE cuentas
SET moneda = 'COP'
WHERE moneda = 'COP';

GO

-- Eliminar constraint existente de cuentas
DECLARE @ConstraintNameCuentas NVARCHAR(200);
SELECT @ConstraintNameCuentas = name FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('cuentas') 
AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('cuentas'), 'moneda', 'ColumnId');

IF @ConstraintNameCuentas IS NOT NULL
BEGIN
    EXEC('ALTER TABLE cuentas DROP CONSTRAINT ' + @ConstraintNameCuentas);
END
GO

-- Agregar nuevo constraint para cuentas
ALTER TABLE cuentas
ADD CONSTRAINT DF_cuentas_moneda DEFAULT 'COP' FOR moneda;
GO

-- Actualizar tabla TRANSACCIONES
-- Primero actualizar datos existentes
UPDATE transacciones
SET moneda = 'COP'
WHERE moneda = 'COP';

GO

-- Eliminar constraint existente de transacciones
DECLARE @ConstraintNameTransacciones NVARCHAR(200);
SELECT @ConstraintNameTransacciones = name FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('transacciones') 
AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('transacciones'), 'moneda', 'ColumnId');

IF @ConstraintNameTransacciones IS NOT NULL
BEGIN
    EXEC('ALTER TABLE transacciones DROP CONSTRAINT ' + @ConstraintNameTransacciones);
END
GO

-- Agregar nuevo constraint para transacciones
ALTER TABLE transacciones
ADD CONSTRAINT DF_transacciones_moneda DEFAULT 'COP' FOR moneda;
GO

-- Verificar los cambios en las tres tablas
PRINT '===== USUARIOS ====='
SELECT 
    id, 
    nombre, 
    email, 
    moneda_predeterminada 
FROM usuarios;

PRINT '===== CUENTAS ====='
SELECT 
    id, 
    usuario_id, 
    nombre, 
    moneda 
FROM cuentas;

PRINT '===== TRANSACCIONES ====='
SELECT 
    id, 
    usuario_id, 
    monto, 
    moneda 
FROM transacciones;

PRINT '===== RESUMEN DE CAMBIOS ====='
PRINT 'Moneda predeterminada actualizada a COP en:'
PRINT '- usuarios.moneda_predeterminada'
PRINT '- cuentas.moneda'
PRINT '- transacciones.moneda'

GO

