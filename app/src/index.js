const { Hono } = require("hono");

const app = new Hono();

app.get("/", (c) => {
	console.log("Received request to /");
	return c.json({
		status: "ok",
		message: "Hello from Lambda!",
		timestamp: new Date().toISOString(),
	});
});

app.get("/hello/:name", (c) => {
	const name = c.req.param("name");
	return c.json({
		message: `Hello, ${name}!`,
		timestamp: new Date().toISOString(),
	});
});

app.post("/echo", async (c) => {
	const body = await c.req.json();
	return c.json({
		message: "Echo response",
		data: body,
		timestamp: new Date().toISOString(),
	});
});

app.get("/error", (c) => {
	console.log("About to trigger an error");
	throw new Error("This is a deliberately triggered error for testing");
});

module.exports = { app };
