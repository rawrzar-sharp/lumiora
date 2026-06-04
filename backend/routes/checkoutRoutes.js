const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  getAllCheckouts, getCheckoutById, getCheckoutByOrder, createCheckout, updateCheckoutStatus
} = require('../controllers/checkoutController');

/**
 * @openapi
 * /api/checkouts:
 *   get:
 *     tags: [Checkouts]
 *     summary: Get all checkouts
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of checkouts
 *   post:
 *     tags: [Checkouts]
 *     summary: Create a checkout for an order
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               orders_id: { type: integer }
 *     responses:
 *       201:
 *         description: Checkout created
 * /api/checkouts/{id}:
 *   get:
 *     tags: [Checkouts]
 *     summary: Get checkout by ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Checkout data
 *   put:
 *     tags: [Checkouts]
 *     summary: Update payment status
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               payment_status:
 *                 type: string
 *                 enum: [cancelled, pending, paid]
 *     responses:
 *       200:
 *         description: Payment status updated
 * /api/checkouts/order/{orderId}:
 *   get:
 *     tags: [Checkouts]
 *     summary: Get checkout by order ID
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Checkout data for order
 */

router.get('/', authenticate, getAllCheckouts);
router.get('/order/:orderId', authenticate, getCheckoutByOrder);
router.get('/:id', authenticate, getCheckoutById);
router.post('/', createCheckout);
router.put('/:id', authenticate, updateCheckoutStatus);

module.exports = router;
