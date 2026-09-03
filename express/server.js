const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
require('dotenv').config();

const express = require('express');
const authRoutes = require('./routes/authRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const serverRoutes = require('./routes/serverRoutes');

const app = express();
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api', dashboardRoutes);
app.use('/api/server', serverRoutes);

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`api berjalan di http://localhost:${PORT}`);
});
