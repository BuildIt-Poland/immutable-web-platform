import * as diff from 'changeset'
import { readFileSync } from 'fs'
import { relative } from 'path'

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

export const reconcileState = (desc: ChangeDescriptor): JSON =>
  diff.apply(desc.changes, desc.a)

export const escapeNixExpression = (path: string, cwd: string) =>
  `<${relative(cwd || process.cwd(), path)}>`

export const escapeResources =
  (args: string, cwd: string) =>
    args
      .split(' ')
      .map(d =>
        d.indexOf('.nix') > -1
          ? escapeNixExpression(d, cwd)
          : d
      )
      .join(' ')