--Vamos a crear aqui el procedmiento de las misiones y su comprobacion--

DELIMITER //

CREATE PROCEDURE crear_mision(
    IN p_nombre_mision VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_objetivo VARCHAR(500),
    IN p_id_oficial INT,
    IN p_num_troopers INT
)
BEGIN
    DECLARE troopers_disponibles INT;
    DECLARE id_nueva_mision INT;

    --  Iniciar transacción para evitar inserciones parciales
    START TRANSACTION;

    --  Insertar la nueva misión
    INSERT INTO misiones (nombre_mision, descripcion, objetivo, id_oficial)
    VALUES (p_nombre_mision, p_descripcion, p_objetivo, p_id_oficial);

    --  Obtener el ID de la misión recién insertada
    SET id_nueva_mision = LAST_INSERT_ID();

    --  Contar cuántos soldados están disponibles para la asignación
    SELECT COUNT(*) INTO troopers_disponibles
    FROM troopers t
    WHERE rango = 'soldado';

    --  Si no hay suficientes troopers, cancelar la misión
    IF troopers_disponibles < p_num_troopers THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay suficientes soldados disponibles para la misión.';
    END IF;

    --  Asignar los troopers con menos misiones
    INSERT INTO asignacion (id_mision, id_trooper)
    SELECT id_nueva_mision, id_trooper
    FROM (
        SELECT t.id_trooper
        FROM troopers t
        LEFT JOIN asignacion a ON t.id_trooper = a.id_trooper
        WHERE t.rango = 'soldado'
        GROUP BY t.id_trooper
        ORDER BY COUNT(a.id_mision) ASC -- Selecciona los que menos misiones tienen
        LIMIT p_num_troopers
    ) AS troopers_seleccionados;

    --  Confirmar la transacción
    COMMIT;

END;
//

DELIMITER ;


--Al no utilizar un cursor en esta consulta tenemos en comparación una velocidad mas rapida y una carga menor en la bd pero perdemos control sobre la asignacion (reglas en especificao para x troopers)--

--Comprobacion--
CALL crear_mision('Operación Endor', 'Ataque a la base rebelde', 'Destruir la base rebelde', 1, 3);

SELECT * FROM misiones ORDER BY id_mision DESC;
SELECT * FROM asignacion WHERE id_mision = (SELECT MAX(id_mision) FROM misiones);

--Error--

--cuantos soldados tenemos--

SELECT COUNT(*) FROM troopers WHERE rango = 'soldado';
--Probamos el error
CALL crear_mision('Batalla Final', 'Asalto total', 'Conquistar el planeta', 1, 500);

--error no hay suficientes soldados--