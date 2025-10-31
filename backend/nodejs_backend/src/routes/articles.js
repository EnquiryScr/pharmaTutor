const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { handleValidationErrors, commonValidations, articleValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Create article
router.post('/', [
  authMiddleware,
  ...articleValidations.create
], handleValidationErrors, async (req, res, next) => {
  try {
    const authorId = req.user.userId;
    const {
      title,
      content,
      summary,
      tags = [],
      category,
      difficultyLevel,
      estimatedReadTime,
      isPublished = false
    } = req.body;

    const articleId = uuidv4();

    const result = await databaseService.query(
      databaseService.queries.articles.create,
      [
        articleId,
        authorId,
        title,
        content,
        summary,
        JSON.stringify(tags),
        category,
        difficultyLevel,
        estimatedReadTime,
        isPublished
      ]
    );

    const article = result.rows[0];

    logger.info('Article created', {
      articleId,
      authorId,
      category,
      isPublished
    });

    res.status(201).json({
      success: true,
      message: 'Article created successfully',
      data: { article }
    });

  } catch (error) {
    next(error);
  }
});

// Get all published articles
router.get('/', [
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const { page = 1, limit = 20, category, search } = req.query;
    const offset = (page - 1) * limit;

    let query = databaseService.queries.articles.findAll;
    let params = [limit, offset];

    if (category) {
      query = databaseService.queries.articles.findByCategory;
      params = [category, limit, offset];
    } else if (search) {
      query = databaseService.queries.articles.search;
      params = [`%${search}%`, limit, offset];
    }

    const result = await databaseService.query(query, params);
    const articles = result.rows.map(article => ({
      ...article,
      tags: article.tags ? JSON.parse(article.tags) : []
    }));

    res.json({
      success: true,
      data: { articles }
    });

  } catch (error) {
    next(error);
  }
});

// Get specific article
router.get('/:id', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid article ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const articleId = req.params.id;

    const result = await databaseService.query(
      databaseService.queries.articles.findById,
      [articleId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Article not found'
      });
    }

    const article = result.rows[0];

    // Increment view count
    await databaseService.query(
      databaseService.queries.articles.incrementViews,
      [articleId]
    );

    const processedArticle = {
      ...article,
      tags: article.tags ? JSON.parse(article.tags) : []
    };

    res.json({
      success: true,
      data: { article: processedArticle }
    });

  } catch (error) {
    next(error);
  }
});

// Update article
router.put('/:id', [
  authMiddleware,
  ...articleValidations.create, // Can reuse the same validation
  param('id').isUUID().withMessage('Invalid article ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const articleId = req.params.id;
    const userId = req.user.userId;

    // Check if user owns the article or is admin
    const articleResult = await databaseService.query(
      databaseService.queries.articles.findById,
      [articleId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Article not found'
      });
    }

    const article = articleResult.rows[0];

    if (article.author_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const {
      title,
      content,
      summary,
      tags = [],
      category,
      difficultyLevel,
      estimatedReadTime,
      isPublished
    } = req.body;

    const result = await databaseService.query(
      databaseService.queries.articles.update,
      [
        articleId,
        title || article.title,
        content || article.content,
        summary || article.summary,
        JSON.stringify(tags),
        category || article.category,
        difficultyLevel || article.difficulty_level,
        estimatedReadTime || article.estimated_read_time,
        isPublished !== undefined ? isPublished : article.is_published
      ]
    );

    const updatedArticle = result.rows[0];

    res.json({
      success: true,
      message: 'Article updated successfully',
      data: { 
        article: {
          ...updatedArticle,
          tags: updatedArticle.tags ? JSON.parse(updatedArticle.tags) : []
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Like article
router.post('/:id/like', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid article ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const articleId = req.params.id;
    const userId = req.user.userId;

    // Check if article exists
    const articleResult = await databaseService.query(
      databaseService.queries.articles.findById,
      [articleId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Article not found'
      });
    }

    // Add like
    await databaseService.query(
      'INSERT INTO article_likes (id, article_id, user_id) VALUES ($1, $2, $3)',
      [uuidv4(), articleId, userId]
    );

    // Increment like count
    await databaseService.query(
      databaseService.queries.articles.incrementLikes,
      [articleId]
    );

    res.json({
      success: true,
      message: 'Article liked successfully'
    });

  } catch (error) {
    if (error.code === '23505') { // Duplicate like
      return res.status(400).json({
        success: false,
        message: 'Article already liked'
      });
    }
    next(error);
  }
});

// Bookmark article
router.post('/:id/bookmark', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid article ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const articleId = req.params.id;
    const userId = req.user.userId;

    // Check if article exists
    const articleResult = await databaseService.query(
      databaseService.queries.articles.findById,
      [articleId]
    );

    if (articleResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Article not found'
      });
    }

    // Add bookmark
    await databaseService.query(
      'INSERT INTO article_bookmarks (id, article_id, user_id) VALUES ($1, $2, $3)',
      [uuidv4(), articleId, userId]
    );

    res.json({
      success: true,
      message: 'Article bookmarked successfully'
    });

  } catch (error) {
    if (error.code === '23505') { // Duplicate bookmark
      return res.status(400).json({
        success: false,
        message: 'Article already bookmarked'
      });
    }
    next(error);
  }
});

module.exports = router;