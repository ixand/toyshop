package models

import "time"

type Order struct {
	ID                  uint        `json:"id" gorm:"primaryKey"`
	UserID              uint        `json:"user_id"`
	User                User        `json:"user"`
	CreatedAt           time.Time   `json:"created_at"`
	ShippingAddress     string      `json:"shipping_address"`
	RecipientFirstName  string      `json:"recipient_first_name"`
	RecipientLastName   string      `json:"recipient_last_name"`
	RecipientMiddleName string      `json:"recipient_middle_name"`
	PaymentStatus       string      `json:"payment_status"`
	PaymentType         string      `json:"payment_type"`
	Status              string      `json:"status" gorm:"column:_status"`
	Items               []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
	TTN                 string      `json:"ttn"`
	TotalPrice          float64     `json:"total_price"`
}
