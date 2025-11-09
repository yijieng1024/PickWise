const Address = require("../models/Address");

const addAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      fullName,
      phoneNumber,
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
      isDefault,
    } = req.body;

    if (isDefault) {
      await Address.updateMany({ userId }, { isDefault: false });
    }

    const newAddress = await Address.create({
      userId,
      fullName,
      phoneNumber,
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
      isDefault,
    });

    res.status(201).json(newAddress);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAddresses = async (req, res) => {
  try {
    const userId = req.user.id;
    const addresses = await Address.find({ userId }).sort({ createdAt: -1 });
    res.json(addresses);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updated = await Address.findOneAndUpdate(
      { _id: id, userId },
      req.body,
      { new: true }
    );
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    await Address.findOneAndDelete({ _id: id, userId });
    res.json({ message: "Address deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const setDefaultAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    await Address.updateMany({ userId }, { isDefault: false });
    const updated = await Address.findByIdAndUpdate(
      id,
      { isDefault: true },
      { new: true }
    );

    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  addAddress,
  getAddresses,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
};
