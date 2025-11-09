const express = require("express");
const verifyToken = require("../middleware/verifyToken");
const {
  addAddress,
  getAddresses,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
} = require("../controllers/addressController");

const router = express.Router();

router.post("/", verifyToken, addAddress);
router.get("/", verifyToken, getAddresses);
router.put("/:id", verifyToken, updateAddress);
router.delete("/:id", verifyToken, deleteAddress);
router.put("/:id/default", verifyToken, setDefaultAddress);

module.exports = router;
