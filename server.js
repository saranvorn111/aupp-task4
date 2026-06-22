const express = require('express');
const userRoutes = require('./userRoutes');

const app = express();

app.use(express.json());
app.use('/', userRoutes);

app.listen(5000, () => {
    console.log('Server running on port 5000');
});