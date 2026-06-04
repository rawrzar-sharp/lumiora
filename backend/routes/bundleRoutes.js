const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../middleware/auth');
const {
  getBundles, getBundleById, createBundle, updateBundle, deleteBundle
} = require('../controllers/bundleController');

/**
 * @openapi
 * /api/bundles:
 *   get:
 *     tags: [Bundles]
 *     summary: Get all bundles
 *     responses:
 *       200:
 *         description: List of bundles
 *   post:
 *     tags: [Bundles]
 *     summary: Create a new bundle
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               Type: { type: string }
 *               name: { type: string }
 *               description: { type: string }
 *               price: { type: number }
 *     responses:
 *       201:
 *         description: Bundle created
 * /api/bundles/{id}:
 *   get:
 *     tags: [Bundles]
 *     summary: Get bundle by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Bundle data
 *   put:
 *     tags: [Bundles]
 *     summary: Update a bundle
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Bundle updated
 *   delete:
 *     tags: [Bundles]
 *     summary: Delete a bundle
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Bundle deleted
 */

router.get('/', getBundles);
router.get('/:id', getBundleById);
router.post('/', authenticate, createBundle);
router.put('/:id', authenticate, updateBundle);
router.delete('/:id', authenticate, adminOnly, deleteBundle);

module.exports = router;
