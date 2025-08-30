-- 1. Show the attacks found by employees working with hacker whose alias starts with the
--    letter C, the alias of the hacker and a field with the full name of the employee with
--    their alias in this format:  name surname, "alias". Sort the result alphabetically by
--    that field, type_code and at_type.

-- Explicit
SELECT type_code, index_at, H.alias AS hacker,
CONCAT(name_emp,' ',surname_emp,', "',E. alias,'"') AS employee
FROM attack
INNER JOIN employee E ON found_by=E.alias
INNER JOIN hacker H ON E.alias=contact
WHERE H.alias LIKE'C%'
ORDER BY 4, type_code,index_at;

-- Implicit
SELECT type_code, index_at, H.alias AS hacker,
CONCAT(name_emp,' ',surname_emp,', "',E. alias,'"') AS employee
FROM attack, employee E, hacker H
WHERE found_by=E.alias AND E.alias=contact AND H.alias LIKE'C%'
ORDER BY 4, type_code,index_at;

-- 2. Show the name of the target and the average severity of all effects caused by attacks
--    on that target, only if the average is greater than 60%. Sort the result from highest
--    to lowest average severity.

-- GROUP BY
SELECT name_ta, AVG(severity) AS severity_avg
FROM effect E, target T
WHERE E.ip_target=T.ip_target AND E.service=T.service
GROUP BY E.ip_target, E.service, name_ta
HAVING AVG(severity)>0.6
ORDER BY 2 DESC;

-- Derived table with GROUP BY
SELECT name_ta, severity_avg
FROM target T, (SELECT E.ip_target, E.service, 
                AVG(severity) AS severity_avg 
                FROM effect E
                GROUP BY E.ip_target, E.service) S
WHERE T.ip_target=S.ip_target AND T.service=S.service
AND severity_avg>0.6
ORDER BY 2 DESC;

-- Subquery
SELECT name_ta, (SELECT AVG(severity) FROM effect E
                 WHERE  E.ip_target=T.ip_target
                     AND E.service=T.service) AS severity_avg
FROM target T
WHERE (SELECT AVG(severity) FROM effect E
       WHERE  E.ip_target=T.ip_target
           AND E.service=T.service) > 0.6
ORDER BY 2 DESC;

-- 3. Display the aliases of employees who have never worked with another employee,
--    sorted by the last name of the employee. Use the following methods:

-- IN. with DISTINCT and UNION
SELECT alias FROM employee
WHERE alias NOT IN (SELECT DISTINCT emp1 FROM collaborate
                    UNION
                    SELECT DISTINCT emp2 FROM collaborate)
ORDER BY surname_emp;

-- IN. with GROUP BY and UNION
SELECT alias FROM employee
WHERE alias NOT IN (SELECT emp1 FROM collaborate GROUP BY emp1
                    UNION
                    SELECT emp2 FROM collaborate GROUP BY emp2)
ORDER BY surname_emp;

-- IN. with DISTINCT and AND instead of UNION
SELECT alias FROM employee
WHERE alias NOT IN (SELECT DISTINCT emp1 FROM collaborate)
  AND alias NOT IN (SELECT DISTINCT emp2 FROM collaborate)
ORDER BY surname_emp;

-- IN. with GROUP BY and AND instead of UNION
SELECT alias FROM employee
WHERE alias NOT IN (SELECT emp1 FROM collaborate GROUP BY emp1)
  AND alias NOT IN (SELECT emp2 FROM collaborate GROUP BY emp2)
ORDER BY surname_emp;

-- EXISTS
SELECT alias FROM employee
WHERE NOT EXISTS (SELECT 1
                  FROM collaborate
                  WHERE alias=Emp1 OR alias=Emp2)
ORDER BY surname_emp;

-- 4. Show the attacks, their timestamps, and the first and last name of their
--    finders (if any) of **all** attacks of the same type as the most recent
--    attack, except this one. Sort the results by surname and from most recent
--    to oldest.

-- >= ALL
SELECT type_code, index_at, timestamp_at, name_emp, surname_emp
FROM attack
LEFT JOIN employee ON found_by = alias
WHERE type_code = (SELECT type_code FROM attack
                   WHERE timestamp_at>= ALL (SELECT timestamp_at FROM attack))
AND timestamp_at <> (SELECT timestamp_at FROM attack
                     WHERE timestamp_at>= ALL (SELECT timestamp_at FROM attack))
ORDER BY surname_emp, timestamp_at DESC;

-- MAX
SELECT type_code, index_at, timestamp_at, name_emp, surname_emp
FROM attack
LEFT JOIN employee ON found_by = alias
WHERE type_code = (SELECT type_code FROM attack
                   WHERE timestamp_at = (SELECT MAX(timestamp_at) FROM attack))
AND timestamp_at <> (SELECT timestamp_at FROM attack
                     WHERE timestamp_at = (SELECT MAX(timestamp_at) FROM attack))
ORDER BY surname_emp, timestamp_at DESC;

-- Derived table/Inline view
SELECT A.type_code, A.index_at, A.timestamp_at, name_emp, surname_emp
FROM attack A
LEFT JOIN employee ON A.found_by = alias
CROSS JOIN (SELECT type_code,timestamp_at FROM attack
            WHERE timestamp_at = (SELECT MAX(timestamp_at) FROM attack)) LA
WHERE A.type_code = LA.type_code AND A.timestamp_at <> LA.timestamp_at
ORDER BY surname_emp, timestamp_at DESC;

-- 5. List how many attacks each target has received and sort the targets 
--    from least to most attacked.
SELECT ip_target, service, COUNT(DISTINCT type_at,index_at) AS n_attacks
FROM effect E
GROUP BY ip_target, service
ORDER BY 3;

-- Now list the average number of attacks suffered by targets according to 
-- their service.
SELECT E.service, AVG(n_attacks) as avg_attacks
FROM effect E, (SELECT service, COUNT(DISTINCT type_at,index_at) AS n_attacks
                FROM effect E
                GROUP BY ip_target, service) A
WHERE E.service=A.service
GROUP BY service;

-- 6. View that calculates the number of attacks found for each employee working
--    with a hacker whose dni is unknown. The view will show the alias of the 
--    employee, the alias of the hacker and the number of attacks.
CREATE OR REPLACE VIEW attacks_found AS
SELECT E.alias AS employee, H.alias AS hacker, COUNT(found_by) AS at_found
FROM hacker H, employee E, attack
WHERE H.contact=E.alias AND E.alias=found_by
AND H.dni IS NULL
GROUP BY E.alias,H.alias
ORDER BY COUNT(found_by) DESC; 

--  Show which employee(s) has/have found the most and how many attacks that meet 
--  the above conditions, first using the view and then without it.

-- With VIEW

-- Subquery with >= ALL
SELECT employee, at_found
FROM attacks_found 
WHERE at_found >= ALL (SELECT at_found
                      FROM attacks_found);


-- Subquery with MAX
SELECT employee, at_found
FROM attacks_found 
WHERE at_found = ALL (SELECT MAX(at_found)
                      FROM attacks_found);

-- Derived tables/Inline views
SELECT AF.employee, AF.at_found
FROM attacks_found AF, (SELECT MAX(at_found) AS max_at
                        FROM attacks_found) MA
WHERE  AF. at_found = MA.max_at;

-- Without VIEW

-- Subquery with >= ALL (HAVING)
SELECT E.alias, COUNT(found_by) AS at_found
FROM hacker H, employee E, attack A
WHERE E.alias=found_by AND H.contact=E.alias
AND H.dni IS NULL
GROUP BY E.alias
HAVING COUNT(found_by) >= ALL (SELECT COUNT(found_by)
                               FROM hacker H, employee E, attack A
                               WHERE E.alias=found_by AND H.contact=E.alias
                               AND H.dni IS NULL
                               GROUP BY E.alias);

-- Subquery with MAX (HAVING)
SELECT E.alias, COUNT(found_by) AS at_found
FROM hacker H, employee E, attack A
WHERE E.alias=found_by AND H.contact=E.alias
AND H.dni IS NULL
GROUP BY E.alias
HAVING COUNT(found_by) = (SELECT MAX(at_f)
                          FROM (SELECT COUNT(found_by) AS at_f
                                FROM hacker H, employee E, attack A
                                WHERE E.alias=found_by AND H.contact=E.alias
                                AND H.dni IS NULL
                                GROUP BY E.alias) AF);

-- Derived table/Inline view
SELECT E.alias, COUNT(found_by) AS at_found
FROM hacker H, employee E, attack A,
(SELECT MAX(at_f) AS max_at
 FROM (SELECT COUNT(found_by) AS at_f
       FROM hacker H, employee E, attack A
       WHERE E.alias=found_by AND H.contact=E.alias
       AND H.dni IS NULL
       GROUP BY E.alias) AF) MA 
WHERE E.alias=found_by AND H.contact=E.alias
AND H.dni IS NULL
GROUP BY E.alias, max_at
HAVING COUNT(found_by)=MA.max_at;
                              
-- Derived_tables/Inline views
-- It is the same solution as the one with VIEWS
SELECT AF.alias, AF.at_found
FROM (SELECT E.alias, COUNT(found_by) AS at_found
      FROM hacker H, employee E, attack A
      WHERE E.alias=found_by AND H.contact=E.alias
      AND H.dni IS NULL
      GROUP BY E.alias) AF,
     (SELECT MAX(AF2.at_found) AS max_at
      FROM (SELECT COUNT(found_by) AS at_found
            FROM hacker H, employee E, attack A
            WHERE E.alias=found_by AND H.contact=E.alias
            AND H.dni IS NULL
            GROUP BY E.alias) AF2) MA
WHERE AF.at_found=MA.max_at;
