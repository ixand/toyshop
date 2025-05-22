package controllers

import (
	"net/http"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
)

func GetProducts(c *gin.Context) {
	var products []models.Product
	result := database.DB.Find(&products)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, products)
}

func GetActiveProducts(c *gin.Context) {
	var products []models.Product
	if err := database.DB.Where("_status = ?", "active").Find(&products).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося завантажити активні товари"})
		return
	}
	c.JSON(http.StatusOK, products)
}

func GetMyProducts(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var products []models.Product
	if err := database.DB.Where("owner_id = ?", userID).Find(&products).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося завантажити товари"})
		return
	}

	c.JSON(http.StatusOK, products)
}

func CreateProduct(c *gin.Context) {

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Не авторизовано"})
		return
	}

	var product models.Product
	product.Status = "pending"
	product.PreviousData = "{}" // порожній обʼєкт JSON — валідне значення

	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	product.OwnerID = userID.(uint)

	if err := database.DB.Create(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, product)
}

func UpdateProduct(c *gin.Context) {
	id := c.Param("id")

	var product models.Product
	if err := database.DB.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Товар не знайдено"})
		return
	}

	// Створюємо мапу попередніх значень
	prevMap := map[string]interface{}{
		"id":             product.ID,
		"name":           product.Name,
		"description":    product.Description,
		"price":          product.Price,
		"image_url":      product.ImageURL,
		"location":       product.Location,
		"stock_quantity": product.StockQuantity,
		"category_id":    product.CategoryID,
		"owner_id":       product.OwnerID,
		"created_at":     product.CreatedAt.Format("2006-01-02T15:04:05Z"),
		"status":         product.Status,
	}

	// Отримуємо нові дані
	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Мапінг ключів на назви колонок у базі
	if val, ok := input["name"]; ok {
		input["_name"] = val
		delete(input, "name")
	}
	if val, ok := input["description"]; ok {
		input["_description"] = val
		delete(input, "description")
	}
	if val, ok := input["location"]; ok {
		input["_location"] = val
		delete(input, "location")
	}
	if val, ok := input["status"]; ok {
		input["_status"] = val
		delete(input, "status")
	}

	// Додаємо попередні дані як JSON
	input["previous_data"] = prevMap

	// Оновлюємо запис
	if err := database.DB.Model(&product).Updates(input).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, product)
}

func DeleteProduct(c *gin.Context) {
	id := c.Param("id")

	var product models.Product
	if err := database.DB.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Товар не знайдено"})
		return
	}

	if err := database.DB.Delete(&product).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Товар видалено"})
}

func GetAllProducts(c *gin.Context) {
	var products []models.Product
	if err := database.DB.Find(&products).Error; err != nil {
		c.JSON(500, gin.H{"error": "Не вдалося завантажити продукти"})
		return
	}
	c.JSON(200, products)
}

func UpdateProductStatus(c *gin.Context) {
	id := c.Param("id")

	// Приймаємо JSON з ключем "status"
	var body struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некоректні дані"})
		return
	}

	// Валідація статусу (тільки дозволені значення)
	allowedStatuses := map[string]bool{
		"active":   true,
		"inactive": true,
		"pending":  true,
	}
	if !allowedStatuses[body.Status] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неприпустиме значення статусу"})
		return
	}

	// Знаходимо товар
	var product models.Product
	if err := database.DB.First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Товар не знайдено"})
		return
	}

	// Дозволено змінювати тільки товари зі статусом "pending"
	if product.Status != "pending" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Статус можна змінити лише для товарів зі статусом 'очікується'"})
		return
	}

	// Оновлюємо статус
	if err := database.DB.Model(&product).Update("_status", body.Status).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити статус"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статус оновлено"})
}

func GetAllProductsForAdmin(c *gin.Context) {
	var products []models.Product
	if err := database.DB.Where("_status = ?", "pending").Find(&products).Error; err != nil {
		c.JSON(500, gin.H{"error": "Не вдалося завантажити продукти"})
		return
	}
	c.JSON(200, products)
}
