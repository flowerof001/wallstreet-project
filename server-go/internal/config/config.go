package config

import "os"

// Config holds all server configuration
type Config struct {
	Port       string
	RedisAddr  string
	AKShareURL string // Python 数据服务地址
}

func Load() *Config {
	return &Config{
		Port:       getEnv("PORT", "8080"),
		RedisAddr:  getEnv("REDIS_ADDR", "localhost:6379"),
		AKShareURL: getEnv("AKSHARE_URL", "http://localhost:8001"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
