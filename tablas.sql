-- =====================================================
-- Esquema PostgreSQL - Sistema académico
-- Generado a partir del diagrama entidad-relación
-- =====================================================

-- -----------------------------------------------------
-- USUARIOS Y ROLES
-- -----------------------------------------------------
CREATE TABLE usuario (
    id_usuario  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    contrasena  VARCHAR(255) NOT NULL,   -- guardar hash, nunca texto plano
    rol         VARCHAR(30)  NOT NULL
                CHECK (rol IN ('estudiante', 'acudiente', 'docente', 'coordinador')),
    activo      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE acudiente (
    id_acudiente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario   INTEGER NOT NULL UNIQUE
                 REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    telefono     VARCHAR(30)
);

CREATE TABLE docente (
    id_docente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario INTEGER NOT NULL UNIQUE
               REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE coordinador (
    id_coordinador INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario     INTEGER NOT NULL UNIQUE
                   REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- ESTRUCTURA ACADÉMICA
-- -----------------------------------------------------
CREATE TABLE periodo_academico (
    id_periodo   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin    DATE NOT NULL,
    activo       BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE curso (
    id_curso           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_docente_titular INTEGER NOT NULL
                       REFERENCES docente(id_docente),
    nombre             VARCHAR(100) NOT NULL
);

CREATE TABLE estudiante (
    id_estudiante             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario                INTEGER NOT NULL UNIQUE
                              REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_curso                  INTEGER NOT NULL
                              REFERENCES curso(id_curso),
    id_acudiente              INTEGER NOT NULL
                              REFERENCES acudiente(id_acudiente),
    es_repitente              BOOLEAN NOT NULL DEFAULT FALSE,
    tiene_condicion_especial  BOOLEAN NOT NULL DEFAULT FALSE,
    descripcion_condicion     VARCHAR(500)
);

CREATE TABLE asignatura (
    id_asignatura INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_docente    INTEGER NOT NULL REFERENCES docente(id_docente),
    id_curso      INTEGER NOT NULL REFERENCES curso(id_curso),
    nombre        VARCHAR(100) NOT NULL
);

-- -----------------------------------------------------
-- ASISTENCIA
-- -----------------------------------------------------
CREATE TABLE registro_asistencia (
    id_registro_asistencia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_curso               INTEGER NOT NULL REFERENCES curso(id_curso),
    fecha                  DATE NOT NULL
);

CREATE TABLE detalle_asistencia (
    id_detalle_asistencia  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_registro_asistencia INTEGER NOT NULL
                           REFERENCES registro_asistencia(id_registro_asistencia)
                           ON DELETE CASCADE,
    id_estudiante          INTEGER NOT NULL REFERENCES estudiante(id_estudiante),
    estado                 VARCHAR(30) NOT NULL
                           CHECK (estado IN ('presente', 'ausente', 'tardanza', 'justificado')),
    motivo_justificacion   VARCHAR(500),
    UNIQUE (id_registro_asistencia, id_estudiante)
);

-- -----------------------------------------------------
-- EVALUACIÓN
-- -----------------------------------------------------
CREATE TABLE actividad_evaluativa (
    id_actividad_evaluativa INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_asignatura           INTEGER NOT NULL REFERENCES asignatura(id_asignatura),
    id_periodo              INTEGER NOT NULL REFERENCES periodo_academico(id_periodo),
    nombre                  VARCHAR(150) NOT NULL,
    porcentaje              NUMERIC(5,2) NOT NULL
                            CHECK (porcentaje >= 0 AND porcentaje <= 100)
);

CREATE TABLE calificacion (
    id_calificacion         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_actividad_evaluativa INTEGER NOT NULL
                            REFERENCES actividad_evaluativa(id_actividad_evaluativa),
    id_estudiante           INTEGER NOT NULL REFERENCES estudiante(id_estudiante),
    valor                   NUMERIC(5,2),
    estado                  VARCHAR(30),
    UNIQUE (id_actividad_evaluativa, id_estudiante)
);

-- -----------------------------------------------------
-- SEGUIMIENTO
-- -----------------------------------------------------
CREATE TABLE observacion (
    id_observacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_estudiante  INTEGER NOT NULL REFERENCES estudiante(id_estudiante),
    id_autor       INTEGER NOT NULL REFERENCES usuario(id_usuario), -- docente o coordinador
    tipo           VARCHAR(50),
    descripcion    TEXT NOT NULL,
    es_positiva    BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alerta_academica (
    id_alerta        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_estudiante    INTEGER NOT NULL REFERENCES estudiante(id_estudiante),
    id_generada_por  INTEGER NOT NULL REFERENCES coordinador(id_coordinador),
    motivo           VARCHAR(500) NOT NULL,
    activa           BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_generacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- COMUNICACIÓN
-- -----------------------------------------------------
CREATE TABLE mensaje (
    id_mensaje   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_remitente INTEGER NOT NULL REFERENCES usuario(id_usuario),
    asunto       VARCHAR(200) NOT NULL,
    contenido    TEXT NOT NULL,
    fecha_envio  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE destinatario_mensaje (
    id_destinatario_mensaje INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mensaje              INTEGER NOT NULL
                            REFERENCES mensaje(id_mensaje) ON DELETE CASCADE,
    id_destinatario         INTEGER NOT NULL REFERENCES usuario(id_usuario),
    leido                   BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_leido             TIMESTAMP,
    confirmado              BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (id_mensaje, id_destinatario)
);

CREATE TABLE notificacion (
    id_notificacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_autor        INTEGER NOT NULL REFERENCES usuario(id_usuario),
    asunto          VARCHAR(200) NOT NULL,
    contenido       TEXT NOT NULL,
    fecha_leido     TIMESTAMP,
    leido           BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_envio     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- ÍNDICES SOBRE LLAVES FORÁNEAS (mejoran los JOIN)
-- -----------------------------------------------------
CREATE INDEX idx_estudiante_curso       ON estudiante(id_curso);
CREATE INDEX idx_estudiante_acudiente   ON estudiante(id_acudiente);
CREATE INDEX idx_curso_docente          ON curso(id_docente_titular);
CREATE INDEX idx_asignatura_docente     ON asignatura(id_docente);
CREATE INDEX idx_asignatura_curso       ON asignatura(id_curso);
CREATE INDEX idx_registro_curso         ON registro_asistencia(id_curso);
CREATE INDEX idx_detalle_estudiante     ON detalle_asistencia(id_estudiante);
CREATE INDEX idx_actividad_asignatura   ON actividad_evaluativa(id_asignatura);
CREATE INDEX idx_actividad_periodo      ON actividad_evaluativa(id_periodo);
CREATE INDEX idx_calificacion_estudiante ON calificacion(id_estudiante);
CREATE INDEX idx_observacion_estudiante ON observacion(id_estudiante);
CREATE INDEX idx_observacion_autor      ON observacion(id_autor);
CREATE INDEX idx_alerta_estudiante      ON alerta_academica(id_estudiante);
CREATE INDEX idx_alerta_generada_por    ON alerta_academica(id_generada_por);
CREATE INDEX idx_mensaje_remitente      ON mensaje(id_remitente);
CREATE INDEX idx_destmensaje_dest       ON destinatario_mensaje(id_destinatario);
CREATE INDEX idx_notificacion_autor     ON notificacion(id_autor);