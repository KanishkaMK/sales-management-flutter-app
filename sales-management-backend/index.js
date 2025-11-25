const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
//const multer = require('multer');
const path = require('path');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'your-secret-key';

// ✅ Allow all origins for development (or specify your phone's IP)
app.use(cors({
  origin: '*', // For development only
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true
}));

app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));

// Database connection
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: 'Kani@123',
    database: 'sales_management'
};

async function testConnection() {
    try {
        const connection = await mysql.createConnection(dbConfig);
        console.log('✅ MySQL Database connected successfully!');
        await connection.end();
        return true;
    } catch (error) {
        console.log('❌ Database connection failed:', error.message);
        console.log('💡 Please check your MySQL credentials and make sure the database exists');
        return false;
    }
}

// File upload configuration
// const storage = multer.diskStorage({
//     destination: (req, file, cb) => {
//         cb(null, 'uploads/');
//     },
//     filename: (req, file, cb) => {
//         cb(null, Date.now() + '-' + file.originalname);
//     }
// });
// const upload = multer({ storage });

// Middleware to verify token


const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};


// ========== ROUTES ==========


// Simple test route - NO AUTHENTICATION REQUIRED
app.get('/', (req, res) => {
    res.json({ 
        message: 'Sales Management API is running!',
        status: 'OK',
        timestamp: new Date().toISOString(),
        endpoints: {
            login: 'POST /api/login',
            customers: 'GET /api/customers',
            test: 'GET /api/test'
        }
    });
});

// Test route without authentication
app.get('/api/test', (req, res) => {
    res.json({ 
        success: true,
        message: 'API is working!',
        data: { test: 'This is a test response' }
    });
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        database: 'sales_management',
        timestamp: new Date().toISOString()
    });
});


// Login endpoint
app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const connection = await mysql.createConnection(dbConfig);
        
        const [users] = await connection.execute(
            'SELECT * FROM UserMaster WHERE Name = ?',
            [username]
        );
        
        await connection.end();

        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = users[0];
        
        // For demo purposes, using simple password comparison
        // In production, use bcrypt.compare()
        if (password !== user.Password) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { userId: user.ID, username: user.Name },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: {
                id: user.ID,
                name: user.Name
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


// Customer endpoints - TEMPORARILY REMOVE AUTHENTICATION FOR TESTING
app.get('/api/customers', async (req, res) => {  // Remove authenticateToken
    try {
        const connection = await mysql.createConnection(dbConfig);
        const [customers] = await connection.execute(`
            SELECT cm.*, ca.Name as AreaName, cc.Name as CategoryName 
            FROM CustomerMaster cm
            LEFT JOIN CustomerArea ca ON cm.AreaID = ca.ID
            LEFT JOIN CustomerCategory cc ON cm.CategoryID = cc.ID
        `);
        await connection.end();
        res.json(customers);
    } catch (error) {
        console.log('Database error:', error.message);
        // Return demo data if database fails
        res.json([
            { ID: 1, Name: 'Demo Customer 1', Address: 'Demo Address 1', AreaName: 'North', CategoryName: 'Regular' },
            { ID: 2, Name: 'Demo Customer 2', Address: 'Demo Address 2', AreaName: 'South', CategoryName: 'Premium' }
        ]);
    }
});

app.post('/api/customers', async (req, res) => {
    try {
        const { Name, Address, AreaID, CategoryID } = req.body;
        const connection = await mysql.createConnection(dbConfig);
        
        const [result] = await connection.execute(
            'INSERT INTO CustomerMaster (Name, Address, AreaID, CategoryID) VALUES (?, ?, ?, ?)',
            [Name, Address, AreaID, CategoryID]
        );
        
        await connection.end();
        res.json({ id: result.insertId, message: 'Customer created successfully' });
    } catch (error) {
        console.log('Add customer error:', error.message);
        res.status(500).json({ error: error.message });
    }
});



// Customer endpoints
// app.get('/api/customers', authenticateToken, async (req, res) => {
//     try {
//         const connection = await mysql.createConnection(dbConfig);
//         const [customers] = await connection.execute(`
//             SELECT cm.*, ca.Name as AreaName, cc.Name as CategoryName 
//             FROM CustomerMaster cm
//             LEFT JOIN CustomerArea ca ON cm.AreaID = ca.ID
//             LEFT JOIN CustomerCategory cc ON cm.CategoryID = cc.ID
//         `);
//         await connection.end();
//         res.json(customers);
//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// });

// app.post('/api/customers', authenticateToken, async (req, res) => {
//     try {
//         const { Name, Address, AreaID, CategoryID } = req.body;
//         const connection = await mysql.createConnection(dbConfig);
        
//         const [result] = await connection.execute(
//             'INSERT INTO CustomerMaster (Name, Address, AreaID, CategoryID) VALUES (?, ?, ?, ?)',
//             [Name, Address, AreaID, CategoryID]
//         );
        
//         await connection.end();
//         res.json({ id: result.insertId, message: 'Customer created successfully' });
//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// });

// Add similar endpoints for Products, Sales, etc.


// Start server
app.listen(PORT, '0.0.0.0', async () => {
    console.log('🚀 Server started successfully!');
    console.log(`📍 Local: http://localhost:${PORT}`);
    console.log(`📍 Network: http://YOUR-IP:${PORT}`);
    console.log('📋 Testing connection to database...');
    
    await testConnection();
    console.log('💡 API endpoints:');
    console.log('   GET  /api/customers');
    console.log('   POST /api/login');
});