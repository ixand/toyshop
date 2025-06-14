
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- Таблиця користувачів
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    _name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
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
('Спортивні товари для дітей'),
('Розвиваючі іграшки'),
('Інтерактивні іграшки'),
('Дитячі музичні інструменти'),
('Іграшки для ванної'),
('Іграшки для вулиці'),
('Пісочниці та аксесуари'),
('Іграшкова зброя та арбалети'),
('Дитячі транспортні засоби'),
('Дитячі велосипеди'),
('Скейтборди та самокати'),
('Гіроборди та електротранспорт'),
('Розвиваючі книги та плакати'),
('Пазли та головоломки'),
('Кубики та сортери'),
('Моделі та збірні набори'),
('Фігурки героїв і тварин'),
('Машинки та техніка'),
('Іграшки з улюбленими персонажами'),
('Ігрові набори та сценки'),
('Намистини, бісер та браслети'),
('Набори для малювання'),
('3D ручки та пластик'),
('Ліплення: пластилін, глина, тісто'),
('Набори для наукових експериментів'),
('Дитячі телескопи та мікроскопи'),
('Дитячі намети, будиночки та тунелі'),
('Ігрові килимки та підлоги'),
('Дитячі кухні та побутова техніка'),
('Касові апарати та магазини'),
('Меблі для ляльок'),
('Набори для лікаря / перукаря'),
('Іграшки-антистреси (pop-it, squishy)'),
('STEM-набори'),
('Магнітні ігри та дошки');

-- Таблиця товарів
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    _name TEXT NOT NULL,
    _description TEXT,
    _status TEXT,
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT,
    _location TEXT,
    stock_quantity INT DEFAULT 0,
    category_id INT REFERENCES categories(id),
    owner_id INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    previous_data JSONB
);

-- Таблиця замовлень
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    _status TEXT DEFAULT 'очікується',
    shipping_address TEXT,
    payment_status TEXT DEFAULT 'неоплачений',
    payment_type TEXT,
    total_price NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    recipient_first_name TEXT,
    recipient_last_name TEXT,
    recipient_middle_name TEXT,
    ttn TEXT
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