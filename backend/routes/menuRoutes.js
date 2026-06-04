const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../middleware/auth');
const {
  getAllMenu, getMenuById, getMenuByCategory, createMenu, updateMenu, deleteMenu, updateStock
} = require('../controllers/menuController');

/**
 * @openapi
 * /api/menu:
 *   get:
 *     tags: [Menu]
 *     summary: Get all menu items
 *     responses:
 *       200:
 *         description: List of menu items
 *   post:
 *     tags: [Menu]
 *     summary: Create a new menu item
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               category_id: { type: integer }
 *               item_name: { type: string }
 *               description: { type: string }
 *               image_url: { type: string }
 *               price: { type: integer }
 *               is_Available: { type: boolean }
 *     responses:
 *       201:
 *         description: Menu item created
 * /api/menu/{id}:
 *   get:
 *     tags: [Menu]
 *     summary: Get menu item by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Menu item data
 *   put:
 *     tags: [Menu]
 *     summary: Update a menu item
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Menu item updated
 *   delete:
 *     tags: [Menu]
 *     summary: Delete a menu item
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Menu item deleted
 * /api/menu/category/{categoryId}:
 *   get:
 *     tags: [Menu]
 *     summary: Get menu items by category
 *     parameters:
 *       - in: path
 *         name: categoryId
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Menu items in category
 */

router.get('/', getAllMenu);
router.get('/category/:categoryId', getMenuByCategory);
router.get('/:id', getMenuById);
router.post('/', authenticate, adminOnly, createMenu);
router.put('/:id', authenticate, adminOnly, updateMenu);
router.patch('/:id/stock', updateStock);
router.delete('/:id', authenticate, adminOnly, deleteMenu);

module.exports = router;
