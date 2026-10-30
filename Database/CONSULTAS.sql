SELECT * FROM usuarios
SELECT * FROM categorias

SELECT * FROM cuentas
SELECT * FROM tipos_transaccion
SELECT * FROM metodos_pago

SELECT * FROM metas
SELECT * FROM aportes_metas

SELECT * FROM prestamos
SELECT * FROM pagos_prestamos

SELECT * FROM presupuestos

SELECT * FROM transacciones ORDER BY fecha_transaccion DESC
SELECT * FROM pagos_nfc

SELECT * FROM pagos_recurrentes

SELECT * FROM tarjetas_nfc
SELECT * FROM pagos_nfc
SELECT * FROM dispositivos_nfc

SELECT * FROM log

--DELETE prestamos WHERE id = 7
--DELETE transacciones WHERE id = 58
--DELETE cuentas
--DELETE categorias WHERE id = 14
--DELETE dispositivos_nfc WHERE id = 2


/*
Eliminar todos los registros de todas las tablas de la base de datos FinanzasApiApp.
*/
-- USE FinanzasApiApp;
-- GO

-- SET XACT_ABORT ON;

-- BEGIN TRY
--     BEGIN TRANSACTION;

--     DELETE FROM dbo.pagos_nfc;
--     DELETE FROM dbo.aportes_metas;
--     DELETE FROM dbo.pagos_prestamos;
--     DELETE FROM dbo.prestamos;
--     DELETE FROM dbo.pagos_recurrentes;
--     DELETE FROM dbo.presupuestos;
--     DELETE FROM dbo.metas;
--     DELETE FROM dbo.transacciones;
--     DELETE FROM dbo.tarjetas_nfc;
--     DELETE FROM dbo.dispositivos_nfc;
--     DELETE FROM dbo.categorias;
--     DELETE FROM dbo.cuentas;
--     DELETE FROM dbo.usuarios;

--     COMMIT TRANSACTION;
-- END TRY
-- BEGIN CATCH
--     IF @@TRANCOUNT > 0
--         ROLLBACK TRANSACTION;

--     THROW;
-- END CATCH;