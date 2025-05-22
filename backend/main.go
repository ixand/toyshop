package main

import (
	"toyshop/controllers"
	"toyshop/database"
	"toyshop/middleware"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	r := gin.Default()

	// Підключення до БД
	database.Connect()

	// Публічні маршрути
	r.POST("/register", controllers.CreateUser)
	r.POST("/login", controllers.Login)
	r.GET("/categories", controllers.GetCategories)

	r.GET("/users", controllers.GetUsers)

	r.POST("/create-payment-intent", controllers.CreatePaymentIntent)
	r.GET("/products", controllers.GetProducts)
	r.GET("/products/active", controllers.GetActiveProducts)
	r.GET("/reviews/:product_id", controllers.GetReviewsByProduct)
	r.GET("/reviews/author/:author_id", controllers.GetReviewsByAuthor)
	r.PUT("/users/:id", controllers.UpdateUser)
	// Маршрути з авторизацією
	auth := r.Group("/")
	auth.Use(middleware.AuthMiddleware())
	{
		auth.GET("/me", controllers.GetCurrentUser)
		auth.GET("/my-products", controllers.GetMyProducts)
		auth.POST("/products", controllers.CreateProduct)
		auth.PUT("/products/:id", controllers.UpdateProduct)
		auth.DELETE("/products/:id", controllers.DeleteProduct)

		auth.GET("/my-orders", controllers.GetMyOrders)
		auth.POST("/orders", controllers.CreateOrder)
		auth.PUT("/orders/:id/cancel", controllers.CancelOrder)
		auth.POST("/orders/:id/pay", controllers.PayForOrder)

		auth.POST("/reviews", controllers.CreateReview)

		auth.GET("/messages", controllers.GetMyMessages)
		auth.POST("/messages", controllers.CreateMessage)
		auth.GET("/messages/:user_id", controllers.GetThreadMessages)
		auth.GET("/messages/thread/:thread_id", controllers.GetMessagesByThread)

		auth.POST("/top-up", controllers.TopUpBalance)
		auth.POST("/payment-success", controllers.PaymentSuccess)
	}

	// Адмінські маршрути
	admin := r.Group("/admin")
	admin.Use(middleware.AuthMiddleware(), middleware.AdminOnly())
	{
		admin.GET("/products", controllers.GetAllProductsForAdmin)
		admin.PUT("/products/:id/status", controllers.UpdateProductStatus)
	}

	// Старт сервера
	r.Run("0.0.0.0:8080")
}
