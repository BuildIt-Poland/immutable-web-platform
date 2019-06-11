import * as diff from 'changeset'
import { readFileSync } from 'fs'

export const readStateFile = (path: string) =>
  readFileSync(path).toString()

export const isStateDiffers =
  ({ changes }: ChangeDescriptor) =>
    changes.length > 0

export type Change = { type: 'put' | 'del', key: string[], value: any }
export type ChangeDescriptor = { changes: Change[], a: JSON, b: JSON }

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

const escapeNixExpression = (path: string) => {
  const dir = process.cwd()
  const withoutDir = path.replace(dir, '')
  return `"<${withoutDir}>"`
}

export const escapeResources =
  (args: string) =>
    args
      .split(' ')
      .map(d =>
        d.indexOf('.nix') > -1
          ? escapeNixExpression(d)
          : d
      )
      .join(' ')