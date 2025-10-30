-- Script para crear datos de prueba
-- Ejecuta esto en SQL Server Management Studio

-- Verificar si existe el usuario 1, si no, crearlo
IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = 1)
BEGIN
    INSERT INTO usuarios (nombre, email, contrasena, activo, fecha_creacion)
    VALUES ('Usuario Prueba', 'prueba@test.com', '$2b$10$HASH_PLACEHOLDER', 1, GETDATE());
END

-- Insertar algunas cuentas de prueba
IF NOT EXISTS (SELECT 1 FROM cuentas WHERE usuario_id = 1 AND nombre = 'Efectivo')
BEGIN
    INSERT INTO cuentas (usuario_id, nombre, tipo, moneda, saldo_inicial, color, icono, activa, fecha_creacion)
    VALUES (1, 'Efectivo', 'EFECTIVO', 'COP', 100000, '#10B981', 'wallet', 1, GETDATE());
END

IF NOT EXISTS (SELECT 1 FROM cuentas WHERE usuario_id = 1 AND nombre = 'Banco')
BEGIN
    INSERT INTO cuentas (usuario_id, nombre, tipo, moneda, saldo_inicial, color, icono, activa, fecha_creacion)
    VALUES (1, 'Banco', 'BANCARIA', 'COP', 500000, '#3B82F6', 'account_balance', 1, GETDATE());
END

-- Insertar algunas categorías de prueba
IF NOT EXISTS (SELECT 1 FROM categorias WHERE usuario_id = 1 AND nombre = 'Transporte')
BEGIN
    INSERT INTO categorias (usuario_id, nombre, tipo, color, icono, activo, fecha_creacion)
    VALUES (1, 'Transporte', 'GASTO', '#EF4444', 'directions_bus', 1, GETDATE());
END

IF NOT EXISTS (SELECT 1 FROM categorias WHERE usuario_id = 1 AND nombre = 'Comida')
BEGIN
    INSERT INTO categorias (usuario_id, nombre, tipo, color, icono, activo, fecha_creacion)
    VALUES (1, 'Comida', 'GASTO', '#F59E0B', 'restaurant', 1, GETDATE());
END

IF NOT EXISTS (SELECT 1 FROM categorias WHERE usuario_id = 1 AND nombre = 'Salario')
BEGIN
    INSERT INTO categorias (usuario_id, nombre, tipo, color, icono, activo, fecha_creacion)
    VALUES (1, 'Salario', 'INGRESO', '#10B981', 'attach_money', 1, GETDATE());
END

SELECT 'Datos de prueba insertados correctamente';

