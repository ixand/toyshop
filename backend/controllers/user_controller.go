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

type UpdateAttempt struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Role     string `json:"role"`
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

	// Створити токен
	token, err := utils.GenerateJWT(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося створити токен"})
		return
	}

	// Повертаємо токен і користувача одним JSON-об'єктом
	c.JSON(http.StatusOK, gin.H{
		"message": "Успішний вхід",
		"token":   token,
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

	if input.Name == "" || input.Email == "" || len(input.Password) < 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Ім’я, email та пароль обов'язкові"})
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

	var input UpdateAttempt
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Name == "" || input.Email == "" || len(input.Password) < 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Ім’я, email та пароль не можуть бути порожні"})
		return
	}

	// Хешуємо новий пароль
	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Оновлюємо поля
	user.Name = input.Name
	user.Email = input.Email
	user.PasswordHash = hashedPassword
	user.Role = input.Role
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
		"role":       user.Role,
		"created_at": user.CreatedAt, // ← додай це поле
	})
}
