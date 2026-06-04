const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../middleware/auth');
const {
  getAllCustomers, getCustomerById, addCustomer, updateCustomer, deleteCustomer
} = require('../controllers/customerController');

/**
 * @openapi
 * /api/customers:
 *   get:
 *     tags: [Customers]
 *     summary: Get all customers
 *     responses:
 *       200:
 *         description: List of customers
 *   post:
 *     tags: [Customers]
 *     summary: Register a new customer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               phone: { type: string }
 *               birthday: { type: string, format: date }
 *     responses:
 *       201:
 *         description: Customer created
 * /api/customers/{id}:
 *   get:
 *     tags: [Customers]
 *     summary: Get customer by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Customer data
 *   put:
 *     tags: [Customers]
 *     summary: Update a customer
 *     responses:
 *       200:
 *         description: Customer updated
 *   delete:
 *     tags: [Customers]
 *     summary: Delete a customer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Customer deleted
 */

router.get('/', getAllCustomers);
router.get('/:id', getCustomerById);
router.post('/', addCustomer);
router.put('/:id', updateCustomer);
router.delete('/:id', authenticate, adminOnly, deleteCustomer);

module.exports = router;
