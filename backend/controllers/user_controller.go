package controllers

import (
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func GetUsers(c *gin.Context) {
	var users []models.User
	result := database.DB.Find(&users)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, users)
}

type RegisterAttempt struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

type LoginAttempt struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func Login(c *gin.Context) {
	var input LoginAttempt
	var user models.User

	// Зчитати дані з тіла запиту
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Знайти користувача з таким email
	if err := database.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неправильний email або пароль"})
		return
	}

	// Перевірити пароль
	if !CheckPasswordHash(input.Password, user.PasswordHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неправильний email або пароль"})
		return
	}

	// Успішний вхід
	c.JSON(http.StatusOK, gin.H{
		"message": "Успішний вхід",
		"user": gin.H{
			"id":    user.ID,
			"name":  user.Name,
			"email": user.Email,
			"role":  user.Role,
		},
	})
}

func CreateUser(c *gin.Context) {
	var input RegisterAttempt

	// Прочитати JSON з тіла запиту і перетворити в структуру User
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User

	// Перевірити, чи існує користувач з таким email
	if err := database.DB.Where("email = ?", input.Email).First(&user).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Користувач з таким email вже існує"})
		return
	}

	// Хешувати пароль
	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Зберегти користувача в базу
	user.Name = input.Name
	user.Email = input.Email
	user.PasswordHash = hashedPassword
	user.Role = "user" // За замовчуванням роль "user"
	result := database.DB.Create(&user)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	// Повернути створеного користувача у відповіді
	c.JSON(http.StatusCreated, user)
}

func UpdateUser(c *gin.Context) {
	id := c.Param("id") // Отримуємо id з URL

	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}

	var input models.User
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Оновлюємо поля
	user.Name = input.Name
	user.Email = input.Email
	user.Role = input.Role
	user.PasswordHash = input.PasswordHash

	database.DB.Save(&user)

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
