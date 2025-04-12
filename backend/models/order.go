package models

import (
	"time"
)

type Order struct {
	ID              uint        `json:"id" gorm:"primaryKey"`
	UserID          uint        `json:"user_id"`
	CreatedAt       time.Time   `json:"created_at"`
	ShippingAddress string      `json:"shipping_address"`
	PaymentStatus   string      `json:"payment_status"`
	Items           []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
}
