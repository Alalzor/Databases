SET NAMES 'utf8mb4';
DROP DATABASE IF EXISTS estrella_muerte;
CREATE DATABASE estrella_muerte CHARACTER SET utf8mb4 COLLATE utf8mb4_es_0900_as_cs;
USE estrella_muerte;

CREATE TABLE oficiales (
    id_oficial INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    rango VARCHAR(50),
    cargo VARCHAR(100)
);

CREATE TABLE celdas (
    id_celda INT PRIMARY KEY,
    sector INT,
    nivel INT,
    capacidad INT
);

CREATE TABLE prisioneros (
    id_prisionero INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    especie VARCHAR(50),
    causa_detencion TEXT
);

CREATE TABLE alojados (
    id_prisionero INT,
    id_celda INT,
    PRIMARY KEY (id_prisionero, id_celda),
    FOREIGN KEY (id_prisionero) REFERENCES prisioneros(id_prisionero),
    FOREIGN KEY (id_celda) REFERENCES celdas(id_celda)
);

CREATE TABLE misiones (
    id_mision INT PRIMARY KEY AUTO_INCREMENT,
    nombre_mision VARCHAR(100),
    descripcion TEXT,
    objetivo VARCHAR(500),
    id_oficial INT,
    FOREIGN KEY (id_oficial) REFERENCES oficiales(id_oficial)
);

CREATE TABLE troopers (
    id_trooper CHAR(6) PRIMARY KEY,
    serie INT,
    rango VARCHAR(20)
);

CREATE TABLE asignacion (
    id_mision INT,
    id_trooper CHAR(6),
    PRIMARY KEY (id_mision, id_trooper),
    FOREIGN KEY (id_mision) REFERENCES misiones(id_mision),
    FOREIGN KEY (id_trooper) REFERENCES troopers(id_trooper)
);

INSERT INTO oficiales (nombre, rango, cargo) VALUES
('Darth Vader', 'Sith Lord', 'Comandante de la Estrella de la Muerte'),
('Wilhuff Tarkin', 'Gran Moff', 'Comandante Supremo'),
('Conan Antonio Motti', 'Almirante', 'Oficial superior'),
('Cassio Tagge', 'General', 'Comandante militar'),
('Orson Krennic', 'Director', 'Director de Proyecto');

INSERT INTO celdas (id_celda, sector, nivel, capacidad) VALUES
(1138, 4, 2, 1),
(2175, 9, 4, 5),
(3017, 2, 5, 10);

INSERT INTO prisioneros (nombre, especie, causa_detencion) VALUES
('Leia Organa', 'Humana', 'Actividades rebeldes, posesión de información clasificada'),
('Chewbacca', 'Wookiee', 'Aliado rebelde, resistencia imperial'),
('Saw Gerrera', 'Humano', 'Actividades extremistas, resistencia al Imperio'),
('Riyo Chuchi', 'Pantoran', 'Desobediencia a la autoridad imperial');

INSERT INTO alojados (id_prisionero, id_celda) VALUES
(1, 1138),
(2, 2175),
(3, 3017),
(4, 3017);

INSERT INTO misiones (nombre_mision, descripcion, objetivo, id_oficial) VALUES
('Destrucción de Jedha', 'Destrucción del planeta Jedha para acabar con las fuerzas de la Rebelión', 'Eliminar a los partidarios de la Rebelión', 2),
('Captura de la Princesa Leia', 'Operación para capturar a la Princesa Leia y obtener información sobre la Rebelión', 'Captura de líder rebelde', 1),
('Destrucción de Alderaan', 'Destrucción del planeta Alderaan para eliminar un refugio rebelde', 'Eliminar la base rebelde', 2),
('Captura de los miembros de la Alianza Rebelde', 'Misión para capturar y eliminar miembros de la Alianza Rebelde', 'Neutralizar líderes rebeldes', 3),
('Infiltración en Yavin 4', 'Misión para localizar y destruir la base rebelde en Yavin 4', 'Destrucción de base rebelde', 1);

INSERT INTO troopers (id_trooper, serie, rango) VALUES
('TRO111', 1, 'Capitán'),
('TRO112', 1, 'Soldado'),
('TRO113', 1, 'Soldado'),
('TRO114', 1, 'Soldado'),
('TRO115', 1, 'Soldado'),
('TRO116', 1, 'Soldado'),
('TRO117', 1, 'Soldado'),
('TRO118', 1, 'Comandante'),
('TRO119', 1, 'Soldado'),
('TRO120', 1, 'Soldado'),
('TRO121', 1, 'Soldado'),
('TRO122', 1, 'Soldado'),
('TRO123', 1, 'Soldado'),
('TRO124', 1, 'Capitán'),
('TRO125', 2, 'Capitán'),
('TRO126', 2, 'Soldado'),
('TRO127', 2, 'Soldado'),
('TRO128', 2, 'Soldado'),
('TRO129', 2, 'Soldado'),
('TRO130', 2, 'Soldado'),
('TRO131', 2, 'Soldado'),
('TRO132', 2, 'Soldado'),
('TRO133', 2, 'Capitán'),
('TRO134', 2, 'Soldado'),
('TRO135', 2, 'Soldado'),
('TRO136', 2, 'Soldado'),
('TRO137', 2, 'Soldado'),
('TRO138', 2, 'Soldado'),
('TRO139', 2, 'Soldado'),
('TRO140', 2, 'Soldado'),
('TRO141', 2, 'Soldado'),
('TRO142', 2, 'Comandante');

INSERT INTO asignacion (id_mision, id_trooper) VALUES
(1, 'TRO111'),
(1, 'TRO112'),
(1, 'TRO113'),
(1, 'TRO114'),
(1, 'TRO115'),
(1, 'TRO116'),
(1, 'TRO117'),
(1, 'TRO118'),
(1, 'TRO124'),
(1, 'TRO125'),
(1, 'TRO126'),
(1, 'TRO127'),
(1, 'TRO128'),
(1, 'TRO129'),
(1, 'TRO132'),
(1, 'TRO133'),
(1, 'TRO134'),
(1, 'TRO135'),
(1, 'TRO136'),
(1, 'TRO139'),
(1, 'TRO140'),
(1, 'TRO141'),
(1, 'TRO142'),
(2, 'TRO125'),
(2, 'TRO126'),
(2, 'TRO127'),
(2, 'TRO128'),
(2, 'TRO129'),
(2, 'TRO130'),
(2, 'TRO131'),
(2, 'TRO132'),
(4, 'TRO116'),
(4, 'TRO117'),
(4, 'TRO118'),
(4, 'TRO121'),
(4, 'TRO122'),
(4, 'TRO123'),
(4, 'TRO124'),
(4, 'TRO125'),
(4, 'TRO128'),
(4, 'TRO129'),
(4, 'TRO130'),
(4, 'TRO131'),
(4, 'TRO132'),
(4, 'TRO133'),
(4, 'TRO134'),
(4, 'TRO135'),
(4, 'TRO136'),
(4, 'TRO137'),
(4, 'TRO141'),
(4, 'TRO142'),
(5, 'TRO113'),
(5, 'TRO114'),
(5, 'TRO115'),
(5, 'TRO116'),
(5, 'TRO117'),
(5, 'TRO118'),
(5, 'TRO119'),
(5, 'TRO120'),
(5, 'TRO121'),
(5, 'TRO124'),
(5, 'TRO125'),
(5, 'TRO126'),
(5, 'TRO127'),
(5, 'TRO128'),
(5, 'TRO129'),
(5, 'TRO130'),
(5, 'TRO131'),
(5, 'TRO132'),
(5, 'TRO133'),
(5, 'TRO137'),
(5, 'TRO141'),
(5, 'TRO142');
