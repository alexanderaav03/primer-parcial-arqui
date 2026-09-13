SELECT * FROM rutinas;
SELECT * FROM detalles_rutina;
SELECT * FROM registros_progreso;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';