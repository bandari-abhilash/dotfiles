#!/usr/bin/env bash

# Synthetic incident output for demo recordings, so no real logs end up on screen.
# Usage: fake-logs.sh          # service logs: healthy, errors climb, rollback, recovery
#        fake-logs.sh metrics  # a small metrics table that follows the same story
#        fake-logs.sh deploys  # deploy history: the bad release, then the rollback
#
# Healthy for the first few seconds, then degraded. Recovery comes when the file named by
# DEMO_RECOVER_FLAG exists (record-demo.sh creates it), or after 24s without one.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

phase() {
    local t=$(( $(date +%s) - START ))
    if [ "$t" -lt 3 ]; then echo healthy
    elif [ -n "${DEMO_RECOVER_FLAG:-}" ]; then
        if [ -e "$DEMO_RECOVER_FLAG" ]; then echo recovered; else echo degraded; fi
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

deploys() {
    local deployed_at rollback_at=""
    deployed_at=$(date -v-6M '+%H:%M')
    while true; do
        local p
        p=$(phase)
        if [ "$p" = recovered ] && [ -z "$rollback_at" ]; then
            rollback_at=$(date '+%H:%M')
        fi
        clear
        echo -e "checkout-api  ·  deploy history\n"
        printf "  %-4s %-9s %-7s %s\n" "REV" "VERSION" "TIME" "STATUS"
        printf "  %-4s %-9s %-7s %s\n" "41" "v2.14.0" "09:12" "superseded"
        if [ -z "$rollback_at" ]; then
            if [ "$p" = degraded ]; then
                echo -e "  42   v2.14.1   $deployed_at   ${RED}active  ← errors started here${NC}"
            else
                echo -e "  42   v2.14.1   $deployed_at   ${GREEN}active${NC}"
            fi
        else
            printf "  %-4s %-9s %-7s %s\n" "42" "v2.14.1" "$deployed_at" "rolled back"
            echo -e "  43   v2.14.0   $rollback_at   ${GREEN}active  (rollback)${NC}"
        fi
        sleep 1
    done
}

START=$(date +%s)
case "${1:-logs}" in
    metrics) metrics ;;
    deploys) deploys ;;
    *) logs ;;
esac
