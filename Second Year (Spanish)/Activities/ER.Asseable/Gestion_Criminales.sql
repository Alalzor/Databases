--!Creamos un trigger para cuando se intente eliminar--

CREATE TRIGGER prevent_delete_criminal
BEFORE DELETE ON criminales
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se puede eliminar un criminal de la base de datos.';
END;

--!Comprobacion--
DELETE FROM criminales WHERE id_criminal = 1;


--!Creamos una funcion para contar a los rebeldes--

DELIMITER //
CREATE FUNCTION contar_rebeldes(id_celda_param INT) RETURNS INT
BEGIN
    DECLARE total_rebeldes INT;
    
    SELECT COUNT(*) INTO total_rebeldes
    FROM ubicacion u
    WHERE u.id_celda = id_celda_param
        AND u.fecha_entrada IS NOT NULL
        AND (u.fecha_salida IS NULL OR u.fecha_salida > CURDATE());
    
    RETURN total_rebeldes;
END //

DELIMITER ;

--! Aqui nos topamos los criminales con fecha null, no se consideran como ingresados --
UPDATE ubicacion SET fecha_entrada = '2024-01-01' WHERE id_criminal = 1 AND id_celda = 201;

--!Si actualizamos ahora la consulta con el preso en la celda 201 da= 1--
SELECT contar_criminales_celda(201) AS total_criminales;




--Crear el conteo de criminales por celdas-
DELIMITER //
CREATE TRIGGER verificar_capacidad
BEFORE INSERT ON ubicacion
FOR EACH ROW
BEGIN
    DECLARE capacidad_max INT;
    DECLARE ocupacion_actual INT;

    SELECT capacidad INTO capacidad_max FROM celdas WHERE id_celda = nuevo.id_celda;
    
    SELECT COUNT(*) INTO ocupacion_actual
    FROM ubicacion
    WHERE id_celda = nuevo.id_celda
        AND fecha_entrada IS NOT NULL
        AND (fecha_salida IS NULL OR fecha_salida > CURDATE());

    IF ocupacion_actual >= capacidad_max THEN
        SIGNAL SQLSTATE '46210'
        SET MESSAGE_TEXT = 'No se puede asignar más rebeldes a esta celda. Capacidad máxima alcanzada.';
    END IF;
END //

DELIMITER ;

--!Vamos a actualizar la fecha de los presos en la celda 302 para que los cuenta en la celda--
UPDATE ubicacion SET fecha_entrada = '2024-01-01' WHERE id_criminal = 2 AND id_celda = 302;


--!vamos a insertar  nuevos criminales--
INSERT INTO criminales (id_criminal, nombre, especie, causa_detencion, libertad, estado)
VALUES (1003, 'Stormtrooper X', 'Humano', 'Traición', FALSE, 1);

INSERT INTO criminales (id_criminal, nombre, especie, causa_detencion, libertad, estado)
VALUES (1003, 'Stormtrooper X', 'CLON', 'Traición', FALSE, 1);

--!Ahora vamos a insertar a los criminales en la celda 302--

INSERT INTO ubicacion (id_criminal, id_celda, fecha_entrada)
VALUES (1002, 302, '2024-01-01');

--!Si intentamos insertar un nuevo criminal en la celda 302, nos dara error--
INSERT INTO ubicacion (id_criminal, id_celda, fecha_entrada)
VALUES (1003, 302, '2024-01-01');



--4. Crear un trigger para que ningun criminal sin libertad tenga una celda--


DELIMITER //

CREATE TRIGGER verificar_criminal_celda
BEFORE INSERT ON criminales
FOR EACH ROW
BEGIN
    DECLARE tiene_celda INT;

    -- Si el criminal NO tiene libertad (libertad = FALSE), debe tener una celda asignada
    IF NEW.libertad = FALSE THEN
        SELECT COUNT(*) INTO tiene_celda FROM ubicacion WHERE id_criminal = NEW.id_criminal;

        IF tiene_celda = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Los criminales sin libertad deben tener al menos una celda asignada.';
        END IF;
    END IF;
END;
//

DELIMITER ;

--!Comprobacion de que funciona--

INSERT INTO criminales (id_criminal, nombre, especie, causa_detencion, libertad, estado)
VALUES (1005, 'Rebelde X', 'Humano', 'Terrorismo', TRUE, 1);





--5. Crear un procedimiento para registrar el criminal con los datos del enunciado 4.1.5 y ademas quitamos la opcion de insercion manual en la tabla criminales.

DELIMITER //

CREATE PROCEDURE registrar_criminal(
    IN p_id_criminal INT,
    IN p_nombre VARCHAR(100),
    IN p_especie VARCHAR(50),
    IN p_causa_detencion TEXT,
    IN p_id_celda INT
)
BEGIN
    DECLARE capacidad_max INT;
    DECLARE ocupacion_actual INT;

    --  Evitar que la celda sea NULL
    IF p_id_celda IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Debe asignar una celda válida al criminal.';
    END IF;

    --  Iniciar transacción para evitar que se inserte un criminal sin celda
    START TRANSACTION;

    --  Verificar la capacidad de la celda
    SELECT capacidad INTO capacidad_max FROM celdas WHERE id_celda = p_id_celda;

    --  Si la celda no existe, cancelar la operación
    IF capacidad_max IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La celda especificada no existe.';
    END IF;
    -- Contar cuántos criminales hay actualmente en la celda
    SELECT COUNT(*) INTO ocupacion_actual
    FROM ubicacion
    WHERE id_celda = p_id_celda
        AND fecha_entrada IS NOT NULL
        AND (fecha_salida IS NULL OR fecha_salida > CURDATE());

    --  Si la celda ya está llena, cancelar la operación
    IF ocupacion_actual >= capacidad_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede asignar el criminal. Celda llena.';
    END IF;

    --  Insertar el criminal en `criminales` con `libertad = FALSE`
    INSERT INTO criminales (id_criminal, nombre, especie, causa_detencion, libertad, estado)
    VALUES (p_id_criminal, p_nombre, p_especie, p_causa_detencion, FALSE, 1);

    --  Asignar el criminal a la celda con la fecha de entrada del día actual
    INSERT INTO ubicacion (id_criminal, id_celda, fecha_entrada)
    VALUES (p_id_criminal, p_id_celda, CURDATE());

    --  Confirmar la transacción (ambas inserciones deben ejecutarse juntas)
    COMMIT;

END;
//

DELIMITER ;



--Comprobacion--

CALL registrar_criminal(5003, 'Grehiborg', 'R2D2', 'Chatarrero', 301);

--error--


--!Al intentar insertar un criminal con libertad en la celda 301, nos dara error 
--porque el trigger anterior no lo permite--
--entonces lo borramosn --

DROP TRIGGER IF EXISTS verificar_criminal_celda;


-- Ahora  lo sustituimos por un trigger en la tabla de ubicacion--

DELIMITER //

CREATE TRIGGER verificar_asignacion_celda
BEFORE INSERT ON ubicacion
FOR EACH ROW
BEGIN
    DECLARE libertad_criminal BOOLEAN;

    -- Obtener el estado de libertad del criminal
    SELECT libertad INTO libertad_criminal 
    FROM criminales 
    WHERE id_criminal = NEW.id_criminal;

    --  Si el criminal no existe en `criminales`, bloquear la inserción en `ubicacion`
    IF libertad_criminal IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El criminal debe estar registrado antes de asignarle una celda.';
    END IF;

    --  Si el criminal tiene libertad = TRUE, no puede ser asignado a una celda
    IF libertad_criminal = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede asignar celdas a criminales en libertad.';
    END IF;

    --  Si la fecha_entrada es NULL, bloquear la inserción
    IF NEW.fecha_entrada IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los criminales sin libertad deben tener una fecha de entrada válida.';
    END IF;
END;
//

DELIMITER ;


--Ahora deberia funcionar el procedimiento--

CALL registrar_criminal(5005, 'Darth Maul', 'Zabrak', 'Asesinato', 301);

--Celda llena--


--Otro usuario--
CALL registrar_criminal(5006, 'Obi Wan', 'Humano', 'Traición', 303);

--Corractamente asignado--

--Poniendo celda a null--
CALL registrar_criminal(5006, 'Jabba el Hutt', 'Hutt', 'Contrabando', NULL);

--Error--