const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../middleware/auth');
const {
  getAllUsers, getUserById, createUser, updateUser, deleteUser
} = require('../controllers/userController');

/**
 * @openapi
 * /api/users:
 *   get:
 *     tags: [Users]
 *     summary: Get all users (admin only)
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of users
 *   post:
 *     tags: [Users]
 *     summary: Create a new user (admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               email: { type: string }
 *               password: { type: string }
 *               role: { type: string, enum: [admin, staff] }
 *     responses:
 *       201:
 *         description: User created
 * /api/users/{id}:
 *   get:
 *     tags: [Users]
 *     summary: Get user by ID (admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: User data
 *   put:
 *     tags: [Users]
 *     summary: Update a user (admin only)
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User updated
 *   delete:
 *     tags: [Users]
 *     summary: Delete a user (admin only)
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User deleted
 */

router.get('/', authenticate, adminOnly, getAllUsers);
router.get('/:id', authenticate, adminOnly, getUserById);
router.post('/', authenticate, adminOnly, createUser);
router.put('/:id', authenticate, adminOnly, updateUser);
router.delete('/:id', authenticate, adminOnly, deleteUser);

module.exports = router;
