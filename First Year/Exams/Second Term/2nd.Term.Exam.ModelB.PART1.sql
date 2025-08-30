/* Query 1
Show the rep_number, id_emp and score of the reports produced in 2023 that have caused an 
incentive of 120.00 inc_value or are evaluating employees that have not 'Manager' 
emp_position, sort by* score, from lowest to highest. */

SELECT DISTINCT R.rep_number, R.id_emp, R.score
FROM employee E
INNER JOIN report R ON E.id_emp = R.id_emp
LEFT JOIN incentive I ON R.id_emp = I.id_emp AND R.rep_number = I.rep_number
WHERE R.rep_date BETWEEN '2023-01-01' AND '2023-12-31'
AND (I.inc_value = 120.00 OR E.emp_position <> 'Manager')
ORDER BY R.score;

/* Query 2
Show the full name and salary of the employees that have not received any bonus and do not 
appear in any report. Order the list by salary, from highest to lowest, and full name. */

-- NOT EXISTS
SELECT full_name, salary
FROM employee E
WHERE NOT EXISTS (
    SELECT 1 FROM bonus B
    WHERE E.id_emp = B.id_emp)
AND NOT EXISTS (
    SELECT 1 FROM report R
    WHERE E.id_emp = R.id_emp)
ORDER BY salary DESC, full_name;

-- NOT IN
SELECT full_name, salary
FROM employee E
WHERE E.id_emp NOT IN (SELECT DISTINCT id_emp FROM bonus)
AND E.id_emp NOT IN (SELECT DISTINCT id_emp FROM report)
ORDER BY salary DESC, full_name;

/* Query 3
Create a view that shows the id_emp and full_name of all the employees and the number of rates
that they have received. Order the list by that number of rates, from highest to lowest. */

CREATE VIEW rates_received AS
SELECT E.id_emp, E.full_name, COUNT(*) AS num_rates
FROM employee E LEFT JOIN rate R
ON E.id_emp = R.emp_rated
GROUP BY E.id_emp, E.full_name
ORDER BY 3 DESC;

/* Query 4
Show the emp_position, full_name and the salary of the employee/s with the lowest salary of 
each emp_position; show only the results when that salary is higher than the highest bonus 
received by the employees with 'Manager' emp_position. Sort by emp_position in reverse 
alphabetical order. */

SELECT emp_position, full_name, salary
FROM employee E
WHERE salary = (
    SELECT MIN(salary)
    FROM employee E1
    WHERE E1.emp_position = E.emp_position)
AND salary > (
    SELECT MAX(bonus)
    FROM bonus B, employee E1
    WHERE B.id_emp = E1.id_emp 
    AND E1.emp_position = 'Manager')
ORDER BY emp_position DESC;

/* Script 1
Create a procedure that receives an id_emp and shows a number of tables equivalent to the number of
reports about that employee. Each table will contain the rep_number, inc_data and inc_value of the 
incentives that the employee has received due to that report (it can show an empty set if there are 
no incentives related to that rep_number). The procedure should "return" the number of existing
reports about that employee. If the employee does not exist, the procedure will generate an error. */

DELIMITER $$
DROP PROCEDURE IF EXISTS show_incentives$$
CREATE PROCEDURE show_incentives(pi_emp INT, OUT po_num_reports INT)
BEGIN
    DECLARE v_cont INT DEFAULT 1;

    IF NOT EXISTS (SELECT 1 FROM employee WHERE id_emp = pi_emp) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found';
    END IF;

    SELECT COUNT(*) INTO po_num_reports
    FROM report
    WHERE id_emp = pi_emp;

    
    WHILE v_cont <= po_num_reports DO
        SELECT rep_number, inc_date, inc_value
        FROM incentive
        WHERE id_emp = pi_emp AND rep_number = v_cont;
        SET v_cont = v_cont + 1;
    END WHILE;
END$$
DELIMITER ;

-- Emp 4 has 2 reports with 2 incentives each
CALL show_incentives(4, @result);
SELECT @result AS num_reports; 
-- Emp 2 has 0 reports, no screen output
CALL show_incentives(2, @result);
SELECT @result AS num_reports; 
-- Emp 3 has 2 reports, but not incentives, "Empty sets" in the out
CALL show_incentives(3, @result);
SELECT @result AS num_reports; 
-- Emp 11 does not exist, error
CALL show_incentives(11, @result);

/* Script 2
Create a function that receives an id_emp and returns the average of all the rates that employee 
has received (not the avg_rating field) if the employee is found on the database. If the employee 
has not received any rate the function can return NULL value. Then use the function to UPDATE the
field avg_rating (that has random data right now) with the correct number, for every employee on
the database. */

DELIMITER $$
DROP FUNCTION IF EXISTS avg_rates_received$$
CREATE FUNCTION avg_rates_received(pi_emp INT)
RETURNS DECIMAL(4,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM employee WHERE id_emp = pi_emp) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found';
    END IF;
    
    RETURN (SELECT AVG(score) FROM rate WHERE emp_rated = pi_emp);
END$$
DELIMITER ;

-- Testing the function
SELECT avg_rates_received(2); -- 5.29
SELECT avg_rates_received(7); -- NULL 
SELECT avg_rates_received(15); -- Error

-- Updating the avg_rating field
UPDATE employee
SET avg_rating = avg_rates_received(id_emp);

-- Avg data can suffer from integer division or rounding errors, but we will ignore that.

/* User Management
Create a new user with the following characteristics:
- Username: Your first surname
- Password: Your Name
- The user is allowed to connect from anywhere.
- Permissions: SELECT on the employee and rate tables.
- The user can give its permissions to others.

Create a role called *emp_func* that has the permission to EXECUTE the function created in the Script 2.
Give the user the role emp_func so it can be used without further configuration. */

CREATE USER 'Surname'@'%' IDENTIFIED BY 'Name';
GRANT SELECT ON EmployeeDB.employee TO 'Surname'@'%' WITH GRANT OPTION;
GRANT SELECT ON EmployeeDB.rate TO 'Surname'@'%' WITH GRANT OPTION;

CREATE ROLE emp_func;
GRANT EXECUTE ON FUNCTION EmployeeDB.avg_rates_received TO emp_func;

GRANT emp_func TO 'Surname'@'%';
SET DEFAULT ROLE emp_func TO 'Surname'@'%';

/* Data Security
Write 2 MySQL scripts, one to export all the data from the *incentive* table to a file called incentive_data.csv 
and another to replace the data on the incentive table using that file. Explain the necessary configuration 
requirements to ensure the scripts can be executed without any problem and write the command to launch the script
on the command line of the terminal. */

-- Exporting data
SELECT * INTO OUTFILE '/exports/incentive_data.csv'
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM EmployeeDB.incentive;

-- Importing data
TRUNCATE TABLE EmployeeDB.incentive;
-- REPLACE option can be used here instead of TRUNCATE sentence but won't completely delete existing data
LOAD DATA INFILE '/exports/incentive_data.csv'
INTO TABLE EmployeeDB.incentive
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';

/* Configuration requirements
The user executing the script must have FILE privilege and the file path must be accessible by the MySQL server.
The file must not exist or be writable by the MySQL server.
secure_file_priv on the configuration file (my.cnf/my.ini) must be set to '/exports/'. */

-- Command to launch the scripts
mysql -u root -p < /path/script.sql
-- If SELECT/LOAD sentences hadn't included the database name.
mysql -u root -p EmployeeDB < /path/script.sql
