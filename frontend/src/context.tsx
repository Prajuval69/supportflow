import { createContext, useContext } from 'react'
import type { Identity, Membership } from './types'
export const WorkspaceContext = createContext<{ identity: Identity; membership: Membership; refreshNotifications: () => void } | null>(null)
export function useWorkspace() {
  const context = useContext(WorkspaceContext)
  if (!context) throw new Error('Workspace context is missing')
  return { ...context, org: context.membership.organization.id, staff: context.membership.role !== 'customer', admin: context.membership.role === 'admin' }
}
