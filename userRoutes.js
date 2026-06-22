const express = require('express');
const router = express.Router();

// Fake database
let user = {
    id: 1,
    username: 'admin',
    password: '123456',
    name: 'Vorn Saran',
    email: 'vorn@example.com'
};

// POST localhost:5000/login
router.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (
        username === user.username &&
        password === user.password
    ) {
        return res.json({
            message: 'Login successful'
        });
    }

    res.status(401).json({
        message: 'Invalid credentials'
    });
});

// PUT localhost:5000/updateprofile
router.put('/updateprofile', (req, res) => {
    const { name, email } = req.body;

    user.name = name || user.name;
    user.email = email || user.email;

    res.json({
        message: 'Profile updated',
        user
    });
});

// GET localhost:5000/view
router.get('/view', (req, res) => {
    res.json(user);
});

// GET localhost:5000/search?name=vorn
router.get('/search', (req, res) => {
    const keyword = req.query.name;

    if (
        user.name.toLowerCase().includes(keyword.toLowerCase())
    ) {
        return res.json(user);
    }

    res.status(404).json({
        message: 'User not found'
    });
});

module.exports = router;