package database

import (
	"fmt"
	"log"
	"os"
	"toyshop/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	host := os.Getenv("PGHOST")
	port := os.Getenv("PGPORT")
	user := os.Getenv("POSTGRES_USER")
	password := os.Getenv("PGPASSWORD")
	dbname := os.Getenv("PGDATABASE")

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("❌ Не вдалося підключитись до бази даних:", err)
	}

	fmt.Println("✅ Підключення до бази даних успішне!")
	DB = db

	err = db.AutoMigrate(
		&models.User{},
		&models.Product{},
		&models.Category{},
		&models.Order{},
		&models.OrderItem{},
		&models.Review{},
		&models.Message{},
	)
	if err != nil {
		log.Fatal("❌ Помилка при міграції:", err)
	}
}
