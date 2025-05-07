-- Таблиця користувачів
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    _name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    balance FLOAT,
    _role TEXT DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблиця категорій
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    _name TEXT NOT NULL
);

INSERT INTO categories (_name) VALUES
('Іграшки для дітей'),
('Настільні ігри'),
('Конструктори'),
('Ляльки та аксесуари'),
('М’які іграшки'),
('Творчість та хобі'),
('Радіокеровані моделі'),
('Спортивні товари для дітей');

-- Таблиця товарів
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    _name TEXT NOT NULL,
    _description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT,
    _location TEXT,
    stock_quantity INT DEFAULT 0,
    category_id INT REFERENCES categories(id),
    owner_id INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблиця замовлень
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    _status TEXT DEFAULT 'очікується',
    shipping_address TEXT,
    payment_status TEXT DEFAULT 'неоплачений',
    total_price NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблиця позицій у замовленні
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL
);

-- Таблиця відгуків з каскадним видаленням
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(id) ON DELETE CASCADE,
    user_id INT REFERENCES users(id),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(id),
    receiver_id INT REFERENCES users(id),
    content TEXT,
    product_id INT REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    thread_id TEXT  -- унікальний ідентифікатор пари (наприклад: "1_2" або UUID)
);

