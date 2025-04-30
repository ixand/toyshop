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
	r.POST("/categories", controllers.CreateCategory)

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
		auth.GET("/my-products", controllers.GetMyProducts)
		auth.GET("/my-orders", controllers.GetMyOrders)
		auth.PUT("/orders/:id/cancel", controllers.CancelOrder)

		auth.GET("/messages/:user_id", controllers.GetThreadMessages)
		auth.GET("/messages/thread/:thread_id", controllers.GetMessagesByThread)

		auth.POST("/messages", controllers.CreateMessage)
		auth.GET("/messages", controllers.GetMyMessages)

	}

	// старт сервера
	r.Run("0.0.0.0:8080")

}
