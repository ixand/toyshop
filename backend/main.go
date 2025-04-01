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

	// старт сервера
	r.Run(":8080")
}
