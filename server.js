const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./backend/routes/authRoutes');
app.use('/api/auth', authRoutes);

// MongoDB connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(5000, '0.0.0.0', () => {
      console.log("Server running on http://0.0.0.0:5000");
    });
  })
  .catch((err) => console.error('MongoDB error:', err));

