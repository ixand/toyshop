package controllers

import (
	"net/http"
	"strconv"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

type MessageRequest struct {
	ReceiverID uint   `json:"receiver_id"`
	Content    string `json:"content"`
}

func CreateMessage(c *gin.Context) {
	senderIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	senderID := senderIDRaw.(uint)

	var input MessageRequest
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	message := models.Message{
		SenderID:   senderID,
		ReceiverID: input.ReceiverID,
		Content:    input.Content,
	}
	if err := database.DB.Create(&message).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Повідомлення надіслано"})
}

func GetMyMessages(c *gin.Context) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}
	userID := userIDRaw.(uint)

	// Завантажуємо повідомлення разом з інформацією про відправника
	var messages []struct {
		ID         uint   `json:"id"`
		SenderID   uint   `json:"sender_id"`
		SenderName string `json:"sender_name"`
		Content    string `json:"content"`
		CreatedAt  string `json:"created_at"`
	}

	err := database.DB.
		Table("messages").
		Select("messages.id, messages.sender_id, users._name as sender_name, messages.content, messages.created_at").
		Joins("left join users on users.id = messages.sender_id").
		Where("messages.receiver_id = ?", userID).
		Order("messages.created_at DESC").
		Scan(&messages).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося завантажити повідомлення"})
		return
	}

	c.JSON(http.StatusOK, messages)
}

func GetThreadMessages(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID := userIDRaw.(uint)
	otherIDParam := c.Param("user_id")
	otherID, err := strconv.ParseUint(otherIDParam, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Невірний ID"})
		return
	}

	var messages []models.Message
	err = database.DB.
		Where("(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
			userID, otherID, otherID, userID).
		Order("created_at").
		Find(&messages).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, messages)
}
