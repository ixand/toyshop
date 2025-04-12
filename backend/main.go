package main

import (
	"toyshop/controllers"
	"toyshop/database"

	"toyshop/middleware"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// підключення до БД
	database.Connect()

	// маршрути
	r.GET("/users", controllers.GetUsers)
	r.PUT("/users/:id", controllers.UpdateUser)
	r.DELETE("/users/:id", controllers.DeleteUser)

	r.GET("/products", controllers.GetProducts)
	r.POST("/products", controllers.CreateProduct)
	r.PUT("/products/:id", controllers.UpdateProduct)
	r.DELETE("/products/:id", controllers.DeleteProduct)

	r.GET("/categories", controllers.GetCategories)
	r.POST("/categories", controllers.CreateCategory)
	r.POST("/orders", middleware.AuthMiddleware(), controllers.CreateOrder)
	r.POST("/reviews", middleware.AuthMiddleware(), controllers.CreateReview)

	r.POST("/register", controllers.CreateUser)
	r.POST("/login", controllers.Login)

	r.GET("/me", middleware.AuthMiddleware(), controllers.GetCurrentUser)

	r.GET("/reviews/:product_id", controllers.GetReviewsByProduct)

	// старт сервера
	r.Run(":8080")
}
