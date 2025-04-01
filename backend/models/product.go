package models

type Product struct {
	ID            uint    `json:"id" gorm:"primaryKey"`
	Name          string  `json:"name"`
	Description   string  `json:"description"`
	Price         float64 `json:"price"`
	ImageURL      string  `json:"image_url"`
	StockQuantity int     `json:"stock_quantity"`
	CategoryID    uint    `json:"category_id"`
	OwnerID       uint    `json:"owner_id"`
}
