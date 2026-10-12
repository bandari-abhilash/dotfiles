#!/usr/bin/env bash

# Synthetic incident output for demo recordings, so no real logs end up on screen.
# Usage: fake-logs.sh          # service logs: healthy, errors climb, rollback, recovery
#        fake-logs.sh metrics  # a small metrics table that follows the same story

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

# Phase by elapsed seconds: 0–7 healthy, 7–24 degraded, 24+ recovered after rollback
phase() {
    local t=$(( $(date +%s) - START ))
    if [ "$t" -lt 7 ]; then echo healthy
    elif [ "$t" -lt 24 ]; then echo degraded
    else echo recovered
    fi
}

logs() {
    local paths=("/api/checkout" "/api/cart" "/api/orders" "/api/payments" "/healthz")
    local rolled_back=false
    while true; do
        local p ts path ms
        p=$(phase)
        ts=$(date '+%H:%M:%S')
        path=${paths[$((RANDOM % ${#paths[@]}))]}
        case "$p" in
            healthy)
                ms=$((20 + RANDOM % 40))
                echo -e "${DIM}$ts${NC} ${GREEN}INFO${NC}  checkout-api  200 GET $path  ${ms}ms"
                ;;
            degraded)
                if [ $((RANDOM % 3)) -eq 0 ]; then
                    ms=$((900 + RANDOM % 2000))
                    echo -e "${DIM}$ts${NC} ${RED}ERROR${NC} checkout-api  503 POST $path  ${ms}ms  upstream timeout: payments-db pool exhausted (50/50)"
                else
                    ms=$((300 + RANDOM % 600))
                    echo -e "${DIM}$ts${NC} ${YELLOW}WARN${NC}  checkout-api  200 GET $path  ${ms}ms  slow query"
                fi
                ;;
            recovered)
                if [ "$rolled_back" = false ]; then
                    echo -e "${DIM}$ts${NC} ${YELLOW}DEPLOY${NC} checkout-api  rollback v2.14.1 → v2.14.0 complete"
                    rolled_back=true
                fi
                ms=$((20 + RANDOM % 40))
                echo -e "${DIM}$ts${NC} ${GREEN}INFO${NC}  checkout-api  200 GET $path  ${ms}ms"
                ;;
        esac
        sleep 0.$((2 + RANDOM % 5))
    done
}

metrics() {
    while true; do
        local p rps err p99
        p=$(phase)
        case "$p" in
            healthy)   rps=$((1180 + RANDOM % 60)); err="0.1%";  p99="48ms"  ;;
            degraded)  rps=$((610 + RANDOM % 90));  err="$((18 + RANDOM % 9))%"; p99="$((2 + RANDOM % 2)).$((RANDOM % 10))s" ;;
            recovered) rps=$((1150 + RANDOM % 60)); err="0.2%";  p99="52ms"  ;;
        esac
        clear
        echo -e "checkout-api  ·  last 10s  ·  $(date '+%H:%M:%S')\n"
        printf "  %-12s %s\n" "requests/s" "$rps"
        if [ "$p" = degraded ]; then
            echo -e "  error rate   ${RED}$err${NC}"
            echo -e "  p99 latency  ${RED}$p99${NC}"
            echo -e "\n  ${RED}● ALERT${NC} CheckoutErrorRate > 5% for 1m"
        else
            echo -e "  error rate   ${GREEN}$err${NC}"
            echo -e "  p99 latency  ${GREEN}$p99${NC}"
            echo -e "\n  ${GREEN}● OK${NC}"
        fi
        sleep 1
    done
}

START=$(date +%s)
case "${1:-logs}" in
    metrics) metrics ;;
    *) logs ;;
esac
