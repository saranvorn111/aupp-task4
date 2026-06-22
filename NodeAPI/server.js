const express = require('express');
const app = express();

const userRoute = require('./userRoute');

app.use(express.json());

// mount your router
app.use('/', userRoute);

const PORT = 5000;

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});