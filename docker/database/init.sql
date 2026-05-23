-- Base de datos CORPAMAG
-- Tabla de licencias ambientales

CREATE TABLE IF NOT EXISTS licencias_ambientales (
    id SERIAL PRIMARY KEY,
    numero_expediente VARCHAR(50) UNIQUE NOT NULL,
    titular VARCHAR(200) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    tipo_licencia VARCHAR(100) NOT NULL,
    fecha_solicitud DATE NOT NULL,
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha_creacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS funcionarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

-- Datos de prueba
INSERT INTO licencias_ambientales 
    (numero_expediente, titular, municipio, tipo_licencia, fecha_solicitud)
VALUES
    ('CORP-2024-001', 'Empresa Minera SA', 'Cienaga', 
     'Mineria', '2024-01-15'),
    ('CORP-2024-002', 'Agricola del Norte', 'Fundacion', 
     'Vertimientos', '2024-02-20'),
    ('CORP-2024-003', 'Constructora Magdalena', 'Santa Marta', 
     'Construccion', '2024-03-10');

INSERT INTO funcionarios (nombre, cargo, email)
VALUES
    ('Ana Garcia', 'Directora de Licencias', 'agarcia@corpamag.gov.co'),
    ('Carlos Perez', 'Ingeniero Ambiental', 'cperez@corpamag.gov.co');
