#!/bin/bash

# Library Management System API Test Script
# Run this script to test if the backend API is working correctly

echo "🧪 Testing Library Management System API..."
echo "=============================================="

BASE_URL="http://localhost:8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test API endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "\n${YELLOW}Testing: $description${NC}"
    echo "Request: $method $endpoint"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method \
            "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS:.*//')
    
    if [ $http_code -ge 200 ] && [ $http_code -lt 300 ]; then
        echo -e "${GREEN}✓ Success (HTTP $http_code)${NC}"
        echo "Response: $body"
    else
        echo -e "${RED}✗ Failed (HTTP $http_code)${NC}"
        echo "Response: $body"
    fi
}

# Check if server is running
echo "🔍 Checking if backend server is running..."
if curl -s "$BASE_URL" > /dev/null; then
    echo -e "${GREEN}✓ Backend server is running on $BASE_URL${NC}"
else
    echo -e "${RED}✗ Backend server is not running on $BASE_URL${NC}"
    echo "Please start the backend server with: cd backend && sbt run"
    exit 1
fi

# Test User Authentication Endpoints
echo -e "\n📝 Testing User Authentication..."
test_endpoint "POST" "/users/signup" \
    '{"id":"test1","username":"testuser","email":"test@example.com","password":"test123","role":"admin"}' \
    "Create test user"

test_endpoint "GET" "/users" "" "Get all users"

# Test Member Management
echo -e "\n👥 Testing Member Management..."
test_endpoint "POST" "/members" \
    '{"id":"MEM001","name":"John Doe","email":"john@example.com","phone":"555-0101","address":"123 Main St"}' \
    "Create member"

test_endpoint "GET" "/members" "" "Get all members"

test_endpoint "GET" "/members/MEM001" "" "Get specific member"

# Test Librarian Management
echo -e "\n👨‍🏫 Testing Librarian Management..."
test_endpoint "POST" "/librarians" \
    '{"id":"LIB001","name":"Jane Smith","specialty":"Reference"}' \
    "Create librarian"

test_endpoint "GET" "/librarians" "" "Get all librarians"

# Test Book Inventory
echo -e "\n📚 Testing Book Inventory..."
test_endpoint "POST" "/inventory" \
    '{"id":"BOOK001","title":"Test Book","author":"Test Author","isbn":"123-456-789","quantity":5,"available":5}' \
    "Add book to inventory"

test_endpoint "GET" "/inventory" "" "Get all books"

# Test Staff Management
echo -e "\n👷 Testing Staff Management..."
test_endpoint "POST" "/staff" \
    '{"id":"STAFF001","name":"Bob Wilson","role":"Assistant","department":"Circulation"}' \
    "Create staff member"

test_endpoint "GET" "/staff" "" "Get all staff"

# Test Book Requests
echo -e "\n📋 Testing Book Requests..."
test_endpoint "POST" "/book-requests" \
    '{"id":"REQ001","memberId":"MEM001","librarianId":"LIB001","date":"2024-01-15","time":"10:00"}' \
    "Create book request"

test_endpoint "GET" "/book-requests" "" "Get all book requests"

# Test Legacy Endpoints
echo -e "\n🔄 Testing Legacy Compatibility..."
test_endpoint "GET" "/doctors" "" "Get legacy doctors (should map to librarians)"
test_endpoint "GET" "/appointments" "" "Get legacy appointments (should map to book requests)"
test_endpoint "GET" "/pharmacy" "" "Get legacy pharmacy (should map to inventory)"

echo -e "\n🎉 API Testing Complete!"
echo "=============================================="
echo "If you see mostly green checkmarks above, your API is working correctly!"
echo "If you see red X marks, check the backend logs for errors."
echo ""
echo "To clean up test data, connect to MongoDB and run:"
echo "mongo library_db --eval \"db.dropDatabase()\"" 