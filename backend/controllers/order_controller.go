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

	for i := range orderItems {
		orderItems[i].OrderID = order.ID
		if err := tx.Create(&orderItems[i]).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка при створенні позицій замовлення"})
			return
		}
	}
	order.Items = orderItems

	tx.Commit()

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Замовлення створено",
		"order_id":    order.ID,
		"total_price": totalPrice,
	})
}

func CancelOrder(c *gin.Context) {
	orderID := c.Param("id")
	userID := c.MustGet("user_id").(uint)

	var order models.Order
	if err := database.DB.Preload("Items.Product").First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Замовлення не знайдено"})
		return
	}

	if order.Status == "скасований" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Замовлення вже скасовано"})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Користувача не знайдено"})
		return
	}

	// Повернення коштів
	if order.PaymentStatus == "оплачено" {
		user.Balance += order.TotalPrice
	}

	// Повернення кількості товару
	for _, item := range order.Items {
		item.Product.StockQuantity += item.Quantity
		if err := database.DB.Save(&item.Product).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка повернення товару"})
			return
		}
	}

	order.Status = "скасований"

	// зберігаємо зміни
	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити баланс"})
		return
	}
	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити замовлення"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Замовлення скасовано, кошти повернуто"})
}

func PayForOrder(c *gin.Context) {
	orderID := c.Param("id")
	userID := c.MustGet("user_id").(uint)

	var order models.Order
	if err := database.DB.Preload("Items").First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Замовлення не знайдено"})
		return
	}

	if order.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Це не ваше замовлення"})
		return
	}

	if order.PaymentStatus == "оплачено" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Замовлення вже оплачено"})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Користувач не знайдений"})
		return
	}

	if user.Balance < order.TotalPrice {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Недостатньо коштів"})
		return
	}

	user.Balance -= order.TotalPrice
	order.PaymentStatus = "оплачено"
	order.Status = "в дорозі"

	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка оновлення користувача"})
		return
	}
	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка оновлення замовлення"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Оплата успішна"})
}
