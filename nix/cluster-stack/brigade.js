const { events } = require("brigadier");

function run(e, project) {
  console.log("hello default script")
}

events.on("run", run)

events.on("push", function (e, project) {
  console.log("received push for commit " + e.revision.commit)
})
