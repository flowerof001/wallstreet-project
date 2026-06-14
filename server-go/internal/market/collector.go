package market

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/wallstreetproject/server-go/internal/config"
	"github.com/wallstreetproject/server-go/internal/model"
	"github.com/wallstreetproject/server-go/internal/ws"
)

// Collector periodically fetches market data and broadcasts via WebSocket
type Collector struct {
	hub     *ws.Hub
	cfg     *config.Config
	quotes  map[string]*model.Quote
	mu      sync.RWMutex
	stopCh  chan struct{}
	client  *http.Client
}

func NewCollector(hub *ws.Hub, cfg *config.Config) *Collector {
	return &Collector{
		hub:    hub,
		cfg:    cfg,
		quotes: make(map[string]*model.Quote),
		stopCh: make(chan struct{}),
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

// Start begins the data collection loop — fetches every 3 seconds
func (c *Collector) Start() {
	log.Println("Market data collector started (interval: 3s)")

	indices := model.GetAllIndices()

	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			var updated []*model.Quote

			// Fetch all predefined indices
			for _, idx := range indices {
				quote, err := c.fetchQuote(idx.Code, idx.Market)
				if err != nil {
					log.Printf("Error fetching index %s (%s): %v", idx.Code, idx.Name, err)
					// Fallback to simulated data
					quote = c.simulateQuote(idx.Code, idx.Market)
				}
				c.mu.Lock()
				c.quotes[idx.Code] = quote
				c.mu.Unlock()
				updated = append(updated, quote)
			}

			// Also fetch any user-subscribed individual stocks
			c.mu.RLock()
			for code := range c.quotes {
				found := false
				for _, idx := range indices {
					if idx.Code == code {
						found = true
						break
					}
				}
				if !found {
					quote, err := c.fetchQuote(code, "")
					if err != nil {
						// Keep the cached version on error
						c.mu.RUnlock()
						continue
					}
					c.mu.RUnlock()
					c.mu.Lock()
					c.quotes[code] = quote
					c.mu.Unlock()
					c.mu.RLock()
					updated = append(updated, quote)
				}
			}
			c.mu.RUnlock()

			if len(updated) > 0 {
				c.hub.BroadcastBatch(updated)
				log.Printf("Broadcast %d quotes to %d clients", len(updated), c.hub.ClientCount())
			}

		case <-c.stopCh:
			log.Println("Market data collector stopped")
			return
		}
	}
}

// fetchQuote fetches a single stock quote from the Python AKShare data service
func (c *Collector) fetchQuote(code string, market string) (*model.Quote, error) {
	url := fmt.Sprintf("%s/api/v1/quote/%s", c.cfg.AKShareURL, code)
	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var quote model.Quote
	if err := json.Unmarshal(body, &quote); err != nil {
		return nil, fmt.Errorf("failed to parse quote JSON: %w", err)
	}

	return &quote, nil
}

// FetchHistory fetches historical K-line data from the Python service
func (c *Collector) FetchHistory(code string, period string, count int) ([]model.KLine, error) {
	url := fmt.Sprintf("%s/api/v1/quote/%s/history?period=%s&count=%d",
		c.cfg.AKShareURL, code, period, count)
	resp, err := c.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var result struct {
		Code   string        `json:"code"`
		Period string        `json:"period"`
		KLines []model.KLine `json:"k_lines"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse history JSON: %w", err)
	}

	return result.KLines, nil
}

// simulateQuote generates fallback mock data with less determinism
func (c *Collector) simulateQuote(code string, market string) *model.Quote {
	return &model.Quote{
		Code:          code,
		Name:          code,
		Market:        market,
		CurrentPrice:  1.0, // obviously simulated — client should show indicator
		Change:        0,
		ChangePercent: 0,
		High:          1.0,
		Low:           1.0,
		Open:          1.0,
		PreClose:      1.0,
		Volume:        0,
		Amount:        0,
		UpdateTime:    time.Now(),
	}
}

// Stop signals the collector to stop
func (c *Collector) Stop() {
	close(c.stopCh)
}

// GetAllQuotes returns all cached quotes
func (c *Collector) GetAllQuotes() map[string]*model.Quote {
	c.mu.RLock()
	defer c.mu.RUnlock()
	result := make(map[string]*model.Quote, len(c.quotes))
	for k, v := range c.quotes {
		result[k] = v
	}
	return result
}

// GetQuote returns a single cached quote
func (c *Collector) GetQuote(code string) *model.Quote {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.quotes[code]
}
