CREATE DATABASE IF NOT EXISTS db_csd
CHARACTER SET utf8mb4 COLLATE utf8mb4_es_0900_as_cs;

use db_csd;

CREATE TABLE IF NOT EXISTS employee (
alias VARCHAR(20) PRIMARY KEY,
dni VARCHAR(10),
name_emp VARCHAR(40),
surname_emp VARCHAR(60),
CONSTRAINT empl_dni_uk UNIQUE(dni)
);

CREATE TABLE IF NOT EXISTS hacker (
alias VARCHAR(20) PRIMARY KEY,
dni VARCHAR(10),
name_hack VARCHAR(40),
surname_hack VARCHAR(60),
email VARCHAR(60),
phone VARCHAR(12),
contact VARCHAR(20) NOT NULL,
CONSTRAINT hkr_con_uk UNIQUE(contact),
CONSTRAINT hkr_emp_fk FOREIGN KEY(contact) REFERENCES employee (alias)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS collaborate (
emp1 VARCHAR(20),
emp2 VARCHAR(20),
day_col DATE,
PRIMARY KEY(emp1,emp2,day_col),
CONSTRAINT col_em1_fk FOREIGN KEY(emp1) REFERENCES employee (alias),
CONSTRAINT col_em2_fk FOREIGN KEY(emp2) REFERENCES employee (alias),
CONSTRAINT col_emp_ck CHECK(emp1<>emp2)
);

CREATE TABLE IF NOT EXISTS at_type (
code_type VARCHAR(5) PRIMARY KEY,
name_type VARCHAR(30) NOT NULL,
desc_type VARCHAR(256) NOT NULL,
risk DECIMAL(3,2),
CONSTRAINT aty_ris_ck CHECK(risk>=0.00 AND risk<=1.00)
);

CREATE TABLE IF NOT EXISTS attack (
type_code VARCHAR(5),
index_at SMALLINT,
found_by VARCHAR(20),
timestamp_at TIMESTAMP DEFAULT NOW(),
PRIMARY KEY(type_code, index_at),
CONSTRAINT att_typ_fk FOREIGN KEY(type_code) REFERENCES at_type (code_type)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT att_fnd_fk FOREIGN KEY(found_by) REFERENCES employee (alias)
);

CREATE TABLE IF NOT EXISTS target (
ip_target VARCHAR(15),
service VARCHAR(20),
name_ta VARCHAR(20),
cost DECIMAL(9,2),
CONSTRAINT tar_iptser_pk PRIMARY KEY(ip_target,service)
);

CREATE TABLE IF NOT EXISTS effect (
code_effect VARCHAR(6) PRIMARY KEY,
eff_description VARCHAR(256),
severity DECIMAL(3,2),
ip_target VARCHAR(15) NOT NULL,
service VARCHAR(20) NOT NULL,
type_at VARCHAR(5) NOT NULL,
index_at SMALLINT NOT NULL,
CONSTRAINT eff_att_fk FOREIGN KEY(type_at,index_at) REFERENCES attack (type_code,index_at),
CONSTRAINT eff_tar_fk FOREIGN KEY(ip_target,service) REFERENCES target (ip_target,service),
CONSTRAINT eff_sev_ck CHECK(severity>=0.00 AND severity<=1.00)
);

INSERT INTO employee VALUES
('HackerMan', '12345678A', 'Héctor', 'Rent'),
('CyberGata', '87654321B', 'Celia', 'Bergara'),
('FireWall', '23456789C', 'Fernando', 'Jones'),
('MrSmith', '98765432D', 'Marta', 'Smith'),
('SpyBot', '34567890E', 'Sergio', 'Botella'),
('AntiVirus', '09876543F', 'Ana', 'Vila'),
('Crypto', '45678901G', 'Cristina', 'Torres'),
('Switch', '10987654H', 'Felipe', 'Privada'),
('Dozer', '56789012I', 'Bruno', 'Secuele'),
('Patch', '21098765J', 'Patricia', 'Datta'),
('Root', '67890123K', 'Rosa', 'Otero'),
('Code', '32109876L', 'Carlos', 'Díaz'),
('Key', '78901234M', 'Kevin', 'Tage'),
('Lock', '43210987N', 'Laura', 'Somware'),
('Data', '89012345O', 'Daniel', 'Tato'),
('Cloud', '54321098P', 'Claudia', 'Udall'),
('Neo', '90123456Q', 'Thomas', 'Anderson'),
('Mouse', '65432109R', 'Wesley', 'Bennett'),
('BotNet', '01234567S', 'Beatriz', 'Iturralde'),
('Tank', '76543210T', 'Brian', 'Yates');

INSERT INTO hacker VALUES
('Worm', '12121212X', 'Walter', 'Ortega', 'worm@protonmail.com', NULL, 'BotNet'),
('DDoS3', '23232323Y', 'Diana', 'Domingo', 'domiana@mailfence.com', '232323232', 'AntiVirus'),
('Crack', NULL, NULL, 'Ramos', 'crack@protonmail.com', '343434343', 'Cloud'),
('Brute', NULL, NULL, NULL, NULL, NULL, 'Lock'),
('Morpheus', '33333333Z', 'Miguel', 'Orfeo', 'morpheus@matrix.com', '333333333', 'Neo'),
('Sniff', NULL, 'Sofía', NULL, NULL, '565656565', 'Patch'),
('Logic', '78787878T', 'Luis', 'Gómez', 'logic@hotmail.com', '787878787', 'Code'),
('Zombie', '89898989S', 'Zoe', 'Molina', NULL, '898989898', 'Key'),
('Cookie', NULL, 'Carlos', 'Otero', 'cookie@mailfence.com', '909090909', 'Tank'),
('Cypher', NULL, NULL, NULL, 'We5f4re3n@tempmail.com', NULL, 'MrSmith');

INSERT INTO collaborate VALUES
('HackerMan', 'CyberGata', '2021-01-01'),
('MrSmith', 'FireWall', '2017-04-02'),
('Neo', 'MrSmith', '2019-12-12'),
('Cloud', 'SpyBot', '2018-06-06'),
('HackerMan', 'AntiVirus', '2016-08-08'),
('HackerMan', 'CyberGata', '2024-02-19'),
('HackerMan', 'CyberGata','2024-01-15'),
('Cloud', 'SpyBot','2017-11-03'),
('MrSmith', 'FireWall','2017-11-03'),
('Lock', 'AntiVirus', '2018-10-12'),
('Patch', 'Switch', '2019-09-30'),
('Switch', 'Lock', '2020-12-07'),
('Root', 'Key', '2021-03-05'),
('Lock', 'Switch', '2022-03-08');

INSERT INTO at_type VALUES
('DoS', 'Denial of Service', 'Attack that makes a machine or network resource unavailable to its intended users', 0.5),
('DDoS', 'Distributed Denial of Service', 'Attack that makes a machine or network resource unavailable to its intended users', 0.65),
('SQLi', 'SQL Injection', 'Attack that exploits a vulnerability in a database-driven application by inserting malicious SQL statements', 0.75),
('Spam', 'Spamming', 'Attack that sends unsolicited or unwanted messages to a large number of recipients', 0.3),
('XSS', 'Cross-Site Scripting', 'Attack that injects malicious code into a web page that runs on the browser of a victim', 0.45),
('CSRF', 'Cross-Site Request Forgery', 'Attack that forces a user to perform an unwanted action on a web application where they are authenticated', 0.55),
('MITM', 'Man-In-The-Middle', 'Attack that intercepts and alters the communication between two parties', 0.75),
('RCE', 'Remote Code Execution', 'Attack that allows an attacker to execute arbitrary commands or code on a target machine', 0.65);

INSERT INTO attack VALUES 
('MITM',1,'SpyBot','2016-01-15 12:34:56'),
('DoS',1,'Lock','2016-02-29 23:45:01'),
('DDoS',1, NULL,'2016-03-31 10:11:12'),
('DoS',2,'FireWall','2016-04-30 18:19:20'),
('Spam',1,'Patch','2016-05-31 22:23:24'),
('DDoS',2,'Lock','2016-06-30 14:15:16'),
('MITM',2, NULL,'2016-07-31 19:20:21'),
('DoS',3,'HackerMan','2016-08-31 16:17:18'),
('Spam',2,'Crypto','2016-09-30 13:14:15'),
('DDoS',3,'Data','2016-10-31 20:21:22'),
('SQLi',1, NULL,'2016-11-30 11:12:13'),
('SQLi',2,'Neo','2016-12-31 17:18:19'),
('DoS',4,'MrSmith','2017-01-31 21:22:23'),
('DDoS',4,'MrSmith','2017-02-28 15:16:17'),
('DoS',5, NULL,'2017-03-31 12:13:14'),
('SQLi',3,'MrSmith','2017-04-30 18:19:20'),
('Spam',3,'AntiVirus','2017-05-31 23:24:25'),
('DoS',6,'MrSmith','2017-06-30 10:11:12'),
('XSS',1,'SpyBot','2017-07-31 19:20:21'),
('Spam',4, NULL,'2017-08-31 16:17:18'),
('MITM',3,'Cloud','2017-09-30 13:14:15'),
('DDoS',5, NULL,'2017-10-31 20:21:22'),
('SQLi',4,'Root','2017-11-30 11:12:13'),
('Spam',5, NULL,'2017-12-31 17:18:19'),
('SQLi',5, NULL,'2018-01-31 21:22:23'),
('DoS',7,'MrSmith','2018-02-28 15:16:17'),
('MITM',4, NULL,'2018-03-31 12:13:14'),
('MITM',5,'HackerMan','2018-04-30 18:19:20'),
('MITM',6,'Root','2018-05-31 23:24:25'),
('Spam',6,'AntiVirus','2018-06-30 10:11:12'),
('DDoS',6,'Lock','2018-07-31 19:20:21'),
('DoS',8, NULL,'2018-08-31 16:17:18'),
('DoS',9,'MrSmith','2018-09-30 13:14:15'),
('DoS',10,'Tank','2018-09-30 13:14:15'),
('MITM',7,'MrSmith','2018-10-31 20:21:22'),
('SQLi',6,'CyberGata','2018-11-30 11:12:13'),
('DDoS',7,'FireWall','2018-12-31 17:18:19'),
('DDoS',8,'SpyBot','2019-01-31 21:22:23'),
('Spam',7,'Crypto','2019-02-28 15:16:17'),
('Spam',8,'CyberGata','2019-03-31 12:13:14'),
('Spam',9,'Code','2019-04-30 18:19:20'),
('MITM',8,'Key','2019-06-30 10:11:12');

INSERT INTO target VALUES
('54.152.23.14', 'HTTPS', 'DuffDuffDoh.com', 1200.00),
('104.26.10.78', 'FTP', 'Azarnet', 15000.00),
('172.67.72.145', 'ERP', 'Emee', 10000.50),
('13.225.62.126', 'SMTP', 'Coldmail', 20000.00),
('52.58.78.16', 'DNS', 'MasterOfNaming', 8570.99),
('104.18.26.25', 'HTTPS', 'CEEDCV',0.01),
('104.21.18.239', 'POP3', 'Owluck.com', 261000.00),
('104.21.18.239', 'IMAP', 'Owluck.com', 2900.00),
('99.86.230.121', 'VPN', 'Soprano', 5000.00),
('13.249.134.92', 'IaaS', 'Azufre', 350000.00),
('13.107.213.69', 'VPN', 'Windlee', 42000.00),
('104.154.89.105', 'HTTP', 'Marcosoft.com', 1942500.00),
('104.26.1.128', 'PaaS', 'Hiroky Platform', NULL),
('151.101.2.133', 'HTTP', 'Googlix.fr', 2850700.50),
('151.101.2.133', 'HTTPS', 'Googlix.fr', 268000.00);

INSERT INTO effect VALUES
('ZQW123', 'El ataque DDoS provocó una interrupción del servicio FTP durante 15 minutos', 0.75, '104.26.10.78', 'FTP','DDoS',1),
('LKT456', 'El ataque DDoS causó una pérdida de datos en el servidor FTP', 0.85, '104.26.10.78', 'FTP','DDoS',1),
('RFD789', 'El ataque DDoS saturó el servicio SMTP y retrasó la entrega de los correos electrónicos', 0.65, '13.225.62.126', 'SMTP','DDoS',2),
('HGF321', 'El ataque DDoS afectó al servicio DNS y dificultó el acceso a los dominios web', 0.70, '52.58.78.16', 'DNS','DDoS',2),
('CVB654', 'El ataque DDoS comprometió la seguridad del sistema ERP y permitió el acceso no autorizado a la información confidencial', 0.95, '172.67.72.145', 'ERP','DDoS',3),
('NHY987', 'El ataque DDoS generó un alto consumo de recursos en el servicio SMTP y redujo el rendimiento del sistema', 0.60, '13.225.62.126', 'SMTP','DDoS',3),
('MNB741', 'El ataque DDoS interrumpió el servicio VPN y dejó a los usuarios sin conexión a la red privada', 0.80, '99.86.230.121', 'VPN','DDoS',4),
('POI852', 'El ataque DDoS provocó una sobrecarga en el servicio SMTP y causó errores en el envío y recepción de los correos electrónicos', 0.67, '13.225.62.126', 'SMTP','DDoS',4),
('LKJ963', 'El ataque DDoS dañó el servicio SMTP y borró algunos correos electrónicos importantes', 0.83, '13.225.62.126', 'SMTP','DDoS',4),
('QAZ147', 'El ataque DDoS impidió el acceso al servicio POP3 y bloqueó la consulta de los correos electrónicos', 0.76, '104.21.18.239', 'POP3','DDoS',5),
('WSX258', 'El ataque DDoS inhabilitó el servicio IMAP y afectó a la sincronización de los correos electrónicos', 0.72, '104.21.18.239', 'IMAP','DDoS',5),
('EDC369', 'El ataque DDoS causó una caída del servicio IaaS y perjudicó a la infraestructura en la nube', 0.90, '13.249.134.92', 'IaaS','DDoS',6),
('RFV135', 'El ataque DDoS ralentizó el servicio HTTP y disminuyó la velocidad de carga de las páginas web', 0.55, '151.101.2.133', 'HTTP','DDoS',6),
('TGB246', 'El ataque DDoS desestabilizó el servicio DNS y provocó fallos en la resolución de nombres', 0.68, '52.58.78.16', 'DNS','DDoS',7),
('YHN357', 'El ataque DDoS deterioró el servicio DNS y generó problemas de seguridad en la navegación web', 0.73, '52.58.78.16', 'DNS','DDoS',7),
('UJM468', 'El ataque DDoS interrumpió el servicio HTTP y dejó inaccesibles algunos sitios web', 0.77, '151.101.2.133', 'HTTP','DDoS',8),
('IKO579', 'El ataque DDoS afectó al servicio HTTPS y comprometió la privacidad de los usuarios', 0.82, '54.152.23.14', 'HTTPS','DDoS',8),
('OLP690', 'El ataque DoS detuvo el servicio HTTP durante 10 minutos y afectó al tráfico web', 0.50, '151.101.2.133', 'HTTP','DoS',1),
('PLO123', 'El ataque DoS causó una pérdida de conexión en el servicio FTP y afectó a la transferencia de archivos', 0.45, '104.26.10.78', 'FTP','DoS',1),
('OKM456', 'El ataque DoS consumió los recursos del servicio IaaS y afectó al rendimiento de la nube', 0.40, '13.249.134.92', 'IaaS','DoS',2),
('EXZ397', 'El ataque DoS ha afectado a bloqueado el servicio por 3 horas', 0.80, '13.249.134.92', 'IaaS','DoS',2),
('QWE789', 'El ataque DoS saturó el servicio SMTP y retrasó la entrega de los correos electrónicos', 0.35, '13.225.62.126', 'SMTP','DoS',2),
('ASD321', 'El ataque DoS interrumpió el servicio FTP durante 5 minutos y afectó a la transferencia de archivos', 0.30, '104.26.10.78', 'FTP','DoS',3),
('ZXC654', 'El ataque DoS afectó al servicio DNS y dificultó el acceso a los dominios web', 0.25, '52.58.78.16', 'DNS','DoS',3),
('RTY987', 'El ataque DoS afectó al servicio DNS y generó problemas de seguridad en la navegación web', 0.28, '52.58.78.16', 'DNS','DoS',4),
('FGH456', 'El ataque DoS interrumpió el servicio VPN y dejó a los usuarios sin conexión a la red privada', 0.32, '99.86.230.121', 'VPN','DoS',4),
('VBN123', 'El ataque DoS comprometió la seguridad del servicio VPN y permitió el acceso no autorizado a la información confidencial', 0.38, '13.107.213.69', 'VPN','DoS',5),
('TYU741', 'El ataque DoS generó un alto consumo de recursos en el servicio SMTP y redujo el rendimiento del sistema', 0.36, '13.225.62.126', 'SMTP','DoS',5),
('IOP852', 'El ataque DoS provocó una sobrecarga en el servicio SMTP y causó errores en el envío y recepción de los correos electrónicos', 0.34, '13.225.62.126', 'SMTP','DoS',6),
('JHG963', 'El ataque DoS interrumpió el servicio VPN y afectó a la conexión de los usuarios', 0.33, '99.86.230.121', 'VPN','DoS',6),
('BNM147', 'El ataque DoS dañó el servicio VPN y borró algunos datos importantes', 0.37, '13.107.213.69', 'VPN','DoS',7),
('KLM258', 'El ataque DoS ralentizó el servicio HTTPS y disminuyó la velocidad de carga de las páginas web', 0.31, '54.152.23.14', 'HTTPS','DoS',7),
('POU369', 'El ataque DoS desestabilizó el servicio DNS y provocó fallos en la resolución de nombres', 0.27, '52.58.78.16', 'DNS','DoS',8),
('LKI135', 'El ataque DoS deterioró el servicio DNS y causó problemas de navegación web', 0.29, '52.58.78.16', 'DNS','DoS',8),
('UYT246', 'El ataque DoS impidió el acceso al servicio POP3 y bloqueó la consulta de los correos electrónicos', 0.26, '104.21.18.239', 'POP3','DoS',9),
('REW357', 'El ataque DoS inhabilitó el servicio IMAP y afectó a la sincronización de los correos electrónicos', 0.24, '104.21.18.239', 'IMAP','DoS',9),
('TRE468', 'El ataque DoS causó una caída del servicio HTTPS y perjudicó a la privacidad de los usuarios', 0.39, '151.101.2.133', 'HTTPS','DoS',10),
('YUI579', 'El ataque MITM interceptó el tráfico del servicio HTTP y robó información sensible de los usuarios', 0.85, '151.101.2.133', 'HTTP','MITM',1),
('GHJ690', 'El ataque MITM alteró el servicio DNS y redirigió a los usuarios a sitios web maliciosos', 0.80, '52.58.78.16', 'DNS','MITM',1),
('CVN123', 'El ataque MITM accedió al servicio FTP y modificó los archivos almacenados', 0.75, '104.26.10.78', 'FTP','MITM',2),
('NHY456', 'El ataque MITM comprometió el servicio IaaS y afectó a la infraestructura en la nube', 0.90, '13.249.134.92', 'IaaS','MITM',2),
('MJK789', 'El ataque MITM vulneró el servicio VPN y obtuvo información confidencial de los usuarios', 0.88, '13.107.213.69', 'VPN','MITM',3),
('NML321', 'El ataque MITM interceptó el tráfico del servicio VPN y modificó los datos transmitidos', 0.83, '99.86.230.121', 'VPN','MITM',3),
('BVC654', 'El ataque MITM alteró el servicio HTTP y mostró contenido falso a los usuarios', 0.78, '151.101.2.133', 'HTTP','MITM',4),
('XSW987', 'El ataque MITM vulneró el servicio HTTPS y robó información sensible de los usuarios', 0.82, '151.101.2.133', 'HTTPS','MITM',5),
('ZAS456', 'El ataque MITM accedió al servicio SMTP y leyó los correos electrónicos de los usuarios', 0.80, '13.225.62.126', 'SMTP','MITM',6),
('EDF123', 'El ataque MITM alteró el servicio SMTP y envió correos electrónicos falsos a los usuarios', 0.85, '13.225.62.126', 'SMTP','MITM',6),
('CDE741', 'El ataque MITM comprometió el servicio ERP y afectó a la gestión de los recursos empresariales', 0.95, '172.67.72.145', 'ERP','MITM',7),
('VFR852', 'El ataque MITM accedió al servicio ERP y modificó los datos almacenados', 0.90, '172.67.72.145', 'ERP','MITM',8),
('BGT963', 'El ataque MITM alteró el servicio DNS y redirigió a los usuarios a sitios web maliciosos', 0.79, '52.58.78.16', 'DNS','MITM',8),
('NHY147', 'El ataque MITM afectó al servicio DNS y generó problemas de seguridad en la navegación web', 0.77, '52.58.78.16', 'DNS','MITM',8),
('MJU258', 'El ataque Spam inundó el servicio POP3 con correos electrónicos no deseados', 0.15, '104.21.18.239', 'POP3','Spam',1),
('KIU369', 'El ataque Spam inundó el servicio POP3 con correos electrónicos no deseados', 0.16, '104.21.18.239', 'POP3','Spam',2),
('LOP135', 'El ataque Spam inundó el servicio HTTPS con solicitudes falsas', 0.18, '54.152.23.14', 'HTTPS','Spam',2),
('QAZ246', 'El ataque Spam inundó el servicio POP3 con correos electrónicos no deseados', 0.17, '104.21.18.239', 'POP3','Spam',3),
('WSX357', 'El ataque Spam inundó el servicio IMAP con correos electrónicos no deseados', 0.19, '104.21.18.239', 'IMAP','Spam',4),
('EDC468', 'El ataque Spam afectó al 20% de los usuarios', 0.20, '104.21.18.239', 'POP3','Spam',5),
('RFV579', 'El ataque Spam afectó al 21% de los usuarios', 0.21, '104.21.18.239', 'IMAP','Spam',6),
('TGB690', 'El ataque Spam inundó el servicio HTTPS con solicitudes falsas', 0.22, '54.152.23.14', 'HTTPS','Spam',7),
('YHN123', 'El ataque Spam inundó el servicio HTTPS con solicitudes falsas', 0.23, '104.18.26.25', 'HTTPS','Spam',8),
('UJM456', 'El ataque Spam inundó el servicio IMAP con correos electrónicos no deseados', 0.24, '104.21.18.239', 'IMAP','Spam',9),
('PLM789', 'El ataque SQLi inyectó código malicioso en el servicio ERP y borró algunos registros de la base de datos', 0.95, '172.67.72.145', 'ERP','SQLi',1),
('OKN321', 'El ataque SQLi inyectó código malicioso en el servicio HTTP y obtuvo información sensible de los usuarios', 0.90, '104.154.89.105', 'HTTP','SQLi',1),
('IUY654', 'El ataque SQLi inyectó código malicioso en el servicio ERP y modificó algunos datos almacenados', 0.92, '172.67.72.145', 'ERP','SQLi',2),
('OPL987', 'El ataque SQLi inyectó código malicioso en el servicio ERP y afectó al funcionamiento del sistema', 0.93, '172.67.72.145', 'ERP','SQLi',2),
('ALO321', 'El ataque SQLi inyectó código malicioso en el servicio HTTP y alteró el contenido de las páginas web', 0.88, '151.101.2.133', 'HTTP','SQLi',3),
('ZSE456', 'El ataque SQLi inyectó código malicioso en el servicio SMTP y accedió a los correos electrónicos de los usuarios', 0.85, '13.225.62.126', 'SMTP','SQLi',3),
('XDR741', 'El ataque SQLi inyectó código malicioso en el servicio ERP y comprometió la seguridad de los datos', 0.94, '172.67.72.145', 'ERP','SQLi',4),
('CFT852', 'El ataque SQLi inyectó código malicioso en el servicio ERP y causó errores en el sistema', 0.91, '172.67.72.145', 'ERP','SQLi',4),
('VGY963', 'El ataque SQLi inyectó código malicioso en el servicio ERP y afectó al rendimiento del sistema', 0.89, '172.67.72.145', 'ERP','SQLi',4),
('BHU147', 'El ataque SQLi inyectó código malicioso en el servicio ERP y perjudicó a la gestión de los recursos empresariales', 0.96, '172.67.72.145', 'ERP','SQLi',4),
('NJK258', 'El ataque SQLi inyectó código malicioso en el servicio HTTP y robó información sensible de los usuarios', 0.87, '104.154.89.105', 'HTTP','SQLi',5),
('MLP369', 'El ataque SQLi inyectó código malicioso en el servicio ERP y borró algunos registros de la base de datos', 0.95, '172.67.72.145', 'ERP','SQLi',5),
('QWE135', 'El ataque SQLi inyectó código malicioso en el servicio HTTP y obtuvo información sensible de los usuarios', 0.90, '104.154.89.105', 'HTTP','SQLi',6),
('ASD246', 'El ataque XSS inyectó código malicioso en el servicio HTTPS y mostró contenido falso a los usuarios', 0.80, '104.18.26.25', 'HTTPS','XSS',1),
('ZXC357', 'El ataque XSS inyectó código malicioso en el servicio IaaS y afectó a la infraestructura en la nube', 0.85, '13.249.134.92', 'IaaS','XSS',1),
('RTY468', 'El ataque XSS inyectó código malicioso en el servicio ERP y comprometió la seguridad de los datos', 0.90, '172.67.72.145', 'ERP','XSS',1);
