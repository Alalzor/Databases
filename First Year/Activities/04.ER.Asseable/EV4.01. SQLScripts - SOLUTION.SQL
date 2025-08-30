/* SCRIPT 1
   Create a function that returns the number of times a target has been attacked. 
   The function must receive the target identifier and return the number of attacks, 
   or raise an error if the target does not exist. */

DELIMITER //
DROP FUNCTION IF EXISTS get_target_attacks //
CREATE FUNCTION get_target_attacks(p_ip_target VARCHAR(15), p_service VARCHAR(20))
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN

   IF (SELECT COUNT(*) FROM target WHERE ip_target=p_ip_target AND service=p_service) = 0
     THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =  
        '\nUnexpected parameter\n*****\n====> Target does not exists.\n*****\n';
   END IF;
    
   RETURN (SELECT COUNT(DISTINCT type_at,index_at)
           FROM effect
           WHERE ip_target=p_ip_target AND service=p_service);

END //
SELECT get_target_attacks('54.152.23.14', 'HTTPS') AS n_attacks// -- 4
SELECT get_target_attacks('104.26.1.128', 'PaaS') AS n_attacks// -- 0
SELECT get_target_attacks('54.152.23.14', 'FTP') AS n_attacks// -- Error

DELIMITER ;

/* SCRIPT 2
   Create a function that receives a timestamp and returns only the date part of it. 
   If the timestamp is not valid the function must raise an error. */

DELIMITER //
DROP FUNCTION IF EXISTS get_date_part //
CREATE FUNCTION get_date_part(p_timestamp_at TIMESTAMP)
RETURNS DATE
DETERMINISTIC
BEGIN

   IF p_timestamp_at IS NULL
   THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =  
      '\nUnexpected parameter\n*****\n====> Timestamp is NULL.\n*****\n';
   END IF;
    
   RETURN DATE(p_timestamp_at);

END //

SELECT get_date_part('2021-06-01 12:30:45') AS date_part// -- 2021-06-01
SELECT get_date_part(NULL) AS date_part// -- User Error
SELECT get_date_part('Hi') AS date_part// -- Default error

DELIMITER ;

/* Create a procedure that displays the attacks that have been found by a given employee 
on the same day that they worked in collaboration with another employee. The procedure must 
receive an employee *alias* and display the attack identifier, the *timestamp_at* of the attack 
and the *alias* of the employee who worked with them that day. */

DELIMITER //
DROP PROCEDURE IF EXISTS attacks_found_by_employee //
CREATE PROCEDURE attacks_found_by_employee(pi_alias VARCHAR(20))
BEGIN

   IF (SELECT alias FROM employee WHERE alias=pi_alias) IS NULL
   THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =  
      '\nUnexpected parameter\n*****\n====> Employee does not exists.\n*****\n';
   END IF;
    
   /* Employee table can be skipped as alias is validated and same as found_by.
      We need to show when the employee who found the attack were on Emp1 or on
      Emp2 in collaboration table */
   SELECT A.type_code, A.index_at, A.timestamp_at, C.emp1 as Collaborator
   FROM attack A, collaborate C 
   WHERE A.found_by = pi_alias AND C.emp2 = A.found_by
   AND get_date_part(A.timestamp_at) = C.day_col
   UNION
   SELECT A.type_code, A.index_at, A.timestamp_at, C.emp2
   FROM attack A, collaborate C 
   WHERE A.found_by = pi_alias AND C.emp1 = A.found_by
   AND get_date_part(A.timestamp_at) = C.day_col;

END //

CALL attacks_found_by_employee('Morpheus')// -- Error
CALL attacks_found_by_employee('MrSmith')// -- 0 rows
/* There is no data in the database that matches the conditions, so we are going to
   insert some data to test the procedure, these attacks happen when MrSmith was
   collaborating as Emp1 and as Emp2 */
START TRANSACTION//
INSERT INTO attack VALUES
('XSS',2, 'MrSmith', '2017-11-03 12:30:45'),
('XSS',3, 'MrSmith', '2019-12-12 01:15:22')//

CALL attacks_found_by_employee('MrSmith')// -- 2 rows 
ROLLBACK//

DELIMITER ;

/* SCRIPT 3
   Create a procedure that receives a *type_code* and displays a report about the attacks of that type. 
   For each attack, the report must display a table with the *index_at*, *timestamp_at*, *found_by* 
   (1 row) and a second table with the *eff_description*, *severity* and target identifier for each 
   effect of the attack. */

DELIMITER //
DROP PROCEDURE IF EXISTS report_attack_type //
CREATE PROCEDURE report_attack_type(pi_type VARCHAR(5))
BEGIN

   DECLARE v_cont INT DEFAULT 1;
   DECLARE v_total INT;
   
   IF (SELECT code_type FROM at_type WHERE code_type=pi_type) IS NULL
   THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =  
      '\nUnexpected parameter\n*****\n====> Attack type does not exists.\n*****\n';
   END IF;
   
   SELECT MAX(index_at) INTO v_total
   FROM attack WHERE type_code=pi_type;

   IF v_total IS NULL
   THEN
      SELECT 'No attacks of this type' AS 'Report';
   ELSE
      REPEAT
         SELECT index_at, timestamp_at, found_by
         FROM attack
         WHERE type_code = pi_type AND index_at = v_cont;

         SELECT eff_description, severity, ip_target, service
         FROM effect
         WHERE type_at = pi_type AND index_at = v_cont;
         
         SET v_cont = v_cont + 1;
      UNTIL v_cont > v_total
      END REPEAT; 
   END IF;
   
END //

CALL report_attack_type('RCE')// -- No attacks
CALL report_attack_type('SQLi')// -- 6 attacks
CALL report_attack_type('SQLI')// -- Error

DELIMITER ;

/* SCRIPT 4
   Create a procedure to insert a new attack. The procedure must receive a *type_code* and insert the new
   attack with the current timestamp and the *index_at* field being the next number for that type of attack. 
   The founder of the attack must be the user that is executing the procedure, without host part. If the user 
   is not an employee, then *found_by* will be empty. Make the necessary arrangements to check the procedure 
   works correctly.

   If the *type_code* is not valid, the procedure must raise an error. 
   The procedure must "return" 1 if the attack has been inserted by an employee and 0 if it was not. */

DELIMITER //

/* We will use get_user() function developed in the unit */
DROP FUNCTION IF EXISTS get_user//
CREATE FUNCTION get_user ()
RETURNS CHAR(20)
DETERMINISTIC NO SQL
BEGIN
   RETURN SUBSTRING_INDEX(USER(), '@', 1);
END//

DROP PROCEDURE IF EXISTS insert_attack //
CREATE PROCEDURE insert_attack(pi_type VARCHAR(5), OUT po_ret BOOLEAN)
BEGIN

   DECLARE v_index INT DEFAULT 0;
   DECLARE v_host VARCHAR(20);


   START TRANSACTION;

   IF (SELECT code_type FROM at_type WHERE code_type=pi_type) IS NULL
   THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =  
      '\nUnexpected parameter\n*****\n====> Attack type does not exists.\n*****\n';
   END IF;
  
   /* This way v_host will contain the user if it is an employee, otherwise it will be null */
   SELECT alias INTO v_host FROM employee WHERE alias=get_user();

   /* We get the number of attacks for the type, we assume there are no gaps in the index */
   SELECT COUNT(index_at) INTO v_index FROM attack WHERE type_code=pi_type;

   INSERT INTO attack VALUES (pi_type, v_index+1, v_host, NOW());

   COMMIT;

   IF v_host IS NULL
   THEN
      SET po_ret = 0;
   ELSE
      SET po_ret = 1;
   END IF;

END //

CALL insert_attack('SQLI', @ret)// -- Error
SELECT @ret// -- NULL
CALL insert_attack('RCE', @ret)// -- index_at 1 and found_by is NULL
SELECT * FROM attack WHERE type_code='RCE' ORDER BY index_at//
SELECT @ret// -- 0 Your user is not an employee

-- Create user Neo and give permissions to execute any procedure in database
CREATE USER 'Neo'@'localhost' IDENTIFIED BY 'Neo'//
GRANT EXECUTE ON db_csd.* TO 'Neo'@'localhost'//

-- After switching to user Neo, insert an attack
CALL insert_attack('SQLi', @ret); -- index_at 7 and found_by is Neo
SELECT @ret; -- 1 Neo is an employee
/* To check the attack table must switch back to your user or give Neo 
   SELECT permission on at least attack table */
SELECT * FROM attack WHERE type_code='SQLi' ORDER BY index_at;

