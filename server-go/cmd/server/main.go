package main

import (
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"github.com/rs/cors"

	"github.com/wallstreetproject/server-go/internal/config"
	"github.com/wallstreetproject/server-go/internal/market"
	"github.com/wallstreetproject/server-go/internal/ws"
)

func main() {
	cfg := config.Load()

	r := gin.Default()

	// CORS
	r.Use(func(c *gin.Context) {
		cors.New(cors.Options{
			AllowedOrigins:   []string{"*"},
			AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
			AllowedHeaders:   []string{"*"},
			AllowCredentials: true,
		}).HandlerFunc(c.Writer, c.Request)
	})

	// WebSocket endpoint — 实时行情推送
	hub := ws.NewHub()
	go hub.Run()

	// 行情数据采集器
	collector := market.NewCollector(hub, cfg)
	go collector.Start()

	r.GET("/ws", func(c *gin.Context) {
		ws.ServeWS(hub, c.Writer, c.Request)
	})

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "wallstreet-go"})
	})

	// REST API: 获取当前所有行情快照
	r.GET("/api/v1/quotes", func(c *gin.Context) {
		c.JSON(200, collector.GetAllQuotes())
	})

	// REST API: 获取单只股票行情
	r.GET("/api/v1/quotes/:code", func(c *gin.Context) {
		code := c.Param("code")
		quote := collector.GetQuote(code)
		if quote == nil {
			c.JSON(404, gin.H{"error": "stock not found"})
			return
		}
		c.JSON(200, quote)
	})

	// 优雅关闭
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan
		log.Println("Shutting down...")
		collector.Stop()
		os.Exit(0)
	}()

	log.Printf("Go server starting on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
