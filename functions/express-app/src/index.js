const express = require("express")
const app = express()

app.get("/", (req, res) => {
  console.log("Hello world received a request.")

  const target = process.env.TARGET || "World!!!!"
  const delay = process.env.DELAY || 1000
  setTimeout(() => {
    console.log(`Sending response for ${target} - cool!`)
    res.send(`Hello ${target}! yay!!! hey skaffold!!!`)
  }, delay)
})

// https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-http-request
app.get("/healthz", (req, res) => {
  console.log("Calling health check endpoint!!")
  res.status(200).send("ok")
})

const port = process.env.PORT || 8080
app.listen(port, () => {
  console.log("Hello world listening on port", port)
})