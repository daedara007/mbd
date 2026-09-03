const express = require('express');
const router = express.Router();
const serverController = require('../controllers/serverController');
const { validasiToken } = require('../middlewares/authMiddleware');

router.get('/paket', validasiToken, serverController.getDaftarPaket);
router.get('/node', validasiToken, serverController.getDaftarNode);
router.post('/deploy', validasiToken, serverController.deployServer);
router.post('/start', validasiToken, serverController.startServer);
router.post('/stop', validasiToken, serverController.stopServer);
router.post('/renew', validasiToken, serverController.renewServer);
router.put('/rename', validasiToken, serverController.renameServer);
router.delete('/destroy', validasiToken, serverController.destroyServer);
router.get('/:id_instance/logs', validasiToken, serverController.getLogServer);

module.exports = router;
