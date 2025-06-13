# 📚 Library Management System

A comprehensive Library Management System built with Scala (Akka HTTP) backend and HTML/CSS/JavaScript frontend.

## 🚀 Features

### Frontend Features
- **Public Landing Page** - Welcoming library homepage
- **User Authentication** - Login system for admins and librarians
- **Admin Dashboard** - Complete management interface for administrators
- **Librarian Dashboard** - Specialized interface for library staff
- **Member Management** - Add, edit, and manage library members
- **Librarian Management** - Manage librarian profiles and specializations
- **Book Request System** - Handle book issue and return requests
- **Book Inventory** - Comprehensive book collection management
- **Staff Management** - Manage library staff and roles
- **Query System** - Advanced search and reporting capabilities

### Backend Features
- **RESTful API** - Complete CRUD operations for all entities
- **MongoDB Integration** - Persistent data storage
- **CORS Support** - Cross-origin resource sharing enabled
- **User Authentication** - Secure user registration and login
- **Legacy Compatibility** - Backward compatible with hospital system endpoints

## 🏗️ Architecture

```
Frontend (Port: File System)     Backend (Port: 8080)     Database (Port: 27017)
├── landing.html                 ├── /users               ├── library_db
├── login.html                   ├── /members             │   ├── users
├── index.html (members)         ├── /librarians          │   ├── members
├── doctors.html (librarians)    ├── /book-requests       │   ├── librarians
├── appointments.html (requests) ├── /inventory           │   ├── book_requests
├── inventory.html               ├── /staff               │   ├── inventory
├── staff.html                   └── Legacy:              │   ├── staff
├── query.html                       ├── /doctors         │   └── Legacy:
└── landing_doctor.html              ├── /appointments    │       ├── doctors
                                     └── /pharmacy        │       └── appointments
```

## 🛠️ Prerequisites

### Backend Requirements
- **Java 8+** (for Scala)
- **SBT** (Scala Build Tool)
- **MongoDB** (version 4.0+)

### Frontend Requirements
- **Web Browser** (Chrome, Firefox, Safari, Edge)
- **HTTP Server** (for serving static files)

## 📦 Installation & Setup

### 1. Database Setup

1. **Install MongoDB:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install mongodb
   
   # macOS (with Homebrew)
   brew install mongodb-community
   
   # Windows - Download from mongodb.com
   ```

2. **Start MongoDB:**
   ```bash
   # Linux/macOS
   sudo service mongod start
   # OR
   mongod --dbpath /data/db
   
   # Windows
   net start MongoDB
   ```

3. **Verify MongoDB is running:**
   ```bash
   mongo --eval "db.adminCommand('ismaster')"
   ```

### 2. Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd BDA/backend
   ```

2. **Compile and run the backend:**
   ```bash
   sbt compile
   sbt run
   ```

3. **Verify backend is running:**
   - Open browser to `http://localhost:8080`
   - You should see the API server running

### 3. Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd BDA/frontend
   ```

2. **Start a local HTTP server:**
   
   **Option A: Using Python (if available):**
   ```bash
   # Python 3
   python -m http.server 3000
   
   # Python 2
   python -m SimpleHTTPServer 3000
   ```
   
   **Option B: Using Node.js (if available):**
   ```bash
   npx http-server -p 3000
   ```
   
   **Option C: Using Live Server (VS Code extension):**
   - Install "Live Server" extension in VS Code
   - Right-click on `landing.html` and select "Open with Live Server"

3. **Access the application:**
   - Open browser to `http://localhost:3000` (or the port shown)
   - Start with `landing.html`

## 🎯 Usage Guide

### Initial Setup & Login

1. **Start from the Landing Page:**
   - Navigate to `http://localhost:3000/landing.html`
   - Click "Login" button

2. **Create Admin User:**
   - Click "Sign Up" tab
   - Fill in details:
     - Username: `admin`
     - Email: `admin@library.com` 
     - Password: `admin123`
     - Role: Select "Admin"
   - Click "Sign Up"

3. **Login as Admin:**
   - Switch to "Login" tab
   - Enter credentials above
   - Select "Admin" role
   - Click "Login"

### Using the System

#### Admin Dashboard Features:
- **Member Management** - Add/edit library members
- **Librarian Management** - Manage librarian profiles
- **Book Requests** - Handle book issue/return requests
- **Inventory** - Manage book collection
- **Staff Management** - Add/edit staff members
- **Query System** - Search and generate reports

#### Librarian Dashboard Features:
- **Book Requests** - Process member requests
- **Inventory** - View and update book information
- **Members** - View member information
- **Query System** - Search database

## 🔧 API Endpoints

### Authentication
- `POST /users/signup` - Register new user
- `GET /users` - Get all users
- `GET /users/{id}` - Get user by ID

### Library Management
- `GET|POST|PUT|DELETE /members` - Member CRUD operations
- `GET|POST|PUT|DELETE /librarians` - Librarian CRUD operations
- `GET|POST|PUT|DELETE /book-requests` - Book request CRUD operations
- `GET|POST|PUT|DELETE /inventory` - Book inventory CRUD operations
- `GET|POST|PUT|DELETE /staff` - Staff CRUD operations

### Legacy Compatibility
- `GET|POST|PUT|DELETE /doctors` - Maps to librarians
- `GET|POST|PUT|DELETE /appointments` - Maps to book-requests
- `GET|POST|PUT|DELETE /pharmacy` - Maps to inventory

## 📊 Sample Data

Test users for login:
```json
{
  "admin": {
    "username": "admin",
    "password": "admin123",
    "role": "admin"
  },
  "librarian": {
    "username": "librarian1", 
    "password": "lib123",
    "role": "doctor"
  }
}
```

## 🐛 Troubleshooting

### Common Issues:

1. **Backend won't start:**
   - Check if MongoDB is running: `mongo --eval "db.runCommand({connectionStatus: 1})"`
   - Verify port 8080 is not in use: `lsof -i :8080`

2. **Frontend CORS errors:**
   - Ensure backend is running on `localhost:8080`
   - Use proper HTTP server for frontend (not file:// protocol)

3. **Login not working:**
   - Check browser console for errors
   - Verify backend API responses in Network tab
   - Ensure users collection exists in MongoDB

4. **MongoDB connection issues:**
   - Check MongoDB service status: `sudo service mongod status`
   - Verify MongoDB is listening on port 27017

### Database Commands:
```bash
# Connect to MongoDB
mongo

# Switch to library database
use library_db

# View collections
show collections

# View users
db.users.find().pretty()

# Clear all data (if needed)
db.dropDatabase()
```

## 🔄 Development Workflow

1. **Backend Changes:**
   ```bash
   cd BDA/backend
   sbt compile
   sbt run
   ```

2. **Frontend Changes:**
   - No compilation needed
   - Refresh browser to see changes

3. **Database Schema Changes:**
   - Update case classes in `Main.scala`
   - Restart backend

## 📝 Project Structure

```
BDA/
├── frontend/
│   ├── landing.html          # Public homepage
│   ├── login.html            # Authentication page
│   ├── index.html            # Member management
│   ├── doctors.html          # Librarian management
│   ├── appointments.html     # Book request management
│   ├── inventory.html        # Book inventory management
│   ├── staff.html            # Staff management
│   ├── query.html            # Query system
│   └── landing_doctor.html   # Librarian dashboard
├── backend/
│   ├── src/main/scala/
│   │   └── Main.scala        # Backend API server
│   ├── build.sbt             # Project configuration
│   └── test-data.json        # Sample data
└── README.md                 # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit pull request

## 📄 License

This project is licensed under the MIT License.

---

**Happy Library Management! 📚✨**
