const { Hono } = require("hono");

const app = new Hono();

// Simple health check endpoint
app.get("/", (c) => {
	console.log("Received request to /");
	return c.json({
		status: "ok",
		message: "Hello from Lambda!",
		timestamp: new Date().toISOString(),
	});
});

// Example endpoint with path parameter
app.get("/hello/:name", (c) => {
	const name = c.req.param("name");
	return c.json({
		message: `Hello, ${name}!`,
		timestamp: new Date().toISOString(),
	});
});

// Example POST endpoint
app.post("/echo", async (c) => {
	const body = await c.req.json();
	return c.json({
		message: "Echo response",
		data: body,
		timestamp: new Date().toISOString(),
	});
});

// Error-triggering endpoint
app.get("/error", (c) => {
	console.log("About to trigger an error");
	throw new Error("This is a deliberately triggered error for testing");
});

// Lambda handler
exports.handler = async (event, context) => {
	console.log("Lambda event:", JSON.stringify(event, null, 2));

	try {
		console.log("Starting Lambda handler");

		// Extract request details from API Gateway event
		const method =
			event.requestContext?.http?.method || event.httpMethod || "GET";
		console.log("HTTP method:", method);

		const path = event.rawPath || event.path || "/";
		console.log("Path:", path);

		// Simple response for testing
		return {
			statusCode: 200,
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify({
				status: "ok",
				message: "Hello from Lambda!",
				path: path,
				method: method,
				timestamp: new Date().toISOString(),
			}),
		};
	} catch (error) {
		console.error("Error:", error);
		return {
			statusCode: 500,
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify({
				error: "Internal Server Error",
				message: error.message,
				stack: error.stack,
			}),
		};
	}
};
