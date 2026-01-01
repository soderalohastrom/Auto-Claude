#!/bin/bash
# test_graphiti_setup.sh
# Quick verification script for Graphiti memory setup

set -e

echo "======================================================================"
echo "  GRAPHITI SETUP VERIFICATION"
echo "======================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print status
print_status() {
    if [ "$1" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $2"
    elif [ "$1" = "fail" ]; then
        echo -e "${RED}✗${NC} $2"
        ERRORS=$((ERRORS + 1))
    elif [ "$1" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $2"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "  $2"
    fi
}

echo "1. Checking Docker containers..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_status "fail" "Docker is not running"
    echo ""
    echo "Please start Docker Desktop and try again."
    exit 1
fi
print_status "pass" "Docker is running"

# Check FalkorDB container
if docker ps | grep -q "auto-claude-falkordb"; then
    FALKOR_STATUS=$(docker inspect auto-claude-falkordb --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$FALKOR_STATUS" = "healthy" ]; then
        print_status "pass" "FalkorDB container is running and healthy"
    else
        print_status "warn" "FalkorDB container is running but status: $FALKOR_STATUS"
    fi
else
    print_status "fail" "FalkorDB container is not running"
    echo ""
    echo "Start it with: docker-compose up -d falkordb"
fi

# Check Graphiti MCP container
if docker ps | grep -q "auto-claude-graphiti-mcp"; then
    MCP_STATUS=$(docker inspect auto-claude-graphiti-mcp --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$MCP_STATUS" = "healthy" ]; then
        print_status "pass" "Graphiti MCP container is running and healthy"
    else
        print_status "warn" "Graphiti MCP container is running but status: $MCP_STATUS"
    fi
else
    print_status "fail" "Graphiti MCP container is not running"
    echo ""
    echo "Start it with: docker-compose up -d graphiti-mcp"
fi

echo ""
echo "2. Checking port accessibility..."
echo ""

# Check FalkorDB port
if nc -z localhost 6380 2>/dev/null || timeout 1 bash -c 'cat < /dev/null > /dev/tcp/localhost/6380' 2>/dev/null; then
    print_status "pass" "FalkorDB port 6380 is accessible"
else
    print_status "fail" "FalkorDB port 6380 is not accessible"
fi

# Check MCP port
if nc -z localhost 9000 2>/dev/null || timeout 1 bash -c 'cat < /dev/null > /dev/tcp/localhost/9000' 2>/dev/null; then
    print_status "pass" "Graphiti MCP port 9000 is accessible"
else
    print_status "fail" "Graphiti MCP port 9000 is not accessible"
fi

echo ""
echo "3. Testing endpoints..."
echo ""

# Test FalkorDB with redis-cli
if command -v redis-cli > /dev/null; then
    if redis-cli -h localhost -p 6380 ping 2>/dev/null | grep -q "PONG"; then
        print_status "pass" "FalkorDB responds to PING"
    else
        print_status "fail" "FalkorDB did not respond to PING"
    fi
else
    print_status "warn" "redis-cli not installed, skipping FalkorDB PING test"
fi

# Test Graphiti MCP SSE endpoint
if command -v curl > /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:9000/sse)
    if [ "$HTTP_CODE" = "200" ]; then
        print_status "pass" "Graphiti MCP /sse endpoint returns 200 OK"
    else
        print_status "fail" "Graphiti MCP /sse endpoint returned: $HTTP_CODE"
    fi
else
    print_status "warn" "curl not installed, skipping HTTP test"
fi

echo ""
echo "4. Checking environment variables..."
echo ""

# Check for .env file
if [ -f "auto-claude/.env" ]; then
    print_status "pass" "auto-claude/.env file exists"

    # Check GRAPHITI_ENABLED
    if grep -q "^GRAPHITI_ENABLED=true" auto-claude/.env 2>/dev/null; then
        print_status "pass" "GRAPHITI_ENABLED=true is set"
    else
        print_status "warn" "GRAPHITI_ENABLED is not set to true"
        echo "     Add to auto-claude/.env: GRAPHITI_ENABLED=true"
    fi

    # Check OPENAI_API_KEY
    if grep -q "^OPENAI_API_KEY=" auto-claude/.env 2>/dev/null && ! grep -q "^OPENAI_API_KEY=$" auto-claude/.env 2>/dev/null; then
        print_status "pass" "OPENAI_API_KEY is set"
    else
        print_status "warn" "OPENAI_API_KEY is not set"
        echo "     Add to auto-claude/.env: OPENAI_API_KEY=sk-..."
    fi

    # Check GRAPHITI_MCP_URL
    if grep -q "^GRAPHITI_MCP_URL=" auto-claude/.env 2>/dev/null; then
        MCP_URL=$(grep "^GRAPHITI_MCP_URL=" auto-claude/.env | cut -d'=' -f2)
        if echo "$MCP_URL" | grep -q "/sse"; then
            print_status "pass" "GRAPHITI_MCP_URL uses /sse endpoint"
        else
            print_status "warn" "GRAPHITI_MCP_URL might be incorrect: $MCP_URL"
            echo "     Should be: http://localhost:9000/sse"
        fi
    else
        print_status "info" "GRAPHITI_MCP_URL not set (will use default)"
    fi
else
    print_status "warn" "auto-claude/.env file not found"
    echo "     Create it with: cp auto-claude/.env.example auto-claude/.env"
fi

echo ""
echo "5. Checking Python dependencies..."
echo ""

# Check if venv exists
if [ -d "auto-claude/.venv" ]; then
    print_status "pass" "Python virtual environment exists"

    # Check if Graphiti packages are installed
    if auto-claude/.venv/bin/pip list 2>/dev/null | grep -q "graphiti-core"; then
        print_status "pass" "graphiti-core is installed"
    else
        print_status "warn" "graphiti-core is not installed"
        echo "     Install with: cd auto-claude && .venv/bin/pip install graphiti-core[falkordb]"
    fi

    if auto-claude/.venv/bin/pip list 2>/dev/null | grep -q "falkordb"; then
        print_status "pass" "falkordb Python client is installed"
    else
        print_status "warn" "falkordb Python client is not installed"
        echo "     Install with: cd auto-claude && .venv/bin/pip install falkordb"
    fi
else
    print_status "warn" "Python virtual environment not found at auto-claude/.venv"
    echo "     Create it with: cd auto-claude && python -m venv .venv"
fi

echo ""
echo "======================================================================"
echo "  SUMMARY"
echo "======================================================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC} Graphiti is properly configured."
    echo ""
    echo "Next steps:"
    echo "  1. Test connectivity: python fake_memory.py --test"
    echo "  2. Inject test memory: python fake_memory.py --spec-dir .auto-claude/specs/001-test --content 'Test memory'"
    echo "  3. Verify in UI: Open Context > Memories tab"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Setup is mostly correct with $WARNINGS warning(s)${NC}"
    echo ""
    echo "You can proceed with testing, but review the warnings above."
    echo "  - Test connectivity: python fake_memory.py --test"
else
    echo -e "${RED}Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    echo ""
    echo "Quick fixes:"
    echo "  - Start Docker containers: docker-compose up -d"
    echo "  - Set environment variables in auto-claude/.env"
    echo "  - Install Python dependencies: cd auto-claude && .venv/bin/pip install graphiti-core[falkordb] falkordb"
fi

echo ""
echo "For detailed setup instructions, see: GRAPHITI_TESTING.md"
echo ""

exit $ERRORS
