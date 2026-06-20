-- Script de creación de la base de datos Loginova para PostgreSQL
-- Ejecutar con: psql -U postgres -f loginova_bd.sql

DROP TABLE IF EXISTS historial_estados;
DROP TABLE IF EXISTS ubicaciones;
DROP TABLE IF EXISTS evidencias;
DROP TABLE IF EXISTS recogidas;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS roles;

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);

INSERT INTO roles(nombre, descripcion)
VALUES
('Administrador', 'Control total del sistema'),
('Operador', 'Realiza recogidas'),
('Cliente', 'Consulta servicios');

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    telefono VARCHAR(20),
    rol_id INTEGER NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES roles(id)
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    nit VARCHAR(50),
    telefono VARCHAR(20),
    correo VARCHAR(150),
    direccion TEXT,
    ciudad VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recogidas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    usuario_id INTEGER,
    direccion_recogida TEXT NOT NULL,
    cantidad_paquetes INTEGER NOT NULL DEFAULT 0,
    observaciones TEXT,
    estado VARCHAR(50) NOT NULL DEFAULT 'Pendiente',
    fecha_programada TIMESTAMP,
    fecha_recogida TIMESTAMP,
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recogida_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_recogida_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE evidencias (
    id SERIAL PRIMARY KEY,
    recogida_id INTEGER NOT NULL,
    url_foto TEXT NOT NULL,
    comentario TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evidencia_recogida FOREIGN KEY (recogida_id) REFERENCES recogidas(id) ON DELETE CASCADE
);

CREATE TABLE ubicaciones (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL,
    latitud NUMERIC(10,7) NOT NULL,
    longitud NUMERIC(10,7) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ubicacion_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE TABLE historial_estados (
    id SERIAL PRIMARY KEY,
    recogida_id INTEGER NOT NULL,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50),
    usuario_id INTEGER,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_recogida FOREIGN KEY (recogida_id) REFERENCES recogidas(id),
    CONSTRAINT fk_historial_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE INDEX idx_recogidas_estado ON recogidas(estado);
CREATE INDEX idx_recogidas_cliente ON recogidas(cliente_id);
CREATE INDEX idx_recogidas_fecha ON recogidas(fecha_programada);
CREATE INDEX idx_evidencias_recogida ON evidencias(recogida_id);

INSERT INTO usuarios (nombre, correo, password_hash, telefono, rol_id)
VALUES ('Administrador', 'admin@loginova.com', 'pbkdf2$100000$z9+9fuixQ0Fc3fkcPFLQxA==$6z7CsyhGSHYJXoodgT3qjHXFhiW7sOGoTZwWIGfEj/w=', '3000000000', 1);

