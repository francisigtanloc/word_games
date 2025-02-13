const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/api/test', (req, res) => {
    res.json(["item1", "item2", "item3"]);
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});