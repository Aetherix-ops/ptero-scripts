// =============================================================
//  pterodactyl-scripts — node-monitor/monitor.go
//  Realtime terminal dashboard for Pterodactyl servers
//  Refreshes every second, shows RAM/CPU for all servers
//
//  Usage:
//    go run monitor.go
//    go build -o node-monitor && ./node-monitor
// =============================================================

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

// ── CONFIG ────────────────────────────────────────────────────
var (
	PANEL_URL       = getEnv("PANEL_URL", "https://panel.yourdomain.com")
	API_KEY         = getEnv("API_KEY", "your_api_key_here")
	REFRESH_SECONDS = 3
)

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

// ── COLORS ────────────────────────────────────────────────────
const (
	cReset  = "\033[0m"
	cRed    = "\033[31m"
	cGreen  = "\033[32m"
	cYellow = "\033[33m"
	cCyan   = "\033[36m"
	cWhite  = "\033[1;37m"
	cDim    = "\033[2m"
	cBold   = "\033[1m"
	clrScr  = "\033[H\033[2J"
)

// ── STRUCTS ───────────────────────────────────────────────────
type Server struct {
	Attributes struct {
		Identifier  string `json:"identifier"`
		Name        string `json:"name"`
		Node        string `json:"node"`
		Description string `json:"description"`
		Limits      struct {
			Memory int `json:"memory"`
			Cpu    int `json:"cpu"`
			Disk   int `json:"disk"`
		} `json:"limits"`
	} `json:"attributes"`
}

type ServersResponse struct {
	Data []Server `json:"data"`
}

type Resources struct {
	CurrentState string `json:"current_state"`
	Resources    struct {
		MemoryBytes    int64   `json:"memory_bytes"`
		CpuAbsolute    float64 `json:"cpu_absolute"`
		DiskBytes      int64   `json:"disk_bytes"`
		NetworkRxBytes int64   `json:"network_rx_bytes"`
		NetworkTxBytes int64   `json:"network_tx_bytes"`
	} `json:"resources"`
}

type ResourcesResponse struct {
	Attributes Resources `json:"attributes"`
}

type ServerStats struct {
	Server    Server
	Resources Resources
	Error     bool
}

// ── API ───────────────────────────────────────────────────────
func apiRequest(endpoint string, client bool) ([]byte, error) {
	base := "application"
	if client {
		base = "client"
	}
	url := fmt.Sprintf("%s/api/%s/%s", PANEL_URL, base, endpoint)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+API_KEY)
	req.Header.Set("Accept", "application/json")

	client2 := &http.Client{Timeout: 8 * time.Second}
	resp, err := client2.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	return io.ReadAll(resp.Body)
}

func getServers() ([]Server, error) {
	body, err := apiRequest("servers?per_page=100", false)
	if err != nil {
		return nil, err
	}
	var result ServersResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	return result.Data, nil
}

func getResources(identifier string) (*Resources, error) {
	body, err := apiRequest(fmt.Sprintf("servers/%s/resources", identifier), true)
	if err != nil {
		return nil, err
	}
	var result ResourcesResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	return &result.Attributes, nil
}

// ── FORMATTING ────────────────────────────────────────────────
func bytesToHuman(b int64) string {
	switch {
	case b >= 1073741824:
		return fmt.Sprintf("%.1fGB", float64(b)/1073741824)
	case b >= 1048576:
		return fmt.Sprintf("%.1fMB", float64(b)/1048576)
	case b >= 1024:
		return fmt.Sprintf("%.1fKB", float64(b)/1024)
	default:
		return fmt.Sprintf("%dB", b)
	}
}

func progressBar(pct float64, width int) string {
	if pct > 100 {
		pct = 100
	}
	filled := int(float64(width) * pct / 100)
	empty := width - filled

	var color string
	switch {
	case pct >= 85:
		color = cRed
	case pct >= 60:
		color = cYellow
	default:
		color = cGreen
	}

	bar := color + strings.Repeat("█", filled) + cDim + strings.Repeat("░", empty) + cReset
	return bar
}

func statusColor(state string) string {
	switch state {
	case "running":
		return cGreen + "● ONLINE " + cReset
	case "starting":
		return cYellow + "◎ START  " + cReset
	case "stopping":
		return cYellow + "◎ STOP   " + cReset
	default:
		return cRed + "○ OFFLINE" + cReset
	}
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s + strings.Repeat(" ", n-len(s))
	}
	return s[:n-3] + "..."
}

// ── FETCH ALL STATS ───────────────────────────────────────────
func fetchAllStats(servers []Server) []ServerStats {
	results := make([]ServerStats, len(servers))
	done := make(chan struct{}, len(servers))

	for i, srv := range servers {
		go func(idx int, s Server) {
			res, err := getResources(s.Attributes.Identifier)
			if err != nil || res == nil {
				results[idx] = ServerStats{Server: s, Error: true}
			} else {
				results[idx] = ServerStats{Server: s, Resources: *res}
			}
			done <- struct{}{}
		}(i, srv)
	}

	for range servers {
		<-done
	}
	return results
}

// ── RENDER DASHBOARD ──────────────────────────────────────────
func render(stats []ServerStats, lastUpdate time.Time, fetchMs int64) {
	fmt.Print(clrScr)

	// Header
	fmt.Printf("%s", cCyan)
	fmt.Println("╔══════════════════════════════════════════════════════════════════════════════╗")
	fmt.Printf("║  %sPTERODACTYL NODE MONITOR%s%s                                                   ║\n", cWhite+cBold, cReset, cCyan)
	fmt.Printf("║  %s%-44s%s  Refresh: %ds  Fetch: %dms%s  ║\n",
		cDim,
		fmt.Sprintf("Updated: %s", lastUpdate.Format("2006-01-02 15:04:05")),
		cReset+cCyan,
		REFRESH_SECONDS,
		fetchMs,
		cReset+cCyan,
	)
	fmt.Println("╚══════════════════════════════════════════════════════════════════════════════╝")
	fmt.Print(cReset)
	fmt.Println()

	// Column headers
	fmt.Printf("%s%-24s %-11s %-22s %-22s %-12s%s\n",
		cDim,
		"SERVER", "STATUS", "RAM", "CPU", "DISK",
		cReset,
	)
	fmt.Printf("%s%s%s\n", cDim, strings.Repeat("─", 96), cReset)

	// Stats
	total := len(stats)
	online := 0

	for _, s := range stats {
		attr := s.Server.Attributes
		name := truncate(attr.Name, 22)

		if s.Error {
			fmt.Printf("%-24s %s  %serror fetching data%s\n",
				name,
				cRed+"○ ERROR  "+cReset,
				cDim, cReset,
			)
			continue
		}

		res := s.Resources
		if res.CurrentState == "running" {
			online++
		}

		status := statusColor(res.CurrentState)

		if res.CurrentState == "running" {
			// RAM
			ramLimit := int64(attr.Limits.Memory) * 1048576
			ramPct := 0.0
			ramLimitStr := "unlimited"
			if ramLimit > 0 {
				ramPct = float64(res.Resources.MemoryBytes) / float64(ramLimit) * 100
				ramLimitStr = bytesToHuman(ramLimit)
			}
			ramBar := progressBar(ramPct, 8)
			ramStr := fmt.Sprintf("%s %s/%s",
				ramBar,
				bytesToHuman(res.Resources.MemoryBytes),
				ramLimitStr,
			)

			// CPU
			cpuLimit := float64(attr.Limits.Cpu)
			cpuPct := res.Resources.CpuAbsolute
			if cpuLimit > 0 {
				cpuPct = res.Resources.CpuAbsolute / cpuLimit * 100
			}
			cpuBar := progressBar(cpuPct, 8)
			cpuStr := fmt.Sprintf("%s %.1f%%", cpuBar, res.Resources.CpuAbsolute)

			// Disk
			diskStr := bytesToHuman(res.Resources.DiskBytes)

			fmt.Printf("%-24s %s  %-38s %-38s %-12s\n",
				name, status, ramStr, cpuStr, diskStr,
			)
		} else {
			fmt.Printf("%-24s %s  %s%-22s %-22s %-12s%s\n",
				name, status,
				cDim, "─", "─", "─", cReset,
			)
		}
	}

	// Footer
	fmt.Printf("%s%s%s\n", cDim, strings.Repeat("─", 96), cReset)
	fmt.Println()

	// Summary
	offline := total - online
	fmt.Printf("  %sServers:%s %s%d total%s  ",
		cDim, cReset, cWhite, total, cReset)
	fmt.Printf("%s%d online%s  ",
		cGreen, online, cReset)
	fmt.Printf("%s%d offline%s\n",
		cRed, offline, cReset)
	fmt.Println()
	fmt.Printf("  %sCtrl+C to exit%s\n", cDim, cReset)
}

// ── MAIN ──────────────────────────────────────────────────────
func main() {
	// Handle Ctrl+C
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

	// Load config from file if exists
	loadConfig()

	fmt.Print(clrScr)
	fmt.Printf("%s  Pterodactyl Node Monitor — Connecting to %s...%s\n\n",
		cCyan, PANEL_URL, cReset)

	// Fetch server list once
	servers, err := getServers()
	if err != nil || len(servers) == 0 {
		fmt.Printf("%s[ERR] Failed to fetch servers. Check PANEL_URL and API_KEY in config.env%s\n", cRed, cReset)
		os.Exit(1)
	}

	fmt.Printf("%s  Found %d servers. Starting dashboard...%s\n", cGreen, len(servers), cReset)
	time.Sleep(1 * time.Second)

	ticker := time.NewTicker(time.Duration(REFRESH_SECONDS) * time.Second)
	defer ticker.Stop()

	// First render immediately
	start := time.Now()
	stats := fetchAllStats(servers)
	fetchMs := time.Since(start).Milliseconds()
	render(stats, time.Now(), fetchMs)

	for {
		select {
		case <-sig:
			fmt.Print(clrScr)
			fmt.Printf("%s  Node Monitor stopped.%s\n\n", cCyan, cReset)
			os.Exit(0)
		case <-ticker.C:
			// Refresh server list every 60 ticks
			start = time.Now()
			stats = fetchAllStats(servers)
			fetchMs = time.Since(start).Milliseconds()
			render(stats, time.Now(), fetchMs)
		}
	}
}

// ── LOAD CONFIG FROM FILE ─────────────────────────────────────
func loadConfig() {
	data, err := os.ReadFile("config.env")
	if err != nil {
		return
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		key := strings.TrimSpace(parts[0])
		val := strings.TrimSpace(parts[1])
		switch key {
		case "PANEL_URL":
			PANEL_URL = val
		case "API_KEY":
			API_KEY = val
		}
	}
}
