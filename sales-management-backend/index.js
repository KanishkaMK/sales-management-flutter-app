const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
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

//File upload configuration

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'));
        }
    },
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});



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
// app.get('/api/customers', async (req, res) => {  // Remove authenticateToken
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
//         console.log('Database error:', error.message);
//         // Return demo data if database fails
//         res.json([
//             { ID: 1, Name: 'Demo Customer 1', Address: 'Demo Address 1', AreaName: 'North', CategoryName: 'Regular' },
//             { ID: 2, Name: 'Demo Customer 2', Address: 'Demo Address 2', AreaName: 'South', CategoryName: 'Premium' }
//         ]);
//     }
// });

// app.post('/api/customers', async (req, res) => {
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
//         console.log('Add customer error:', error.message);
//         res.status(500).json({ error: error.message });
//     }
// });



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



// Get dropdown data
// app.get('/api/dropdowns', async (req, res) => {
//   try {
//     const connection = await mysql.createConnection(dbConfig);
    
//     const [areas] = await connection.execute('SELECT * FROM CustomerArea');
//     const [categories] = await connection.execute('SELECT * FROM CustomerCategory');
    
//     await connection.end();
    
//     res.json({
//       success: true,
//       data: {
//         areas,
//         categories
//       }
//     });
//   } catch (error) {
//     res.status(500).json({
//       success: false,
//       message: error.message
//     });
//   }
// });

// Update customer
// app.put('/api/customers/:id', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;
//     const { Name, Address, AreaID, CategoryID } = req.body;
//     const connection = await mysql.createConnection(dbConfig);
    
//     const [result] = await connection.execute(
//       'UPDATE CustomerMaster SET Name = ?, Address = ?, AreaID = ?, CategoryID = ? WHERE ID = ?',
//       [Name, Address, AreaID, CategoryID, id]
//     );
    
//     await connection.end();
    
//     if (result.affectedRows === 0) {
//       return res.status(404).json({ error: 'Customer not found' });
//     }
    
//     res.json({ message: 'Customer updated successfully' });
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// });

// // Delete customer
// app.delete('/api/customers/:id', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;
//     const connection = await mysql.createConnection(dbConfig);
    
//     const [result] = await connection.execute(
//       'DELETE FROM CustomerMaster WHERE ID = ?',
//       [id]
//     );
    
//     await connection.end();
    
//     if (result.affectedRows === 0) {
//       return res.status(404).json({ error: 'Customer not found' });
//     }
    
//     res.json({ message: 'Customer deleted successfully' });
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// });







// ========== CUSTOMER ENDPOINTS ==========

// Get customers
app.get('/api/customers', async (req, res) => {
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
        res.json([
            { ID: 1, Name: 'Demo Customer 1', Address: 'Demo Address 1', AreaName: 'North', CategoryName: 'Regular' },
            { ID: 2, Name: 'Demo Customer 2', Address: 'Demo Address 2', AreaName: 'South', CategoryName: 'Premium' }
        ]);
    }
});

// Add customer
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

// Update customer
app.put('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { Name, Address, AreaID, CategoryID } = req.body;
        const connection = await mysql.createConnection(dbConfig);
        
        const [result] = await connection.execute(
            'UPDATE CustomerMaster SET Name = ?, Address = ?, AreaID = ?, CategoryID = ? WHERE ID = ?',
            [Name, Address, AreaID, CategoryID, id]
        );
        
        await connection.end();
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        
        res.json({ message: 'Customer updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete customer
app.delete('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const connection = await mysql.createConnection(dbConfig);
        
        const [result] = await connection.execute(
            'DELETE FROM CustomerMaster WHERE ID = ?',
            [id]
        );
        
        await connection.end();
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        
        res.json({ message: 'Customer deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ========== DROPDOWNS ENDPOINT ==========

// Get dropdown data - ADD THIS ENDPOINT
app.get('/api/dropdowns', async (req, res) => {
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        console.log('📊 Fetching dropdown data from database...');
        
        const [areas] = await connection.execute('SELECT * FROM CustomerArea');
        const [categories] = await connection.execute('SELECT * FROM CustomerCategory');
        
        await connection.end();
        
        console.log('✅ Dropdown data fetched - Areas:', areas.length, 'Categories:', categories.length);
        
        // If no data in database, return demo data
        const areasData = areas.length > 0 ? areas : [
            { ID: 1, Name: 'North' },
            { ID: 2, Name: 'South' },
            { ID: 3, Name: 'East' },
            { ID: 4, Name: 'West' }
        ];
        
        const categoriesData = categories.length > 0 ? categories : [
            { ID: 1, Name: 'Regular' },
            { ID: 2, Name: 'Premium' },
            { ID: 3, Name: 'Wholesale' }
        ];
        
        res.json({
            success: true,
            data: {
                areas: areasData,
                categories: categoriesData
            }
        });
    } catch (error) {
        console.log('❌ Dropdowns error:', error.message);
        // Return demo data even if database fails
        res.json({
            success: true,
            data: {
                areas: [
                    { ID: 1, Name: 'North' },
                    { ID: 2, Name: 'South' },
                    { ID: 3, Name: 'East' },
                    { ID: 4, Name: 'West' }
                ],
                categories: [
                    { ID: 1, Name: 'Regular' },
                    { ID: 2, Name: 'Premium' },
                    { ID: 3, Name: 'Wholesale' }
                ]
            }
        });
    }
});





// ========== PRODUCT ENDPOINTS ==========

// Get products with category and brand names
app.get('/api/products', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [products] = await connection.execute(`
      SELECT pm.*, pc.Name as CategoryName, pb.Name as BrandName 
      FROM ProductMaster pm
      LEFT JOIN ProductCategory pc ON pm.CategoryID = pc.ID
      LEFT JOIN ProductBrand pb ON pm.BrandID = pb.ID
    `);
    await connection.end();
    res.json(products);
  } catch (error) {
    console.log('Products error:', error.message);
    // Return demo data if database fails
    res.json([
      { 
        ID: 1, 
        Name: 'Sample Laptop', 
        CategoryID: 1, 
        BrandID: 3, 
        PurchaseRate: 800.00, 
        SalesRate: 999.99,
        CategoryName: 'Electronics',
        BrandName: 'Apple'
      },
      { 
        ID: 2, 
        Name: 'Running Shoes', 
        CategoryID: 2, 
        BrandID: 2, 
        PurchaseRate: 45.00, 
        SalesRate: 79.99,
        CategoryName: 'Clothing',
        BrandName: 'Nike'
      }
    ]);
  }
});

// Add product
app.post('/api/products', async (req, res) => {
  try {
    const { Name, CategoryID, BrandID, PurchaseRate, SalesRate } = req.body;
    const connection = await mysql.createConnection(dbConfig);
    
    const [result] = await connection.execute(
      'INSERT INTO ProductMaster (Name, CategoryID, BrandID, PurchaseRate, SalesRate) VALUES (?, ?, ?, ?, ?)',
      [Name, CategoryID, BrandID, PurchaseRate, SalesRate]
    );
    
    await connection.end();
    res.json({ id: result.insertId, message: 'Product created successfully' });
  } catch (error) {
    console.log('Add product error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Update product
app.put('/api/products/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { Name, CategoryID, BrandID, PurchaseRate, SalesRate } = req.body;
    const connection = await mysql.createConnection(dbConfig);
    
    const [result] = await connection.execute(
      'UPDATE ProductMaster SET Name = ?, CategoryID = ?, BrandID = ?, PurchaseRate = ?, SalesRate = ? WHERE ID = ?',
      [Name, CategoryID, BrandID, PurchaseRate, SalesRate, id]
    );
    
    await connection.end();
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json({ message: 'Product updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete product
app.delete('/api/products/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const connection = await mysql.createConnection(dbConfig);
    
    const [result] = await connection.execute(
      'DELETE FROM ProductMaster WHERE ID = ?',
      [id]
    );
    
    await connection.end();
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get product dropdowns
app.get('/api/product-dropdowns', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    
    const [categories] = await connection.execute('SELECT * FROM ProductCategory');
    const [brands] = await connection.execute('SELECT * FROM ProductBrand');
    
    await connection.end();
    
    // If no data in database, return demo data
    const categoriesData = categories.length > 0 ? categories : [
      { ID: 1, Name: 'Electronics' },
      { ID: 2, Name: 'Clothing' },
      { ID: 3, Name: 'Food' },
      { ID: 4, Name: 'Books' },
    ];
    
    const brandsData = brands.length > 0 ? brands : [
      { ID: 1, Name: 'Samsung' },
      { ID: 2, Name: 'Nike' },
      { ID: 3, Name: 'Apple' },
      { ID: 4, Name: 'Adidas' },
    ];
    
    res.json({
      success: true,
      data: {
        categories: categoriesData,
        brands: brandsData
      }
    });
  } catch (error) {
    console.log('Product dropdowns error:', error.message);
    res.json({
      success: true,
      data: {
        categories: [
          { ID: 1, Name: 'Electronics' },
          { ID: 2, Name: 'Clothing' },
          { ID: 3, Name: 'Food' },
          { ID: 4, Name: 'Books' },
        ],
        brands: [
          { ID: 1, Name: 'Samsung' },
          { ID: 2, Name: 'Nike' },
          { ID: 3, Name: 'Apple' },
          { ID: 4, Name: 'Adidas' },
        ]
      }
    });
  }
});



//endpoint for image upload
app.post('/api/upload-product-image', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const imagePath = req.file.filename;
        res.json({ 
            success: true, 
            imagePath: imagePath,
            message: 'Image uploaded successfully'
        });
    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: 'Failed to upload image' });
    }
});

// endpoint to save product image reference
app.post('/api/product-images', async (req, res) => {
    try {
        const { productId, imagePath } = req.body;
        const connection = await mysql.createConnection(dbConfig);
        
        const [result] = await connection.execute(
            'INSERT INTO ProductImages (ProductID, ImagePath) VALUES (?, ?)',
            [productId, imagePath]
        );
        
        await connection.end();
        res.json({ success: true, id: result.insertId });
    } catch (error) {
        console.error('Error saving product image:', error);
        res.status(500).json({ error: 'Failed to save product image' });
    }
});

//  endpoint to get product images
app.get('/api/product-images/:productId', async (req, res) => {
    try {
        const { productId } = req.params;
        const connection = await mysql.createConnection(dbConfig);
        
        const [rows] = await connection.execute(
            'SELECT * FROM ProductImages WHERE ProductID = ?',
            [productId]
        );
        
        await connection.end();
        res.json(rows);
    } catch (error) {
        console.error('Error fetching product images:', error);
        res.status(500).json({ error: 'Failed to fetch product images' });
    }
});





// ========== SALES INVOICE ENDPOINTS ==========

// Create sales invoice
app.post('/api/sales-invoices', async (req, res) => {
  try {
    console.log('📦 Creating sales invoice:', req.body);
    
    const { CustomerId, Address, TotalQty, TotalAmount, Items } = req.body;
    const connection = await mysql.createConnection(dbConfig);
    
    // Start transaction
    await connection.beginTransaction();
    
    try {
      // Insert into Sales table
      const [salesResult] = await connection.execute(
        'INSERT INTO Sales (txnDate, CustomerId, Address, TotalQty, TotalAmount) VALUES (NOW(), ?, ?, ?, ?)',
        [CustomerId, Address, TotalQty, TotalAmount]
      );
      
      const txnNo = salesResult.insertId;
      console.log('✅ Sales record created with TxnNo:', txnNo);
      
      // Insert into SalesDetails table
      let sno = 1;
      for (const item of Items) {
        console.log('📝 Adding sales detail:', item);
        await connection.execute(
          'INSERT INTO SalesDetails (TxnNo, Sno, ProductID, Quantity, Rate, Discount, Amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [txnNo, sno, item.ProductID, item.Quantity, item.Rate, item.Discount, item.Amount]
        );
        sno++;
      }
      
      // Commit transaction
      await connection.commit();
      await connection.end();
      
      console.log('✅ Invoice created successfully with', Items.length, 'items');
      
      res.json({ 
        success: true,
        txnNo: txnNo, 
        message: 'Invoice created successfully' 
      });
    } catch (error) {
      // Rollback transaction on error
      await connection.rollback();
      throw error;
    }
  } catch (error) {
    console.log('❌ Create invoice error:', error.message);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Get sales invoices
app.get('/api/sales-invoices', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [invoices] = await connection.execute(`
      SELECT s.*, cm.Name as CustomerName 
      FROM Sales s
      LEFT JOIN CustomerMaster cm ON s.CustomerId = cm.ID
      ORDER BY s.txnDate DESC
    `);
    
    // Get details for each invoice
    for (const invoice of invoices) {
      const [details] = await connection.execute(`
        SELECT sd.*, pm.Name as ProductName 
        FROM SalesDetails sd
        LEFT JOIN ProductMaster pm ON sd.ProductID = pm.ID
        WHERE sd.TxnNo = ?
        ORDER BY sd.Sno
      `, [invoice.TxnNo]);
      
      invoice.Items = details;
    }
    
    await connection.end();
    
    res.json({
      success: true,
      data: invoices
    });
  } catch (error) {
    console.log('❌ Get invoices error:', error.message);
    // Return demo data if database fails
    res.json({
      success: true,
      data: [
        {
          TxnNo: 1,
          txnDate: new Date().toISOString(),
          CustomerId: 1,
          CustomerName: 'John Electronics',
          Address: '123 Main Street',
          TotalQty: 3,
          TotalAmount: 1125.49,
          Items: [
            {
              ID: 1,
              TxnNo: 1,
              Sno: 1,
              ProductID: 1,
              ProductName: 'Laptop Pro',
              Quantity: 1,
              Rate: 999.99,
              Discount: 0,
              Amount: 999.99
            },
            {
              ID: 2,
              TxnNo: 1,
              Sno: 2,
              ProductID: 2,
              ProductName: 'Running Shoes',
              Quantity: 2,
              Rate: 25.50,
              Discount: 0,
              Amount: 51.00
            }
          ]
        }
      ]
    });
  }
});








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