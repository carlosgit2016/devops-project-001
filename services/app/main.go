package main

import (
	"fmt"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.Static("/", "/var/www/static")

	port := os.Getenv("PORT")
	router.Run(fmt.Sprintf(":%s", port))
}
