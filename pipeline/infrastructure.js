const { events, Job } = require("brigadier");

function run(e, project) {
  console.log("hello default script")
  var test = new Job("test", "alpine:3.4")

  test.tasks = [
    "ls -la",
    "echo hello",
    "echo refreshed",
    "ls -la /src",
  ];
  test.run()
}

events.on("exec", run)
events.on("push", function (e, project) {
  console.log("received push for commit " + e.revision.commit)
  console.log(e.payload)
  var gh = JSON.parse(e.payload)
  var test = new Job("test", "alpine:3.4")

  test.tasks = [
    "ls -la",
    "echo hello",
    "ls -la /src",
  ];
  test.run()
})
