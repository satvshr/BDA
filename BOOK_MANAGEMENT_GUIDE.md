# 📚 Book Management Guide - Library Management System

## Overview
This guide explains how to add, manage, and track books in the Library Management System. The system supports full CRUD operations for book inventory with authors stored as simple strings (no separate author collection needed).

## 🚀 Getting Started

### Prerequisites
1. **Backend Running**: Ensure the Scala backend is running on `localhost:8080`
2. **Frontend Running**: Ensure the frontend is served on `localhost:3000`
3. **MongoDB Running**: Ensure MongoDB is running on `localhost:27017`

### Quick Setup
```bash
# 1. Start MongoDB (if not already running)
sudo systemctl start mongod

# 2. Start Backend
cd BDA/backend
sbt run

# 3. Start Frontend (in another terminal)
cd BDA/frontend
python3 -m http.server 3000

# 4. Load test data (optional)
cd BDA
chmod +x load-test-data.sh
./load-test-data.sh
```

## 📖 Book Management Features

### 1. **Add New Books**
- Navigate to `http://localhost:3000/inventory.html`
- Fill in the book information form:
  - **Book ID**: Unique identifier (e.g., BOOK009)
  - **Book Title**: Full title of the book
  - **Author Name**: Author's full name (stored as string)
  - **ISBN**: International Standard Book Number
  - **Total Quantity**: Total copies available
  - **Available Copies**: Currently available copies
- Click **"Add New Book"** button

### 2. **Search Books**
- **Multiple search options available:**
  - **By Book ID**: Enter Book ID (fastest method)
  - **By Title**: Enter full or partial book title
  - **By Author**: Enter full or partial author name
  - **By ISBN**: Enter full or partial ISBN
  - **Combined search**: Fill multiple fields for precise matching
- Click **"Search Book"** button
- Book details will populate the form if found
- **Multiple matches**: Shows list of matching books with IDs

### 3. **Update Books**
- Search for the book first (or click on a book in the table)
- Modify the desired fields
- Click **"Update Book"** button

### 4. **Delete Books**
- Enter the **Book ID** of the book to delete
- Click **"Delete Book"** button
- Confirm the deletion in the popup dialog

### 5. **View All Books**
- The inventory table automatically loads all books
- Click **"Refresh List"** to reload the data
- Click on any book row to select it for editing

## 🎯 Author Management

### Simple String-Based Authors
- **No separate author collection** - authors are stored as strings directly in book records
- **Easy to use** - just type the author's name when adding books
- **Flexible** - supports multiple authors (e.g., "J.R.R. Tolkien and Christopher Tolkien")
- **No complex relationships** - perfect for simple library management

### Adding Books with Authors
```json
{
  "id": "BOOK009",
  "title": "The Lord of the Rings",
  "author": "J.R.R. Tolkien",
  "isbn": "978-0-544-00341-5",
  "quantity": 3,
  "available": 3
}
```

## 📊 Book Status Indicators

The system automatically shows book availability status:

- 🟢 **Available**: More than 2 copies available
- 🟡 **Low Stock**: 1-2 copies available  
- 🔴 **Out of Stock**: 0 copies available

## 🔧 API Endpoints

### Book Inventory Management
- `GET /inventory` - Get all books
- `GET /inventory/{id}` - Get specific book
- `POST /inventory` - Add new book
- `PUT /inventory/{id}` - Update book
- `DELETE /inventory/{id}` - Delete book

### Example API Usage
```bash
# Add a new book
curl -X POST http://localhost:8080/inventory \
  -H "Content-Type: application/json" \
  -d '{
    "id": "BOOK009",
    "title": "Dune",
    "author": "Frank Herbert",
    "isbn": "978-0-441-17271-9",
    "quantity": 4,
    "available": 4
  }'

# Get all books
curl http://localhost:8080/inventory

# Update a book
curl -X PUT http://localhost:8080/inventory/BOOK009 \
  -H "Content-Type: application/json" \
  -d '{
    "id": "BOOK009",
    "title": "Dune",
    "author": "Frank Herbert",
    "isbn": "978-0-441-17271-9",
    "quantity": 5,
    "available": 4
  }'
```

## 📋 Sample Books Included

The test data includes these books:

1. **The Great Gatsby** by F. Scott Fitzgerald
2. **To Kill a Mockingbird** by Harper Lee
3. **1984** by George Orwell
4. **Pride and Prejudice** by Jane Austen
5. **The Catcher in the Rye** by J.D. Salinger
6. **Lord of the Flies** by William Golding
7. **The Hobbit** by J.R.R. Tolkien
8. **Harry Potter and the Philosopher's Stone** by J.K. Rowling

## 🎨 User Interface Features

### Modern Dark Theme
- Professional dark mode interface
- Responsive design for all screen sizes
- Interactive book table with hover effects
- Real-time status updates

### Smart Form Features
- **Auto-sync**: Available copies automatically sync with total quantity
- **Validation**: Prevents invalid data entry
- **Click-to-select**: Click any book in the table to edit it
- **Clear form**: Reset all fields with one click

### Real-time Feedback
- Success/error messages for all operations
- Loading indicators during API calls
- Color-coded status badges
- Confirmation dialogs for destructive actions

## 🔐 Access Control

### User Roles
- **Admin**: Full access to all features
- **Librarian**: Can manage books and view borrowed books
- **Member**: Can view available books (future feature)

### Login Credentials (Test Data)
- **Admin**: username=`admin`, password=`admin123`
- **Librarian**: username=`librarian1`, password=`lib123`

## 🚨 Troubleshooting

### Common Issues

1. **"Failed to load books"**
   - Check if backend is running on port 8080
   - Verify MongoDB is running and accessible

2. **"Book ID already exists"**
   - Use a unique Book ID for new books
   - Check existing books in the inventory table

3. **"Available copies cannot exceed total quantity"**
   - Ensure available copies ≤ total quantity
   - Update total quantity first if needed

4. **Form not submitting**
   - Fill in all required fields (ID, Title, Author)
   - Check browser console for JavaScript errors

### Backend Logs
```bash
# Check backend logs for API errors
cd BDA/backend
sbt run
# Look for error messages in the console
```

### Database Verification
```bash
# Connect to MongoDB to verify data
mongosh
use library_db
db.inventory.find().pretty()
```

## 🎯 Best Practices

### Book ID Naming
- Use consistent format: `BOOK001`, `BOOK002`, etc.
- Include leading zeros for proper sorting
- Keep IDs short but descriptive

### Author Names
- Use full names: "J.R.R. Tolkien" not "Tolkien"
- Be consistent with formatting
- For multiple authors: "Author One and Author Two"

### ISBN Format
- Include hyphens: `978-0-123456-78-9`
- Verify ISBN validity before adding
- Use ISBN-13 format when possible

### Inventory Management
- Keep available copies ≤ total quantity
- Update availability when books are borrowed/returned
- Regular inventory audits recommended

## 📈 Future Enhancements

- **Barcode scanning** for quick book addition
- **Bulk import** from CSV files
- **Author autocomplete** based on existing entries
- **Book cover images** and descriptions
- **Advanced search** by title, author, or ISBN
- **Book categories** and genre classification

---

**Happy Book Managing! 📚✨**

For technical support or feature requests, please check the main project documentation. 