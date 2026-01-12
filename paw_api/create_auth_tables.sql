--tabla autenticación ya que usuario no tiene pasword 
DROP TABLE IF EXISTS paw.usuario_auth CASCADE;

CREATE TABLE paw.usuario_auth (
  id_usuario BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('adoptante', 'fundacion')),
  id_adoptante BIGINT NULL,
  id_fundacion BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);



-- Usamos ON CONFLICT para que si los emails ya existen, solo actualice el hash
INSERT INTO paw.usuario_auth (email, password_hash, rol, id_fundacion)
VALUES 
('fundacion1@pawrescue.com', '$2b$12$MNx8Ho2ok8/8hBL8..g04urclhX.UQ12caxjkII.pLq7m3APsXCGi', 'fundacion', 1),
('fundacion2@pawrescue.com', '$2b$12$MNx8Ho2ok8/8hBL8..g04urclhX.UQ12caxjkII.pLq7m3APsXCGi', 'fundacion', 2)
ON CONFLICT (email) 
DO UPDATE SET password_hash = EXCLUDED.password_hash;

SELECT email, password_hash, rol FROM paw.usuario_auth;