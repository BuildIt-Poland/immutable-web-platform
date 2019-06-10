// take this from nix or env var
export const projectName = process.env.PROJECT_NAME
export const bucketName = `${projectName}-remote-state`
export const tableName = `${projectName}-remote-state`
export const awsRegion = "eu-west-2"