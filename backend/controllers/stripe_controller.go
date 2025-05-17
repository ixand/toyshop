package controllers

import (
	"net/http"
	"os"
	"strconv"
	"toyshop/database"
	"toyshop/models"

	"github.com/gin-gonic/gin"
	"github.com/stripe/stripe-go/v74"
	"github.com/stripe/stripe-go/v74/paymentintent"
)

func CreatePaymentIntent(c *gin.Context) {
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")

	var req struct {
		Amount int64 `json:"amount"` // в копійках: 1000 = 10.00 UAH
	}

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(req.Amount),
		Currency: stripe.String("uah"),
		AutomaticPaymentMethods: &stripe.PaymentIntentAutomaticPaymentMethodsParams{
			Enabled: stripe.Bool(true),
		},
	}

	pi, err := paymentintent.New(params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"clientSecret": pi.ClientSecret})
}

func PaymentSuccess(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var req struct {
		Amount int `json:"amount"` // копійки
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Невірні вхідні дані"})
		return
	}

	var user models.User
	if err := database.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Користувача не знайдено"})
		return
	}

	added := float64(req.Amount) / 100.0
	user.Balance += added

	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не вдалося оновити баланс"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Баланс оновлено",
		"balance": strconv.FormatFloat(user.Balance, 'f', 2, 64),
	})
}
