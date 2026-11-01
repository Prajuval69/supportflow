export type Role = 'admin' | 'agent' | 'customer'
export type Person = { id: string; name: string }
export type Membership = { id: string; role: Role; organization: { id: string; name: string; slug: string } }
export type Identity = { user: Person & { email: string }; memberships: Membership[]; csrf_token?: string }
export type Category = { id: string; name: string; active: boolean }
export type Member = { id: string; role: Role; active: boolean; user: Person & { email: string } }
export type Status = 'open' | 'in_progress' | 'waiting_on_customer' | 'resolved' | 'closed'
export type Priority = 'low' | 'normal' | 'high' | 'urgent'
export type Ticket = {
  id: string; ticket_number: string; title: string; description: string; status: Status; priority: Priority;
  created_by: Person; assignee: Person | null; category: Pick<Category, 'id' | 'name'> | null;
  created_at: string; updated_at: string; first_response_at: string | null;
  first_response_due_at: string; resolution_due_at: string; overdue: boolean;
}
export type Comment = { id: string; body: string; visibility: 'public' | 'internal'; author: Person; created_at: string }
export type TicketEvent = { id: string; event_type: string; metadata: Record<string, string>; actor: Person | null; created_at: string }
export type Notice = { id: string; ticket_id: string | null; kind: string; message: string; read_at: string | null; created_at: string }
export type SlaPolicy = { priority: Priority; first_response_minutes: number; resolution_minutes: number }
export type Summary = { total: number; open: number; in_progress: number; overdue: number; resolved_last_30_days: number; by_priority: Record<string, number>; by_status: Record<string, number>; recent_tickets: Ticket[] }
export type Meta = { page: number; per_page: number; total_pages: number; total_count: number }
export type Response<T> = { data: T; meta?: Meta; unread_count?: number }
