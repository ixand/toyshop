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

	r.PUT("/products/:id", controllers.UpdateProduct)
	r.DELETE("/products/:id", controllers.DeleteProduct)

	r.GET("/categories", controllers.GetCategories)

	r.POST("/register", controllers.CreateUser)
	r.POST("/login", controllers.Login)

	r.GET("/reviews/:product_id", controllers.GetReviewsByProduct)

	auth := r.Group("/")
	auth.Use(middleware.AuthMiddleware())
	{
		auth.POST("/products", controllers.CreateProduct)
		auth.POST("/orders", controllers.CreateOrder)
		auth.POST("/reviews", controllers.CreateReview)
		auth.GET("/me", controllers.GetCurrentUser)
	}

	// старт сервера
	r.Run(":8080")
}
