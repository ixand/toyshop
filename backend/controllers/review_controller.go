package controllers

import (
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type ReviewRequest struct {
	ProductID uint   `json:"product_id"`
	Rating    int    `json:"rating"`
	Comment   string `json:"comment"`
}

func CreateReview(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	userID := userIDRaw.(uint)

	var input ReviewRequest
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Rating < 1 || input.Rating > 5 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Оцінка має бути від 1 до 5"})
		return
	}

	review := models.Review{
		ProductID: input.ProductID,
		UserID:    userID,
		Rating:    input.Rating,
		Comment:   input.Comment,
	}

	database.DB.Create(&review)

	c.JSON(http.StatusCreated, gin.H{"message": "Відгук додано!"})
}
