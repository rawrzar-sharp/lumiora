const express = require('express');
const router = express.Router();
const cms = require('../controllers/cmsController');
const { authenticate, adminOnly } = require('../middleware/auth');

// Orders log and notifications
router.get('/orders', authenticate, cms.getOrdersLog);
router.get('/notifications', authenticate, cms.getNotifications);

// Inventory / ingredients
router.get('/ingredients', authenticate, cms.getIngredients);
router.get('/ingredients/low', authenticate, cms.getLowIngredients);
router.patch('/ingredients/stock', authenticate, adminOnly, cms.updateIngredientStock);

// Recipes
router.get('/recipes', authenticate, cms.getRecipes);
router.get('/recipes/menu/:id', authenticate, cms.getRecipeByMenu);

// Reports
router.get('/reports/daily', authenticate, cms.getDailySales);
router.get('/reports/monthly', authenticate, cms.getMonthlySales);

module.exports = router;
