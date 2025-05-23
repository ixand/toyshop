package controllers

import (
	"net/http"
	"toyshop/database"
	"toyshop/models"
	"toyshop/utils"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func GetUsers(c *gin.Context) {
	var users []models.User
	if err := database.DB.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, users)
}

type RegisterAttempt struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Phone    string `json:"phone"`
}

type LoginAttempt struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type UpdateAttempt struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Role     string `json:"role"`
	Password string `json:"password"`
	Phone    string `json:"phone"`
}

func Login(c *gin.Context) {
	var input LoginAttempt
	var user models.User

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Where("email = ?", input.Email).First(&user).Error; err != nil || !CheckPasswordHash(input.Password, user.PasswordHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неправильний email або пароль"})
		return
	}

	token, err := utils.GenerateJWT(user.ID, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося створити токен"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Успішний вхід",
		"token":   token,
		"user": gin.H{
			"id":    user.ID,
			"name":  user.Name,
			"email": user.Email,
			"role":  user.Role,
			"phone": user.Phone,
		},
	})
}

func CreateUser(c *gin.Context) {
	var input RegisterAttempt
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Name == "" || input.Email == "" || input.Password == "" || input.Phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Усі поля є обов'язковими"})
		return
	}

	var existing models.User
	if err := database.DB.Where("email = ?", input.Email).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Користувач з таким email вже існує"})
		return
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка хешування паролю"})
		return
	}

	user := models.User{
		Name:         input.Name,
		Email:        input.Email,
		PasswordHash: hashedPassword,
		Phone:        input.Phone,
		Role:         "user",
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка створення користувача"})
		return
	}

	c.JSON(http.StatusCreated, user)
}

func UpdateUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}

	var input UpdateAttempt
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Name == "" || input.Email == "" || input.Password == "" || input.Phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Усі поля обов'язкові"})
		return
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка хешування паролю"})
		return
	}

	user.Name = input.Name
	user.Email = input.Email
	user.PasswordHash = hashedPassword
	user.Phone = input.Phone
	user.Role = input.Role

	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Помилка оновлення користувача"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func DeleteUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}
	database.DB.Delete(&user)
	c.JSON(http.StatusOK, gin.H{"message": "Користувача видалено"})
}

func GetCurrentUser(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         user.ID,
		"name":       user.Name,
		"email":      user.Email,
		"phone":      user.Phone,
		"role":       user.Role,
		"balance":    user.Balance,
		"created_at": user.CreatedAt,
	})
}

type TopUpBalanceInput struct {
	Amount float64 `json:"amount"`
}

func TopUpBalance(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}

	var input TopUpBalanceInput
	if err := c.ShouldBindJSON(&input); err != nil || input.Amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Сума повинна бути більшою за 0"})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}

	user.Balance += input.Amount
	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити баланс"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Баланс успішно поповнено",
		"balance": user.Balance,
	})
}
