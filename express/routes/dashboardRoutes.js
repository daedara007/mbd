const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { validasiToken, validasiAdmin } = require('../middlewares/authMiddleware');

router.get('/dashboard', validasiToken, dashboardController.getDashboard);
router.get('/saldo', validasiToken, dashboardController.getSaldo);
router.get('/transaksi', validasiToken, dashboardController.getRiwayatTransaksi);
router.post('/saldo/topup', validasiToken, validasiAdmin, dashboardController.topupSaldo);
router.get('/pengguna', validasiToken, validasiAdmin, dashboardController.getDaftarPengguna);

module.exports = router;
