package main

import (
	"toyshop/controllers"
	"toyshop/database"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// підключення до БД
	database.Connect()

	// маршрути
	r.GET("/users", controllers.GetUsers)
	r.POST("/users", controllers.CreateUser)
	r.PUT("/users/:id", controllers.UpdateUser)
	r.DELETE("/users/:id", controllers.DeleteUser)

	r.GET("/products", controllers.GetProducts)
	r.POST("/products", controllers.CreateProduct)
	r.PUT("/products/:id", controllers.UpdateProduct)
	r.DELETE("/products/:id", controllers.DeleteProduct)

	r.GET("/categories", controllers.GetCategories)
	r.POST("/categories", controllers.CreateCategory)

	// старт сервера
	r.Run(":8080")
}
