package models

type OrderItem struct {
	ID        uint `json:"id" gorm:"primaryKey"`
	OrderID   uint `json:"order_id"`
	ProductID uint `json:"product_id"`
	Quantity  int  `json:"quantity"`
}
