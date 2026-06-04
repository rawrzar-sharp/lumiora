const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  getOrders, getOrderById, getOrdersByCustomer, createOrder, updateOrder, deleteOrder
} = require('../controllers/orderController');

/**
 * @openapi
 * /api/orders:
 *   get:
 *     tags: [Orders]
 *     summary: Get all orders
 *     responses:
 *       200:
 *         description: List of orders
 *   post:
 *     tags: [Orders]
 *     summary: Create a new order
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               customer_id: { type: integer }
 *               menu_id: { type: integer }
 *               quantity: { type: integer }
 *               ice_level: { type: string, enum: [iced, hot] }
 *               sugar_level: { type: string, enum: [less, normal, high] }
 *     responses:
 *       201:
 *         description: Order created
 * /api/orders/{id}:
 *   get:
 *     tags: [Orders]
 *     summary: Get order by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Order data
 *   put:
 *     tags: [Orders]
 *     summary: Update an order
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Order updated
 *   delete:
 *     tags: [Orders]
 *     summary: Delete an order
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Order deleted
 * /api/orders/customer/{customerId}:
 *   get:
 *     tags: [Orders]
 *     summary: Get orders by customer ID
 *     parameters:
 *       - in: path
 *         name: customerId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Customer's orders
 */

router.get('/', getOrders);
router.get('/customer/:customerId', getOrdersByCustomer);
router.get('/:id', getOrderById);
router.post('/', createOrder);
router.put('/:id', authenticate, updateOrder);
router.delete('/:id', authenticate, deleteOrder);

module.exports = router;
