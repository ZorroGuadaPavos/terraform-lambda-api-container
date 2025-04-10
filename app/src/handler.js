const { handle } = require("hono/aws-lambda");
const { app } = require("./index");

exports.handler = handle(app);
