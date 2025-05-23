package controllers

import (
	"fmt"
	"net/http"
	"time"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type CreateTTNRequest struct {
	OrderID   uint   `json:"order_id"`
	Phone     string `json:"phone"`
	Recipient string `json:"recipient"` // ПІБ
	CityName  string `json:"city_name"`
	Warehouse string `json:"warehouse"` // Відділення
}

func CreateTTN(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var body struct {
		OrderID uint `json:"order_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некоректний запит"})
		return
	}

	var order models.Order
	if err := database.DB.
		Preload("Items.Product").
		First(&order, body.OrderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Замовлення не знайдено"})
		return
	}

	// Перевірка, чи користувач є автором хоча б одного товару
	isOwner := false
	for _, item := range order.Items {
		if item.Product.OwnerID == userID {
			isOwner = true
			break
		}
	}
	if !isOwner {
		c.JSON(http.StatusForbidden, gin.H{"error": "Ви не є автором цього замовлення"})
		return
	}

	if order.Status != "прийнято" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Замовлення ще не підтверджене"})
		return
	}

	// Генерація ТТН (наприклад, UUID або префікс з ідентифікатором)
	ttn := fmt.Sprintf("TTN-%d-%d", order.ID, time.Now().Unix())
	order.TTN = ttn

	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося зберегти ТТН"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "ТТН створено", "ttn": ttn})
}
