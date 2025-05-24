/**
 * AI Starter Project
 * 
 * This is a simple Express server designed to be AI-friendly.
 * Each section has clear comments to help AI assistants understand
 * and modify the code.
 * 
 * To run: npm start
 * To develop: npm run dev (auto-restarts on changes)
 */

const express = require('express');
const app = express();
const PORT = 3000;

// Middleware Configuration
// This tells Express how to handle different types of requests
app.use(express.json()); // For parsing JSON bodies
app.use(express.static('public')); // Serve static files from 'public' folder

/**
 * Routes Section
 * Each route handles a different URL path
 */

// Home route - returns a welcome message
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to your AI-assisted project!',
    tips: [
      'Ask AI to add new routes',
      'Ask AI to connect a database',
      'Ask AI to add authentication',
      'Ask AI to create a frontend'
    ]
  });
});

// Example API endpoint
app.get('/api/hello', (req, res) => {
  const name = req.query.name || 'World';
  res.json({
    greeting: `Hello, ${name}!`,
    timestamp: new Date().toISOString()
  });
});

// TODO: Add more routes here
// Examples you can ask AI to help with:
// - POST /api/users - Create a new user
// - GET /api/users - Get all users
// - PUT /api/users/:id - Update a user
// - DELETE /api/users/:id - Delete a user

/**
 * Error Handling
 * Catches any errors and returns a friendly message
 */
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message
  });
});

/**
 * Start the Server
 */
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log('📝 Tips:');
  console.log('   - Visit http://localhost:3000 in your browser');
  console.log('   - Try http://localhost:3000/api/hello?name=YourName');
  console.log('   - Ask AI to help you add new features!');
});