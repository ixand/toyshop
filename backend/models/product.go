package models

import "time"

type Product struct {
	ID            uint      `json:"id" gorm:"primaryKey"`
	Name          string    `json:"name" gorm:"column:_name"`
	Description   string    `json:"description" gorm:"column:_description"`
	Price         float64   `json:"price"`
	ImageURL      string    `json:"image_url"`
	Location      string    `json:"location" gorm:"column:_location"`
	StockQuantity int       `json:"stock_quantity"`
	CategoryID    uint      `json:"category_id"`
	OwnerID       uint      `json:"owner_id"`
	CreatedAt     time.Time `json:"created_at"`
	Status        string    `json:"status" gorm:"column:_status"`
	PreviousData  string    `json:"previous_data" gorm:"column:previous_data"`
}
