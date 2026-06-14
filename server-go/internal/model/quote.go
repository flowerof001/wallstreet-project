package model

import "time"

// Quote represents a real-time stock quote
type Quote struct {
	Code          string    `json:"code"`
	Name          string    `json:"name"`
	Market        string    `json:"market"` // sh, sz, bj, hk, us
	CurrentPrice  float64   `json:"current_price"`
	Change        float64   `json:"change"`
	ChangePercent float64   `json:"change_percent"`
	High          float64   `json:"high"`
	Low           float64   `json:"low"`
	Open          float64   `json:"open"`
	PreClose      float64   `json:"pre_close"`
	Volume        int64     `json:"volume"`
	Amount        float64   `json:"amount"`
	UpdateTime    time.Time `json:"update_time"`
}

// KLine represents a single candlestick / OHLC bar
type KLine struct {
	Date      string  `json:"date"`
	Open      float64 `json:"open"`
	Close     float64 `json:"close"`
	High      float64 `json:"high"`
	Low       float64 `json:"low"`
	Volume    int64   `json:"volume"`
	Amount    float64 `json:"amount"`
	ChangePct float64 `json:"change_pct"`
}

// MarketIndex defines a market index symbol
type MarketIndex struct {
	Code   string `json:"code"`
	Name   string `json:"name"`
	Market string `json:"market"`
}

// Predefined market indices
var MarketIndices = map[string][]MarketIndex{
	"shanghai_shenzhen": {
		{Code: "000001", Name: "上证指数", Market: "sh"},
		{Code: "399001", Name: "深证成指", Market: "sz"},
		{Code: "399006", Name: "创业板指", Market: "sz"},
		{Code: "000688", Name: "科创50", Market: "sh"},
	},
	"beijing": {
		{Code: "899050", Name: "北证50", Market: "bj"},
	},
	"hongkong": {
		{Code: "HSI", Name: "恒生指数", Market: "hk"},
		{Code: "HSCCI", Name: "红筹指数", Market: "hk"},
		{Code: "HSCEI", Name: "国企指数", Market: "hk"},
		{Code: "VHSI", Name: "恒指波幅指数", Market: "hk"},
	},
	"us": {
		{Code: "DJI", Name: "道琼斯工业指数", Market: "us"},
		{Code: "IXIC", Name: "纳斯达克综合指数", Market: "us"},
		{Code: "GSPC", Name: "标普500指数", Market: "us"},
	},
}

// GetAllIndices returns all tracked indices across all markets
func GetAllIndices() []MarketIndex {
	var all []MarketIndex
	for _, indices := range MarketIndices {
		all = append(all, indices...)
	}
	return all
}
