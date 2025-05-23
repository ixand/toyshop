package controllers

import (
	"fmt"
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

func GetMyOrders(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	userID := userIDRaw.(uint)

	var orders []models.Order
	err := database.DB.
		Preload("Items.Product").
		Preload("User").
		Where("user_id = ?", userID).
		Find(&orders).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, orders)
}

type OrderRequest struct {
	ShippingAddress     string `json:"shipping_address"`
	RecipientFirstName  string `json:"recipient_first_name"`
	RecipientLastName   string `json:"recipient_last_name"`
	RecipientMiddleName string `json:"recipient_middle_name"`
	PaymentType         string `json:"payment_type"`
	Items               []struct {
		ProductID uint `json:"product_id"`
		Quantity  int  `json:"quantity"`
	} `json:"items"`
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
		UserID:              userID,
		ShippingAddress:     request.ShippingAddress,
		RecipientFirstName:  request.RecipientFirstName,
		RecipientLastName:   request.RecipientLastName,
		RecipientMiddleName: request.RecipientMiddleName,
		PaymentType:         request.PaymentType,
		PaymentStatus:       "неоплачений",
		Status:              "в обробці",
		TotalPrice:          totalPrice,
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
	if err := database.DB.
		Preload("Items.Product").
		Preload("User").
		First(&order, orderID).Error; err != nil {

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
	if err := database.DB.
		Preload("Items").
		Preload("User").
		First(&order, orderID).Error; err != nil {

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

func GetIncomingOrders(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var orders []models.Order
	err := database.DB.
		Joins("JOIN order_items ON order_items.order_id = orders.id").
		Joins("JOIN products ON products.id = order_items.product_id").
		Where("products.owner_id = ?", userID).
		Preload("Items.Product").
		Preload("User").
		Find(&orders).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка завантаження"})
		return
	}

	c.JSON(http.StatusOK, orders)
}

// PUT /orders/:id/status
func UpdateOrderStatus(c *gin.Context) {
	orderID := c.Param("id")
	var body struct {
		Status string `json:"status"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некоректний запит"})
		return
	}

	var order models.Order
	if err := database.DB.Preload("Items.Product").First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Замовлення не знайдено"})
		return
	}

	// Доступ лише автору товару
	userID := c.MustGet("user_id").(uint)
	isOwner := false
	for _, item := range order.Items {
		if item.Product.OwnerID == userID {
			isOwner = true
			break
		}
	}

	if !isOwner {
		c.JSON(http.StatusForbidden, gin.H{"error": "Ви не маєте доступу до цього замовлення"})
		return
	}

	// Дозволені статуси
	if body.Status != "прийнято" && body.Status != "відхилено" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Недійсний статус"})
		return
	}

	// Дозволити відхиляти навіть якщо вже підтверджено
	if body.Status == "відхилено" && (order.Status == "в обробці" || order.Status == "прийнято") {
		order.Status = "відхилено"
	} else if body.Status == "прийнято" && order.Status == "в обробці" {
		order.Status = "прийнято"
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Недозволений перехід статусу"})
		return
	}

	// ЗБЕРЕЖЕННЯ В БАЗУ
	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити статус у базі"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статус оновлено", "new_status": order.Status})

}

func GetMyDeliveries(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var orders []models.Order
	err := database.DB.
		Joins("JOIN order_items ON order_items.order_id = orders.id").
		Joins("JOIN products ON products.id = order_items.product_id").
		Where("orders.user_id = ? AND orders._status = ?", userID, "прийнято").
		Preload("Items.Product").
		Preload("User").
		Find(&orders).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка завантаження доставок"})
		return
	}

	c.JSON(http.StatusOK, orders)
}

func ShipOrder(c *gin.Context) {
	orderID := c.Param("id")
	userID := c.MustGet("user_id").(uint)

	var order models.Order
	if err := database.DB.
		Preload("Items.Product").
		First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Замовлення не знайдено"})
		return
	}

	// перевірка прав доступу
	isOwner := false
	for _, item := range order.Items {
		if item.Product.OwnerID == userID {
			isOwner = true
			break
		}
	}
	if !isOwner {
		c.JSON(http.StatusForbidden, gin.H{"error": "Ви не є автором товару"})
		return
	}

	// перевірка статусу та ТТН
	if order.Status != "прийнято" || order.TTN == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Замовлення ще не готове до відправки"})
		return
	}

	// оновлення статусу
	order.Status = "відправлено"
	if err := database.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити замовлення"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Замовлення позначено як відправлене"})
}
