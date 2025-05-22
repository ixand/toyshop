package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"toyshop/utils"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware витягує user_id і role з JWT і додає в контекст
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Авторизація потрібна"})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		fmt.Println("🔐 Token string:", tokenString)
		claims, err := utils.ParseJWT(tokenString)
		fmt.Printf("✅ Claims: user_id=%d, role=%s\n", claims.UserID, claims.Role)

		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Недійсний токен"})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)

		c.Next()
	}

}

// AdminOnly перевіряє, що роль користувача — admin
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		roleRaw, exists := c.Get("role")
		if !exists || roleRaw.(string) != "admin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Доступ дозволений лише адміністраторам"})
			c.Abort()
			return
		}
		c.Next()
	}
}
