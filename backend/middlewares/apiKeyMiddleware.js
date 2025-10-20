module.exports = function (req, res, next) {
  const clientKey = req.headers['x-api-key'];

  if (!clientKey || clientKey !== process.env.API_KEY) {
    return res.status(401).json({ message: 'Invalid or missing API key' });
  }

  next();
};
