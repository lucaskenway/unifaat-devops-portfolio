-- Schema base da TechNova (v0) — criado pelo Postgres na primeira subida do container.
-- As migrações em migrations/ evoluem este schema com o padrão expand-contract.
CREATE TABLE IF NOT EXISTS customers (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(120) NOT NULL,
  email       VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS orders (
  id            SERIAL PRIMARY KEY,
  customer_id   INTEGER REFERENCES customers(id),
  customer_name VARCHAR(120),
  product       VARCHAR(200) NOT NULL,
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  status        VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO customers (name, email) VALUES
  ('Ana Souza',    'ana@technova.com.br'),
  ('Bruno Lima',   'bruno@technova.com.br'),
  ('Carla Mendes', 'carla@technova.com.br');

INSERT INTO orders (customer_id, customer_name, product, quantity, status) VALUES
  (1, 'Ana Souza',    'Notebook TechNova Pro',  2, 'pending'),
  (2, 'Bruno Lima',   'Monitor UltraWide 34"',  1, 'shipped'),
  (3, 'Carla Mendes', 'Teclado Mecânico RGB',   5, 'delivered'),
  (1, 'Ana Souza',    'Mouse Gamer',            1, 'pending');
