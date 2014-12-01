# 故事 Page
async = require 'async'
router = require('express').Router()

Story = require '../models/story'
Point = require '../models/point'

# 权限过滤
router.route('*').get (req, res, done) ->
  return res.redirect '/signin' if not req.user
  done()

# 列表
router.route('/').get (req, res, done) ->
  preloaded = {}
  Story.find { author: req.user.id }, 'title cover', { sort: _id: -1 }, (err, stories) ->
    return done err if err
    preloaded.stories = stories
    res.render 'story/default', { preloaded: JSON.stringify preloaded }

# 详情
router.route(/^\/([0-9a-fA-F]{24})$/).get (req, res, done) ->
  preloaded = {}
  async.waterfall [
    (fn) ->
      Story.findById req.params[0], 'title description mark background cover theme sections'
      .populate 'sections'
      .exec (err, story) -> fn err, story
    (story, fn) ->
      fn null, null if not story
      Point.populate story.sections, { path: 'points' }, (err, points) ->
        story.sections.points = points
        fn err, story
  ], (err, story) ->
    return done err if err
    return done() if not story
    preloaded.story = story
    res.render 'story/default', { bige: true, preloaded: JSON.stringify preloaded }

module.exports = router