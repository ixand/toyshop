package controllers

import (
	"net/http"
	"time"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type ReviewRequest struct {
	ProductID uint   `json:"product_id"`
	Rating    int    `json:"rating"`
	Comment   string `json:"comment"`
}

type ReviewWithAuthor struct {
	ID        uint      `json:"id"`
	ProductID uint      `json:"product_id"`
	UserID    uint      `json:"user_id"`
	UserName  string    `json:"user_name"`
	Rating    int       `json:"rating"`
	Comment   string    `json:"comment"`
	CreatedAt time.Time `json:"created_at"`
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

	result := database.DB.Create(&review)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Відгук додано!"})
}

type ReviewWithUser struct {
	models.Review
	UserName  string    `json:"user_name"`
	UserSince time.Time `json:"user_since"`
}

func GetReviewsByProduct(c *gin.Context) {
	productID := c.Param("product_id")
	var reviews []ReviewWithAuthor

	err := database.DB.
		Table("reviews").
		Select("reviews.id, reviews.product_id, reviews.user_id, users.name as user_name, reviews.rating, reviews.comment, reviews.created_at").
		Joins("left join users on users.id = reviews.user_id").
		Where("product_id = ?", productID).
		Scan(&reviews).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, reviews)
}

func GetReviewsByAuthor(c *gin.Context) {
	authorID := c.Param("author_id")
	var reviews []ReviewWithAuthor

	err := database.DB.
		Table("reviews").
		Select("reviews.id, reviews.product_id, reviews.user_id, users.name as user_name, reviews.rating, reviews.comment, reviews.created_at").
		Joins("left join users on users.id = reviews.user_id").
		Joins("left join products on products.id = reviews.product_id").
		Where("products.owner_id = ?", authorID).
		Scan(&reviews).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, reviews)
}
