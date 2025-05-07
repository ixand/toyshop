package controllers

import (
	"fmt"
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

func min(a, b uint) uint {
	if a < b {
		return a
	}
	return b
}
func max(a, b uint) uint {
	if a > b {
		return a
	}
	return b
}

type MessageRequest struct {
	ReceiverID uint   `json:"receiver_id"`
	Content    string `json:"content"`
	ProductID  uint   `json:"product_id"` // 🔥 нове поле
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

	threadID := fmt.Sprintf("%d_%d_%d", min(senderID, input.ReceiverID), max(senderID, input.ReceiverID), input.ProductID)

	message := models.Message{
		SenderID:   senderID,
		ReceiverID: input.ReceiverID,
		Content:    input.Content,
		ThreadID:   threadID,
	}

	if input.ReceiverID == senderID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Не можна надсилати повідомлення самому собі"})
		return
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

	var messages []struct {
		ID         uint   `json:"id"`
		SenderID   uint   `json:"sender_id"`
		ReceiverID uint   `json:"receiver_id"` // додано
		SenderName string `json:"sender_name"`
		Content    string `json:"content"`
		CreatedAt  string `json:"created_at"`
		ThreadID   string `json:"thread_id"`
		ProductID  uint   `json:"product_id"`
	}

	query := `
	SELECT DISTINCT ON (thread_id) 
		messages.id, messages.sender_id, messages.receiver_id, users._name as sender_name, 
		messages.content, messages.created_at, messages.thread_id, messages.product_id
	FROM messages
	LEFT JOIN users ON users.id = messages.sender_id
	WHERE messages.receiver_id = ? OR messages.sender_id = ?
	ORDER BY thread_id, created_at DESC
	`

	if err := database.DB.Raw(query, userID, userID).Scan(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося завантажити повідомлення"})
		return
	}

	c.JSON(http.StatusOK, messages)
}

func GetThreadMessages(c *gin.Context) {
	threadID := c.Param("thread_id")

	var messages []models.Message
	if err := database.DB.
		Where("thread_id = ?", threadID).
		Order("created_at").
		Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, messages)
}

func GetMessagesByThread(c *gin.Context) {
	threadID := c.Param("thread_id")

	var messages []models.Message
	if err := database.DB.
		Where("thread_id = ?", threadID).
		Order("created_at").
		Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, messages)
}
