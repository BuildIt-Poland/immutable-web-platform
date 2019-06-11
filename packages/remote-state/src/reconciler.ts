import * as diff from 'changeset'
import { readFileSync } from 'fs'

export const fileToJSON = (path: string) =>
  readFileSync(path).toString()

export const isStateDiffers =
  ({ changes }: ChangeDescriptor) =>
    changes.length > 0

type Change = { type: 'put' | 'del', key: string[], value: any }
type ChangeDescriptor = { changes: Change[], a: JSON, b: JSON }

export const diffState = (a: string, b: string): ChangeDescriptor => {
  const fileA = JSON.parse(a)
  const fileB = JSON.parse(b)
  return {
    changes: diff(fileA, fileB),
    a: fileA,
    b: fileB,
  }
}

export const reconcileState = (desc: ChangeDescriptor) =>
  diff.apply(desc.changes, desc.a)

// TODO - nixops is keeping resources as full paths -> this is for escape them
export const escapeResoures =
  (a: JSON) => {
    // from "nixExprs": "[\"<configuration.nix>\", \"<virtualbox.nix>\"]"
    // to "nixExprs": "['<basename(file)>']"
  }