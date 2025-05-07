package controllers

import (
	"fmt"
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type OrderRequest struct {
	ShippingAddress string `json:"shipping_address"`
	Items           []struct {
		ProductID uint `json:"product_id"`
		Quantity  int  `json:"quantity"`
	} `json:"items"`
}

func GetMyOrders(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	userID := userIDRaw.(uint)

	var orders []models.Order
	err := database.DB.Preload("Items.Product").Where("user_id = ?", userID).Find(&orders).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, orders)
}

func CreateOrder(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	userID := userIDRaw.(uint)

	var request OrderRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var totalPrice float64
	var orderItems []models.OrderItem

	// Починаємо транзакцію
	tx := database.DB.Begin()

	for _, item := range request.Items {
		var product models.Product
		if err := tx.First(&product, item.ProductID).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusNotFound, gin.H{"error": "Товар не знайдено"})
			return
		}

		if product.StockQuantity < item.Quantity {
			tx.Rollback()
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("Недостатньо товару '%s' на складі", product.Name),
			})
			return
		}

		// Зменшуємо кількість товару на складі
		product.StockQuantity -= item.Quantity
		if err := tx.Save(&product).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка при оновленні кількості товару"})
			return
		}

		totalPrice += product.Price * float64(item.Quantity)
		orderItems = append(orderItems, models.OrderItem{
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
			UnitPrice: product.Price,
		})
	}

	order := models.Order{
		UserID:          userID,
		ShippingAddress: request.ShippingAddress,
		PaymentStatus:   "неоплачений",
		Status:          "в обробці",
		TotalPrice:      totalPrice,
	}

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	for _, item := range orderItems {
		item.OrderID = order.ID
		if err := tx.Create(&item).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка при створенні позицій замовлення"})
			return
		}
	}

	tx.Commit()

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Замовлення створено",
		"order_id":    order.ID,
		"total_price": totalPrice,
	})
}

func CancelOrder(c *gin.Context) {
	orderID := c.Param("id")

	if err := database.DB.Model(&models.Order{}).
		Where("id = ?", orderID).
		Update("_status", "скасований").Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося скасувати замовлення"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Замовлення скасовано"})
}
