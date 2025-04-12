package models

import "time"

type Order struct {
	ID        uint        `json:"id" gorm:"primaryKey"`
	UserID    uint        `json:"user_id"`
	CreatedAt time.Time   `json:"created_at"`
	Items     []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
}
