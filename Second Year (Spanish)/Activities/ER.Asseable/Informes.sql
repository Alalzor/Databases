--Creacion del procedimiento para exportar la informacion cada 3 meses--

DELIMITER //

CREATE PROCEDURE informe_celdas()
BEGIN
    -- Generar informe en un archivo CSV con las celdas, número de criminales y plazas libres --
    SELECT 
        c.id_celda,
        c.capacidad AS capacidad_total,
        COUNT(u.id_criminal) AS criminales_en_celda,
        (c.capacidad - COUNT(u.id_criminal)) AS plazas_libres
    INTO OUTFILE '/var/lib/mysql-files/informe_celdas.csv'
    FIELDS TERMINATED BY ',' 
    ENCLOSED BY '"' 
    LINES TERMINATED BY '\n'
    FROM celdas c
    LEFT JOIN ubicacion u ON c.id_celda = u.id_celda
    WHERE u.fecha_entrada IS NOT NULL AND (u.fecha_salida IS NULL OR u.fecha_salida > CURDATE())
    GROUP BY c.id_celda;
END;
//

DELIMITER ;


--Ahora esto se ejecutaria manualmente llamando al procediemtno cada 3 meses--
-- si queremos hacer una automatizacion necesitariamos crear un evento--

SET GLOBAL event_scheduler = ON;

CREATE EVENT informe_trimestral
ON SCHEDULE EVERY 3 MONTH STARTS '2025-02-11 00:00:00'
DO CALL informe_celdas();


--!Comprobacion--

CALL informe_celdas();



--Procedimiento misiones--

DELIMITER //

CREATE PROCEDURE detalles_mision(IN p_id_mision INT)
BEGIN
    DECLARE total_troopers INT DEFAULT 0;
    DECLARE mensaje VARCHAR(255);

    -- Obtener el total de troopers asignados a la misión--
    SELECT COUNT(a.id_trooper) INTO total_troopers
    FROM asignacion a
    WHERE a.id_mision = p_id_mision;

    -- Si la misión no tiene troopers, asignar mensaje y terminar--
    IF total_troopers = 0 THEN
        SET mensaje = 'No hay troopers asignados a esta misión.';
        SELECT mensaje AS mensaje; -- Mostramos el mensaje aquí y salimos--
    ELSE
        -- Mostrar detalles de la misión--
        SELECT m.nombre_mision, m.objetivo, total_troopers
        FROM misiones m
        WHERE m.id_mision = p_id_mision;

        -- Mostrar lista de troopers por cada rango si existen--
        SELECT id_trooper, serie FROM troopers 
        WHERE id_trooper IN (
            SELECT id_trooper FROM asignacion WHERE id_mision = p_id_mision
        ) AND rango = 'soldado';

        SELECT id_trooper, serie FROM troopers 
        WHERE id_trooper IN (
            SELECT id_trooper FROM asignacion WHERE id_mision = p_id_mision
        ) AND rango = 'sargento';

        SELECT id_trooper, serie FROM troopers 
        WHERE id_trooper IN (
            SELECT id_trooper FROM asignacion WHERE id_mision = p_id_mision
        ) AND rango = 'capitan';
    END IF;
END;
//

DELIMITER ;


--Comprobacion--
CALL detalles_mision(1);

--Error--
CALL detalles_mision(999);

--Mensaje y abajo no hay troopers--



---Creacion del listado de todas las misiones llamando al anterior procedure--

DELIMITER //

CREATE PROCEDURE mostrar_todas_las_misiones()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE id_mision_actual INT;

    -- Definir cursor para recorrer todas las misiones
    DECLARE misiones_cursor CURSOR FOR 
        SELECT id_mision FROM misiones;
    
    -- Manejador de errores para cuando no haya más misiones
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Abrir cursor
    OPEN misiones_cursor;

    misiones_loop: LOOP
        FETCH misiones_cursor INTO id_mision_actual;
        
        -- Si no hay más misiones, salir del loop
        IF done THEN
            LEAVE misiones_loop;
        END IF;

        -- Llamar al procedimiento que muestra detalles de cada misión
        CALL detalles_mision(id_mision_actual);
    END LOOP;

    -- Cerrar cursor
    CLOSE misiones_cursor;

END;
//

DELIMITER ;

--Comprobacion--

CALL mostrar_todas_las_misiones();

--Error--
DELETE FROM asignacion WHERE id_mision IN (SELECT id_mision FROM misiones);
DELETE FROM misiones;

CALL mostrar_todas_las_misiones();

--no se muestra nada--


--¿Qué limitaciones nos encontramos con estos procedimientos? --

Si hay muchas misiones o troopers, el procedimiento puede ser lento y consumir muchos recursos.
No se pueden realizar operaciones complejas o que requieran de un control más detallado.

--¿Se podrían usar o modificar para realizarse automáticamente de forma anual?--

Si, se podria crear un evento que se ejecute cada año para generar un informe anual.

CREATE EVENT informe_anual
ON SCHEDULE EVERY 1 YEAR STARTS '2025-02-11 00:00:00'
DO CALL informe_celdas(); --POR EJEMEPLO EN EL CASO DE INFORME DE CELDAS--

-- ¿Y para generar informes escritos o en un archivo? No se pide que lo hagas, solo que lo analices.--

Si, se podria modificar el procedimiento para que en lugar de exportar a un archivo csv, 
se exporte a un archivo de texto o pdf, tambien en una tabla de informes en la base de datos.
Mysql nos da bastantes opciones para poder exportar estos datos a un archivo, siempre y cuando
tengamos los permisos necesarios para poder hacerlo, la ruta de salida tambien debe ser accesible,
y el formato de salida debe ser compatible con el archivo que queremos generar.

Acordarnos en caso de hacerlo de modificar el procediemtno ya creado en laa base de datos y no crear uno nuevo.

