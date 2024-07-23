DROP DATABASE IF EXISTS PeliculasDB;
CREATE DATABASE PeliculasDB;
USE PeliculasDB;

CREATE TABLE usuarios (
    id INT PRIMARY key auto_increment,
    nombre NVARCHAR(150) NOT NULL,
    correo_electronico NVARCHAR(100) NOT NULL,
    direccion NVARCHAR(255) NOT NULL,
    telefono NVARCHAR(15) NOT NULL
);

CREATE TABLE peliculas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(200) NOT NULL,
    genero VARCHAR(50),
    director VARCHAR(100),
    fecha_estreno DATE
);

CREATE TABLE visualizaciones (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT,
    id_pelicula INT,
    fecha_visualizacion DATE NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    FOREIGN KEY (id_pelicula) REFERENCES peliculas(id)
);

INSERT INTO usuarios (nombre, correo_electronico, direccion, telefono) VALUES
('Juan Perez', 'juan.perez@example.com', 'Calle Falsa 123, Ciudad', '555-1234'),
('Maria Lopez', 'maria.lopez@example.com', 'Avenida Siempre Viva 742, Ciudad', '555-5678'),
('Carlos Sanchez', 'carlos.sanchez@example.com', 'Calle Principal 456, Ciudad', '555-8765'),
('Ana Torres', 'ana.torres@example.com', 'Boulevard de los Sueños 789, Ciudad', '555-4321'),
('Luis Gomez', 'luis.gomez@example.com', 'Plaza de la Libertad 101, Ciudad', '555-0000');

INSERT INTO peliculas (titulo, genero, director, fecha_estreno) VALUES
('El Gran Escape', 'Acción', 'John Sturges', '1963-07-04'),
('La Vida es Bella', 'Drama', 'Roberto Benigni', '1997-12-20'),
('Matrix', 'Ciencia Ficción', 'Lana Wachowski, Lilly Wachowski', '1999-03-31'),
('El Padrino', 'Crimen', 'Francis Ford Coppola', '1972-03-24'),
('Titanic', 'Romance', 'James Cameron', '1997-12-19');

INSERT INTO visualizaciones (id_usuario, id_pelicula, fecha_visualizacion) VALUES
(1, 3, '2023-06-10'),
(2, 1, '2023-06-11'),
(3, 4, '2023-06-12'),
(4, 2, '2023-06-13'),
(5, 5, '2023-06-14'),
(1, 2, '2023-06-15'),
(2, 3, '2023-06-16'),
(3, 1, '2023-06-17'),
(4, 5, '2023-06-18'),
(5, 5, '2023-09-25'),
(5, 3, '2023-06-19');

-- consultas
-- ¿Que peliculas ha visto juan perez?

select p.titulo as pelicula, 
	   u.nombre as usuario, 
	   v.fecha_visualizacion as fecha_visualizacion
from peliculas p 
join visualizaciones v on v.id_pelicula = p.id 
join usuarios u on v.id_usuario = u.id 
where u.id  = 1;

-- Cuantas veces se ha visto la pelicula Titanic
select p.titulo as pelicula, 
	   count(*) as num_visualizaciones 
from peliculas p 
join visualizaciones v on v.id_pelicula = p.id 
join usuarios u on v.id_usuario = u.id 
where p.titulo = "Titanic"; 

-- Ordename las peliculas vistas por numero de visualizaciones
SELECT p.titulo AS pelicula, 
       COUNT(*) AS num_visualizaciones 
FROM peliculas p 
JOIN visualizaciones v ON v.id_pelicula = p.id 
JOIN usuarios u ON v.id_usuario = u.id
GROUP BY p.titulo
ORDER BY num_visualizaciones DESC;

-- Identificame si tengo una pelicula dentro de la base de datos
select titulo 
from peliculas p 
where exists (
	select 1
	where p.titulo = 'El Padrino'
);

-- Seleccioname los usuarios que no han visto Titanic

select u.nombre as usuario
from usuarios u 
-- el not exist se usa para excluir los usuarios en este caso que han visto titanic
-- en este caso es sacame todos los usuarios excepto aquellos que han visto titanic
where not exists (
	select 1
	from visualizaciones v 
	join peliculas p on v.id_pelicula = p.id
	-- a continuacion filtro las visualizaciones donde el titulo de la pelicula es titanic y el usuario coincide con el de la tabla de usuarios
	where p.titulo = 'Titanic' and v.id_usuario = u.id
); 

 -- Seleccioname unicamente los usuarios que han visto titanic

select u.nombre as usuario
from usuarios u 
where exists (
	select 1
	from visualizaciones v 
	join peliculas p on v.id_pelicula = p.id
	-- a continuacion filtro las visualizaciones donde el titulo de la pelicula es titanic y el usuario coincide con el de la tabla de usuarios
	where p.titulo = 'Titanic' and v.id_usuario = u.id
); 

create table titanic_visto (
	id INT primary key auto_increment,
	id_usuario INT,
	veces_vista INT,
	FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
);

-- cuando un usuario ha visto la pelicula titanic se añade su id en la tabla y se suma 1 al veces_vista

DELIMITER //

CREATE PROCEDURE ActualizarNombresTitanic()
begin
	
    DECLARE done INT DEFAULT 0;
    DECLARE v_id_usuario INT;
    DECLARE v_veces_vista INT;

 -- pasa el cursor por la tabla visulaizaciones y recoge todos aquellos
 -- usuarios que tengan id_pelicula igual que @pelicula
	
    DECLARE cursor_pelicula_titanic CURSOR FOR 
    SELECT v.id_usuario
    FROM visualizaciones v
    WHERE v.id_pelicula = @pelicula;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
   
   -- Declaro aqui la variable set @ porque antes de declarar el cursor da error
   SET @pelicula = (SELECT id FROM peliculas WHERE titulo = 'Titanic');
   
    open cursor_pelicula_titanic;
    
    read_loop: loop
	    fetch cursor_pelicula_titanic into v_id_usuario;
	    IF done THEN
            LEAVE read_loop;
        END IF;
       
       -- Verificar si el usuario ya tiene un registro en la tabla titanic_visto
        SET v_veces_vista = (SELECT veces_vista FROM titanic_visto WHERE id_usuario = v_id_usuario);
        
       -- Si no existe, insertar un nuevo registro con veces_vista = 1
        IF v_veces_vista IS NULL THEN
            -- Si no existe, insertar un nuevo registro con veces_vista = 1
            INSERT INTO titanic_visto (id_usuario, veces_vista)
            VALUES (v_id_usuario, 1);
        ELSE
            -- Si existe, actualizar el registro incrementando veces_vista
            UPDATE titanic_visto
            SET veces_vista = veces_vista + 1
            WHERE id_usuario = v_id_usuario;
        END IF;
    END LOOP;
    	
    
   CLOSE cursor_pelicula_titanic;
END //

DELIMITER ;

-- llamo al procedure
CALL ActualizarNombresTitanic(); 


-- Crea una función que recorra todos los usuarios y les añada "_checked" al final de su nombre.

DELIMITER //

CREATE PROCEDURE anyadir_check()
begin
	
    DECLARE done INT DEFAULT 0;
    declare cursor_id INT;
    DECLARE cursor_nombre VARCHAR(100);

 -- pasa el cursor por la tabla visulaizaciones y recoge todos aquellos
 -- usuarios que tengan id_pelicula igual que @pelicula
	
    DECLARE cursor_anyadir_check CURSOR FOR 
    SELECT u.id, u.nombre
    FROM usuarios u;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
   
    open cursor_anyadir_check;
    
    read_loop: loop
	    fetch cursor_anyadir_check into cursor_id, cursor_nombre;
	    IF done THEN
            LEAVE read_loop;
        END IF;
       
        UPDATE usuarios u set u.nombre = CONCAT (cursor_nombre, '_checked') where cursor_id = u.id;

    END LOOP;
    	
    
   close cursor_anyadir_check;
END //

DELIMITER ;

CALL anyadir_check();