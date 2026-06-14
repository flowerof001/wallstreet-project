package ws

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/wallstreetproject/server-go/internal/model"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins
	},
}

// Client represents a single WebSocket connection
type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte
	subs   map[string]bool // subscribed stock codes
	mu     sync.RWMutex
	locale string
}

// Hub maintains the set of active clients and broadcasts messages
type Hub struct {
	clients    map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		broadcast:  make(chan []byte, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

// Run starts the hub's event loop
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			log.Printf("Client connected. Total: %d", len(h.clients))

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()
			log.Printf("Client disconnected. Total: %d", len(h.clients))

		case message := <-h.broadcast:
			h.mu.RLock()
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

// BroadcastQuote sends a quote update to all connected clients
func (h *Hub) BroadcastQuote(quote *model.Quote) {
	data, err := json.Marshal(map[string]interface{}{
		"type":  "quote",
		"data":  quote,
		"ts":    time.Now().UnixMilli(),
	})
	if err != nil {
		log.Printf("Error marshaling quote: %v", err)
		return
	}
	h.broadcast <- data
}

// BroadcastBatch sends multiple quotes at once
func (h *Hub) BroadcastBatch(quotes []*model.Quote) {
	data, err := json.Marshal(map[string]interface{}{
		"type":  "batch",
		"data":  quotes,
		"ts":    time.Now().UnixMilli(),
	})
	if err != nil {
		log.Printf("Error marshaling batch: %v", err)
		return
	}
	h.broadcast <- data
}

// ClientCount returns the number of connected clients
func (h *Hub) ClientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// Client read pump
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(512)
	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WS read error: %v", err)
			}
			break
		}
		// Handle client messages (subscribe/unsubscribe)
		var msg map[string]interface{}
		if json.Unmarshal(message, &msg) == nil {
			switch msg["action"] {
			case "subscribe":
				if codes, ok := msg["codes"].([]interface{}); ok {
					c.mu.Lock()
					for _, code := range codes {
						c.subs[code.(string)] = true
					}
					c.mu.Unlock()
				}
			case "unsubscribe":
				if codes, ok := msg["codes"].([]interface{}); ok {
					c.mu.Lock()
					for _, code := range codes {
						delete(c.subs, code.(string))
					}
					c.mu.Unlock()
				}
			}
		}
	}
}

// Client write pump
func (c *Client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ServeWS handles WebSocket upgrade requests
func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WS upgrade error: %v", err)
		return
	}

	client := &Client{
		hub:  hub,
		conn: conn,
		send: make(chan []byte, 256),
		subs: make(map[string]bool),
	}

	hub.register <- client

	go client.writePump()
	go client.readPump()
}
