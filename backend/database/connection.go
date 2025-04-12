package database

import (
	"fmt"
	"log"
	"toyshop/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	dsn := "host=localhost user=postgres password=postgres dbname=toyshop_db port=5433 sslmode=disable"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Не вдалося підключитись до бази даних:", err)
	}

	fmt.Println("✅ Підключення до бази даних успішне!")
	DB = db

	DB.AutoMigrate(
		&models.User{},
		&models.Product{},
		&models.Category{},
		&models.Order{},
		&models.OrderItem{},
	)

}
