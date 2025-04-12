package controllers

import (
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type OrderRequest struct {
	Items []struct {
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

	order := models.Order{
		UserID: userID,
	}

	result := database.DB.Create(&order)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	for _, item := range request.Items {
		orderItem := models.OrderItem{
			OrderID:   order.ID,
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
		}
		database.DB.Create(&orderItem)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Замовлення створено",
		"order_id": order.ID,
	})
}
