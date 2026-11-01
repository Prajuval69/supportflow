import { Link } from 'react-router-dom'
import { ArrowUpRight, Clock3 } from 'lucide-react'
import type { Ticket } from '../types'
import { Badge, date, Empty } from './ui'
export function TicketTable({ tickets }: { tickets: Ticket[] }) {
  if (!tickets.length)
    return (
      <Empty title="No tickets found">Try a different search or create your first ticket.</Empty>
    )
  return (
    <div className="table-wrap">
      <table className="ticket-table">
        <thead>
          <tr>
            <th>Ticket</th>
            <th>Priority</th>
            <th>Status</th>
            <th>Assignee</th>
            <th>Updated</th>
            <th>Service target</th>
          </tr>
        </thead>
        <tbody>
          {tickets.map((ticket) => (
            <tr key={ticket.id}>
              <td>
                <Link className="ticket-title" to={`/app/tickets/${ticket.id}`}>
                  <span className="ticket-number">{ticket.ticket_number}</span>
                  <strong>{ticket.title}</strong>
                  <span className="ticket-category">
                    {ticket.category?.name || 'General'} <ArrowUpRight size={13} />
                  </span>
                </Link>
              </td>
              <td data-label="Priority">
                <Badge value={ticket.priority} />
              </td>
              <td data-label="Status">
                <Badge value={ticket.status} />
              </td>
              <td data-label="Assignee">
                <span className="person">
                  <span className="avatar small">{ticket.assignee?.name.charAt(0) || '–'}</span>
                  {ticket.assignee?.name || 'Unassigned'}
                </span>
              </td>
              <td className="muted" data-label="Updated">
                {date(ticket.updated_at)}
              </td>
              <td data-label="Service target">
                <span className={`sla-text ${ticket.overdue ? 'overdue' : ''}`}>
                  <Clock3 size={14} />
                  {ticket.status === 'resolved' || ticket.status === 'closed'
                    ? 'Completed'
                    : ticket.overdue
                      ? 'Overdue'
                      : 'On track'}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
