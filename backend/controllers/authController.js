const User = require('../models/User');
const bcrypt = require('bcryptjs');
const crypto = require('crypto'); // for generating secure API keys

// REGISTER
exports.register = async (req, res) => {
  const { name,dob , email, password, } = req.body;

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: 'User already exists' });

    const hashedPassword = await bcrypt.hash(password, 10);

    // 🔑 Generate a unique API Key
    const apiKey = crypto.randomBytes(32).toString('hex');

    const newUser = new User({
      name,
      dob,
      email,
      password: hashedPassword,
      apiKey,
    });

    await newUser.save();

    res.status(201).json({
      message: 'User registered successfully',
      apiKey: newUser.apiKey,
    });
  } catch (err) {
    res.status(400).json({ message: 'Signup Failed', error: err.message });
  }
};

// LOGIN
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user)
      return res.status(400).json({ message: 'Invalid email or password' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(400).json({ message: 'Invalid email or password' });

    res.status(200).json({
      message: 'Login successful',
      userId: user._id,
      apiKey: user.apiKey, // ✅ Return the API key here too
    });
  } catch (err) {
    res.status(500).json({ message: 'Something went wrong', error: err.message });
  }
};
