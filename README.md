# Toyshop

A full-stack mobile marketplace for buying and selling toys. Built with Flutter on the frontend and Go (Gin) on the backend, backed by PostgreSQL.

## Features

- **Auth** — register, login, JWT-based session, auto-login via SharedPreferences
- **Product catalog** — browse active listings, filter by category, view details
- **Selling** — create, edit, and delete your own product listings
- **Orders** — place orders, pay via Stripe, cancel, track status
- **Delivery** — create Nova Poshta TTN, ship orders, track deliveries
- **Reviews** — leave reviews on products, view reviews by author
- **Messaging** — in-app chat between buyers and sellers
- **Balance** — top up account balance, pay for orders from balance
- **Admin panel** — moderate product listings (approve/reject)
- **Profile** — avatar, email, registration date

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter / Dart |
| Backend | Go + Gin |
| Database | PostgreSQL |
| Auth | JWT |
| Payments | Stripe |
| Storage | Firebase Storage |
| Maps | Google Maps Flutter |
| Delivery | Nova Poshta API |

## Project Structure

```
toyshop/
├── backend/
│   ├── controllers/        # route handlers (users, products, orders, reviews, messages, stripe, ttn)
│   ├── middleware/         # JWT auth, admin-only guard
│   ├── models/             # DB models (User, Product, Order, Review, Message, etc.)
│   ├── database/           # PostgreSQL connection
│   ├── utils/              # JWT helpers
│   └── main.go             # router setup, server entry point
├── frontend/
│   └── lib/
│       ├── screens/        # all app screens (home, products, orders, chat, profile, admin, etc.)
│       ├── services/       # API and Stripe service clients
│       ├── models/         # Dart data models
│       └── utils/          # constants, SharedPreferences helpers
├── init/
│   └── init.sql            # database schema and seed
└── docker-compose.yml      # PostgreSQL container
```

## Getting Started

### Prerequisites

- Go 1.21+
- Flutter SDK 3.7+
- Docker (for the database)
- A `.env` file in `backend/` and `frontend/`

### 1. Start the database

```bash
docker-compose up -d
```

### 2. Run the backend

```bash
cd backend
go run main.go
```

The API will be available at `http://localhost:8080`.

### 3. Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

> For Android emulator, the app connects to `http://10.0.2.2:8080`.

## Environment Variables

Create a `.env` file in the `backend/` directory:

```env
DB_HOST=localhost
DB_PORT=5433
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=toyshop_db
JWT_SECRET=your_jwt_secret
STRIPE_SECRET_KEY=your_stripe_secret
NOVA_POSHTA_API_KEY=your_nova_poshta_key
```

## API Overview

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/register` | — | Register a new user |
| POST | `/login` | — | Login and receive JWT |
| GET | `/products` | — | List all products |
| GET | `/products/active` | — | List active products |
| POST | `/products` | ✓ | Create a product |
| PUT | `/products/:id` | ✓ | Update a product |
| DELETE | `/products/:id` | ✓ | Delete a product |
| POST | `/orders` | ✓ | Place an order |
| PUT | `/orders/:id/pay` | ✓ | Pay for an order |
| POST | `/messages` | ✓ | Send a message |
| POST | `/create-ttn` | ✓ | Create a delivery TTN |
| PUT | `/admin/products/:id/status` | Admin | Approve or reject a product |
