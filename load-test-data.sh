#!/bin/bash

# Load Test Data Script for Library Management System
# This script loads sample data into MongoDB for testing

set -e

echo "📚 Loading Test Data into Library Management System"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if backend is running
print_status "Checking if backend is running..."
if ! curl -s http://localhost:8080/users > /dev/null; then
    print_error "Backend is not running on localhost:8080"
    print_status "Please start the backend first:"
    echo "  cd BDA/backend && sbt run"
    exit 1
fi

print_success "Backend is running!"

# Base URL
BASE_URL="http://localhost:8080"

# Function to make API calls
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    print_status "$description"
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" "$BASE_URL$endpoint")
    fi
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        print_success "✓ $description"
    else
        print_warning "⚠ $description (HTTP $http_code)"
    fi
}

# Load Users
print_status "Loading users..."
make_request "POST" "/users/signup" \
    '{"id":"1","username":"admin","email":"admin@library.com","password":"admin123","role":"admin"}' \
    "Create admin user"

make_request "POST" "/users/signup" \
    '{"id":"2","username":"librarian1","email":"librarian1@library.com","password":"lib123","role":"doctor"}' \
    "Create librarian1 user"

make_request "POST" "/users/signup" \
    '{"id":"3","username":"librarian2","email":"librarian2@library.com","password":"lib123","role":"doctor"}' \
    "Create librarian2 user"

# Load Members
print_status "Loading library members..."
make_request "POST" "/members" \
    '{"id":"MEM001","name":"John Smith","email":"john.smith@email.com","phone":"+1-555-0101","address":"123 Main St, City, State 12345"}' \
    "Create member John Smith"

make_request "POST" "/members" \
    '{"id":"MEM002","name":"Alice Johnson","email":"alice.johnson@email.com","phone":"+1-555-0102","address":"456 Oak Ave, City, State 12345"}' \
    "Create member Alice Johnson"

make_request "POST" "/members" \
    '{"id":"MEM003","name":"Bob Wilson","email":"bob.wilson@email.com","phone":"+1-555-0103","address":"789 Pine St, City, State 12345"}' \
    "Create member Bob Wilson"

# Load Librarians
print_status "Loading librarians..."
make_request "POST" "/librarians" \
    '{"id":"LIB001","name":"Sarah Johnson","specialty":"Reference & Research"}' \
    "Create librarian Sarah Johnson"

make_request "POST" "/librarians" \
    '{"id":"LIB002","name":"Michael Chen","specialty":"Children'\''s Literature"}' \
    "Create librarian Michael Chen"

make_request "POST" "/librarians" \
    '{"id":"LIB003","name":"Emily Rodriguez","specialty":"Digital Resources"}' \
    "Create librarian Emily Rodriguez"

# Load Books
print_status "Loading book inventory..."
make_request "POST" "/inventory" \
    '{"id":"BOOK001","title":"The Great Gatsby","author":"F. Scott Fitzgerald","isbn":"978-0-7432-7356-5","quantity":5,"available":3}' \
    "Add The Great Gatsby"

make_request "POST" "/inventory" \
    '{"id":"BOOK002","title":"To Kill a Mockingbird","author":"Harper Lee","isbn":"978-0-06-112008-4","quantity":4,"available":2}' \
    "Add To Kill a Mockingbird"

make_request "POST" "/inventory" \
    '{"id":"BOOK003","title":"1984","author":"George Orwell","isbn":"978-0-452-28423-4","quantity":6,"available":4}' \
    "Add 1984"

make_request "POST" "/inventory" \
    '{"id":"BOOK004","title":"Pride and Prejudice","author":"Jane Austen","isbn":"978-0-14-143951-8","quantity":3,"available":1}' \
    "Add Pride and Prejudice"

make_request "POST" "/inventory" \
    '{"id":"BOOK005","title":"The Catcher in the Rye","author":"J.D. Salinger","isbn":"978-0-316-76948-0","quantity":4,"available":4}' \
    "Add The Catcher in the Rye"

make_request "POST" "/inventory" \
    '{"id":"BOOK006","title":"Lord of the Flies","author":"William Golding","isbn":"978-0-571-05686-2","quantity":5,"available":3}' \
    "Add Lord of the Flies"

make_request "POST" "/inventory" \
    '{"id":"BOOK007","title":"The Hobbit","author":"J.R.R. Tolkien","isbn":"978-0-547-92822-7","quantity":6,"available":5}' \
    "Add The Hobbit"

make_request "POST" "/inventory" \
    '{"id":"BOOK008","title":"Harry Potter and the Philosopher'\''s Stone","author":"J.K. Rowling","isbn":"978-0-7475-3269-9","quantity":8,"available":6}' \
    "Add Harry Potter and the Philosopher's Stone"

# Load Staff
print_status "Loading staff members..."
make_request "POST" "/staff" \
    '{"id":"STAFF001","name":"David Park","role":"Library Assistant","department":"Circulation"}' \
    "Create staff David Park"

make_request "POST" "/staff" \
    '{"id":"STAFF002","name":"Lisa Wong","role":"Cataloger","department":"Technical Services"}' \
    "Create staff Lisa Wong"

make_request "POST" "/staff" \
    '{"id":"STAFF003","name":"Mark Thompson","role":"Security","department":"Administration"}' \
    "Create staff Mark Thompson"

# Load Book Requests
print_status "Loading book requests..."
make_request "POST" "/book-requests" \
    '{"id":"REQ001","memberId":"MEM001","librarianId":"LIB001","bookId":"BOOK001","date":"2024-01-15","time":"10:00","status":"borrowed"}' \
    "Create book request REQ001 (borrowed)"

make_request "POST" "/book-requests" \
    '{"id":"REQ002","memberId":"MEM002","librarianId":"LIB002","bookId":"BOOK002","date":"2024-01-16","time":"14:30","status":"borrowed"}' \
    "Create book request REQ002 (borrowed)"

make_request "POST" "/book-requests" \
    '{"id":"REQ003","memberId":"MEM003","librarianId":"LIB001","bookId":"BOOK004","date":"2024-01-17","time":"09:15","status":"borrowed"}' \
    "Create book request REQ003 (borrowed)"

make_request "POST" "/book-requests" \
    '{"id":"REQ004","memberId":"MEM001","librarianId":"LIB003","bookId":"BOOK003","date":"2024-01-18","time":"11:30","status":"pending"}' \
    "Create book request REQ004 (pending)"

print_success "🎉 Test data loading completed!"
echo ""
echo "📊 Summary of loaded data:"
echo "  👥 Users: 3 (1 admin, 2 librarians)"
echo "  📚 Books: 8 titles with varying availability"
echo "  👨‍👩‍👧‍👦 Members: 3 library members"
echo "  👨‍🏫 Librarians: 3 library staff"
echo "  👷 Staff: 3 general staff members"
echo "  📋 Book Requests: 4 (3 borrowed, 1 pending)"
echo ""
echo "🔑 Test Login Credentials:"
echo "  Admin: username=admin, password=admin123, role=admin"
echo "  Librarian: username=librarian1, password=lib123, role=doctor"
echo ""
echo "🚀 You can now test the librarian dashboard:"
echo "  1. Go to http://localhost:3000/login.html"
echo "  2. Login as librarian1 with role 'Librarian'"
echo "  3. You'll be redirected to the librarian dashboard"
echo "  4. View book inventory and borrowed books with member details" 