package models

import "time"

type User struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	Name         string    `json:"name" gorm:"column:_name"`
	Phone        string    `json:"phone"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	Role         string    `json:"role" gorm:"column:_role"`
	Balance      float64   `json:"balance" gorm:"default:0"`
	CreatedAt    time.Time `json:"created_at"`
}
